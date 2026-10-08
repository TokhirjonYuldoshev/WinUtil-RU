BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $shell = (Get-Process -Id $PID).Path
    function Test-WinUtilLauncherAdministrator { $true }
}
Describe 'Launcher stdout decoding' {
    BeforeEach {
        $savedEncoding = [Console]::OutputEncoding
        $message = [string][char]0x2554 + [char]0x2550 + [char]0x2557 + ' ' + [char]0x0416
        $payload = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($message))
        $child = Join-Path $TestDrive 'child.ps1'
        [IO.File]::WriteAllText($child, "[Console]::OutputEncoding = [Text.UTF8Encoding]::new(`$false); `$b=[Convert]::FromBase64String('$payload'); `$s=[Console]::OpenStandardOutput(); `$s.Write(`$b,0,`$b.Length); `$s.Flush(); exit 7")
        $script:observedOutput = ''
        Mock Out-Host { $script:observedOutput += [string]$InputObject }
        Mock Test-WinUtilLauncherAdministrator { $true }
    }
    AfterEach { [Console]::OutputEncoding = $savedEncoding }
    It 'decodes real file-child UTF-8 with an OEM parent and restores its encoding: <File>' -TestCases @(
        @{ File = 'bootstrap.ps1' }, @{ File = 'run-russian.ps1' }
    ) {
        param($File)
        $ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repoRoot $File), [ref]$null, [ref]$null)
        $definition = $ast.EndBlock.Statements | Where-Object { $_.Name -eq 'Invoke-WinUtilLauncherApplication' }
        . ([scriptblock]::Create($definition.Extent.Text))
        [Console]::OutputEncoding = [Text.Encoding]::GetEncoding(866)
        (& $shell -NoProfile -File $child) -join '' | Should -Not -Be $message
        Invoke-WinUtilLauncherApplication -Shell $shell -ScriptPath $child | Should -Be 7
        $script:observedOutput | Should -Be $message
        [Console]::OutputEncoding.CodePage | Should -Be 866
    }
    It 'decodes the inner file-child in the elevated command with an OEM wrapper: <File>' -TestCases @(
        @{ File = 'bootstrap.ps1' }, @{ File = 'run-russian.ps1' }
    ) {
        param($File)
        $ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repoRoot $File), [ref]$null, [ref]$null)
        $definition = $ast.EndBlock.Statements | Where-Object { $_.Name -eq 'Invoke-WinUtilLauncherApplication' }
        . ([scriptblock]::Create($definition.Extent.Text))
        Mock Test-WinUtilLauncherAdministrator { $false }
        Mock Start-Process { $script:encoded = $ArgumentList[-1]; [pscustomobject]@{ ExitCode = 7 } }
        Invoke-WinUtilLauncherApplication -Shell $shell -ScriptPath $child | Should -Be 7
        $command = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($script:encoded))
        $command = '[Console]::OutputEncoding=[Text.Encoding]::GetEncoding(866); ' + $command
        $info = New-Object Diagnostics.ProcessStartInfo
        $info.FileName = $shell
        $info.Arguments = '-NoProfile -EncodedCommand ' + [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
        $info.UseShellExecute = $false
        $info.RedirectStandardOutput = $true
        $info.RedirectStandardError = $true
        $info.StandardOutputEncoding = New-Object Text.UTF8Encoding($false)
        $process = [Diagnostics.Process]::Start($info)
        try {
            $output = $process.StandardOutput.ReadToEnd().TrimEnd([char]13, [char]10)
            $errorText = $process.StandardError.ReadToEnd()
            $process.WaitForExit()
            $output | Should -Be $message
            $errorText | Should -BeNullOrEmpty
            $process.ExitCode | Should -Be 7
        } finally { $process.Dispose() }
    }
}
Describe 'BOM-safe pinned public bootstrap' {
    BeforeAll {
        $ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repoRoot 'bootstrap.ps1'), [ref]$null, [ref]$null)
        foreach ($definition in $ast.EndBlock.Statements | Where-Object { $_ -is [Management.Automation.Language.FunctionDefinitionAst] }) {
            . ([scriptblock]::Create($definition.Extent.Text))
        }
    }
    BeforeEach {
        $script:observedCommit = $null
        Mock Invoke-WMSourceBootstrap {}
        Mock Get-WMRemoteText { [string][char]0xFEFF + 'function Test-BomRemoteEntry { $script:observedCommit = $env:WINUTIL_RU_COMMIT }; Test-BomRemoteEntry' }
    }
    It 'executes a BOM-prefixed source at the exact requested SHA without branch lookup' {
        $old = $env:WINUTIL_RU_COMMIT
        try {
            $env:WINUTIL_RU_COMMIT = 'previous'
            Invoke-WMBootstrap -Branch russian -Commit ('A' * 40)
            $script:observedCommit | Should -Be ('a' * 40)
            $env:WINUTIL_RU_COMMIT | Should -Be 'previous'
            Should -Invoke Invoke-WMSourceBootstrap -Times 0
        } finally { $env:WINUTIL_RU_COMMIT = $old }
    }
    It 'rejects a short explicit SHA before downloading or falling back' {
        { Invoke-WMBootstrap -Branch russian -Commit 'abc123' } | Should -Throw '*full Git SHA*'
        Should -Invoke Get-WMRemoteText -Times 0
        Should -Invoke Invoke-WMSourceBootstrap -Times 0
    }
    It 'does not launch another cached source when the pinned download fails' {
        Mock Get-WMRemoteText { throw 'download failed' }
        { Invoke-WMBootstrap -Branch russian -Commit ('a' * 40) } | Should -Throw '*download failed*'
        Should -Invoke Invoke-WMSourceBootstrap -Times 0
    }
    It 'keeps the normal branch/cache flow when no explicit SHA is supplied' {
        Invoke-WMBootstrap -Branch russian
        Should -Invoke Invoke-WMSourceBootstrap -Times 1 -ParameterFilter { $Branch -eq 'russian' }
        Should -Invoke Get-WMRemoteText -Times 0
    }
    It 'keeps the remote bootstrap ASCII and BOM-free' {
        $bytes = [IO.File]::ReadAllBytes((Join-Path $repoRoot 'bootstrap.ps1'))
        @($bytes | Where-Object { $_ -gt 127 }).Count | Should -Be 0
    }
}
