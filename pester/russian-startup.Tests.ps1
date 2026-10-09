BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $startAst = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repoRoot 'scripts/start.ps1'), [ref]$null, [ref]$null)
    $clearStatement = $startAst.EndBlock.Statements[-1].Extent.Text
    $hostExecutable = (Get-Process -Id $PID).Path
    $preferenceBlocks = @{}
    foreach ($file in @('run-russian.ps1', 'functions/private/Initialize-WinUtilRussianLocalization.ps1')) {
        $ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repoRoot $file), [ref]$null, [ref]$null)
        $blocks = $ast.FindAll({
            param($node)
            $node -is [Management.Automation.Language.TryStatementAst] -and
                $node.Body.Extent.Text -match '^\{\s*\$savedIconMode\s*='
        }, $true)
        $preferenceBlocks[$file] = [scriptblock]::Create($blocks[0].Extent.Text)
        if ($file -like 'functions/*') {
            $languageBlock = $ast.FindAll({
                param($node)
                $node -is [Management.Automation.Language.TryStatementAst] -and
                    $node.Body.Extent.Text -match '^\{\s*\$savedLanguage\s*='
            }, $true)
            $languagePreferenceBlock = [scriptblock]::Create($languageBlock[0].Extent.Text)
        }
    }
}

Describe 'Startup through redirected launcher output' {
    It 'prints the banner marker without cursor errors, clear sequences or blank rows' {
        # Run the real startup statement in a native child with redirected stdout.
        # No GUI, packages, registry writes or other startup operations execute.
        $command = "`$ErrorActionPreference = 'Stop'; if (-not [Console]::IsOutputRedirected) { throw 'Test requires a redirected child' }; $clearStatement; 'YTY banner'; if (`$Error.Count) { exit 1 }"
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
        $output = @(& $hostExecutable -NoProfile -EncodedCommand $encoded 2>&1)
        $LASTEXITCODE | Should -Be 0
        $output.Count | Should -Be 1
        [string]$output[0] | Should -Be 'YTY banner'
    }
}

Describe 'Optional first-run icon preferences' {
    BeforeEach {
        $script:sync = @{ WinUtilAppIconMode = 'Auto'; preferences = @{ language = 'ru-RU' } }
        $script:iconMode = 'Auto'
        Mock Test-Path { $true } -ParameterFilter { $LiteralPath -eq 'HKCU:\Software\YTY\WindowManager' }
        Mock Get-ItemProperty {
            if ($Name) { throw 'A missing named value would produce a transcript error' }
            [pscustomobject]@{ Language = 'ru-RU' }
        }
    }
    It 'keeps Auto for an existing key without AppIconMode and produces no error record' {
        foreach ($block in $preferenceBlocks.Values) {
            $before = $Error.Count
            . $block
            $Error.Count | Should -Be $before
        }
        $sync.WinUtilAppIconMode | Should -Be 'Auto'
        $iconMode | Should -Be 'Auto'
    }
    It 'does not query a registry key that does not exist' {
        Mock Test-Path { $false } -ParameterFilter { $LiteralPath -eq 'HKCU:\Software\YTY\WindowManager' }
        foreach ($block in $preferenceBlocks.Values) { . $block }
        Should -Invoke Get-ItemProperty -Times 0
        $sync.WinUtilAppIconMode | Should -Be 'Auto'
        $iconMode | Should -Be 'Auto'
    }
    It 'preserves saved <Mode> behavior in both the launcher and renderer' -ForEach @(
        @{ Mode = 'Auto' }, @{ Mode = 'CacheOnly' }, @{ Mode = 'Disabled' }
    ) {
        Mock Get-ItemProperty { [pscustomobject]@{ AppIconMode = $Mode } }
        foreach ($block in $preferenceBlocks.Values) { . $block }
        $sync.WinUtilAppIconMode | Should -Be $Mode
        $iconMode | Should -Be $Mode
    }
    It 'keeps Auto for an unrecognized preference without changing registry data' {
        Mock Get-ItemProperty { [pscustomobject]@{ AppIconMode = 'invalid' } }
        foreach ($block in $preferenceBlocks.Values) { . $block }
        $sync.WinUtilAppIconMode | Should -Be 'Auto'
        $iconMode | Should -Be 'Auto'
    }
    It 'keeps Russian when the existing key has no Language and produces no error record' {
        Mock Get-ItemProperty {
            if ($Name) { throw 'A missing named value would produce a transcript error' }
            [pscustomobject]@{ AppIconMode = 'Auto' }
        }
        $preferencePath = 'HKCU:\Software\YTY\WindowManager'
        $before = $Error.Count
        . $languagePreferenceBlock
        $Error.Count | Should -Be $before
        $sync.preferences.language | Should -Be 'ru-RU'
    }
    It 'preserves the saved English language' {
        Mock Get-ItemProperty { [pscustomobject]@{ Language = 'en-US' } }
        $preferencePath = 'HKCU:\Software\YTY\WindowManager'
        . $languagePreferenceBlock
        $sync.preferences.language | Should -Be 'en-US'
    }
}

Describe 'Display validation uses isolated preference fixtures' {
    It 'sets up both languages with the real optional-key reader and no registry access' {
        $fixtureAst = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repoRoot 'tools/Test-WinUtilRussianXaml.ps1'), [ref]$null, [ref]$null)
        $definitions = $fixtureAst.EndBlock.Statements | Where-Object {
            $_ -is [Management.Automation.Language.FunctionDefinitionAst] -and $_.Name -in @('Test-Path', 'Get-ItemProperty')
        }
        # Use a separate runspace so fixture command shadows do not affect Pester.
        $worker = [powershell]::Create()
        try {
            $fixtureCode = ($definitions.Extent.Text -join "`n")
            [void]$worker.AddScript("param(`$fixture, `$reader) . ([scriptblock]::Create(`$fixture)); `$preferencePath = 'HKCU:\Software\YTY\WindowManager'; foreach (`$testLanguage in @('ru-RU','en-US')) { `$sync = @{ preferences = @{ language = 'ru-RU' } }; . ([scriptblock]::Create(`$reader)); `$sync.preferences.language }").AddArgument($fixtureCode).AddArgument($languagePreferenceBlock.ToString())
            $result = $worker.Invoke()
            $worker.HadErrors | Should -BeFalse
            @($result).Count | Should -Be 2
            $result[0] | Should -Be 'ru-RU'
            $result[1] | Should -Be 'en-US'
        } finally { $worker.Dispose() }
    }
}
