BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $tokens = $null; $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $repoRoot 'scripts/start.ps1'), [ref]$tokens, [ref]$errors)
    $definition = $ast.EndBlock.Statements | Where-Object {
        $_ -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $_.Name -eq 'Initialize-WinUtilConsoleEncoding'
    }
    . ([scriptblock]::Create($definition.Extent.Text))
    $hostExecutable = (Get-Process -Id $PID).Path
    $message = 'Доступные обновления не найдены. Успешно установлено.'
    # A harmless native child writes the same UTF-8 bytes as WinGet, without
    # depending on any package manager or installing anything on the runner.
    $payload = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($message))
    $command = "`$bytes = [Convert]::FromBase64String('$payload'); `$stream = [Console]::OpenStandardOutput(); `$stream.Write(`$bytes, 0, `$bytes.Length); `$stream.Flush()"
    $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
}
Describe 'Russian native console output' {
    BeforeEach { $savedEncoding = [Console]::OutputEncoding }
    AfterEach { [Console]::OutputEncoding = $savedEncoding }
    It 'reproduces OEM decoding corruption and restores readable native UTF-8 output' {
        [Console]::OutputEncoding = [Text.Encoding]::GetEncoding(866)
        $corrupt = (& $hostExecutable -NoProfile -EncodedCommand $encodedCommand) -join ''
        $corrupt | Should -Not -Be $message
        Initialize-WinUtilConsoleEncoding
        $output = (& $hostExecutable -NoProfile -EncodedCommand $encodedCommand) -join ''
        $LASTEXITCODE | Should -Be 0
        $output | Should -Be $message
    }
    It 'uses the same UTF-8 decoding in a worker runspace' {
        [Console]::OutputEncoding = [Text.Encoding]::GetEncoding(866)
        Initialize-WinUtilConsoleEncoding
        $worker = [powershell]::Create()
        try {
            [void]$worker.AddScript('param($shell, $command) & $shell -NoProfile -EncodedCommand $command').AddArgument($hostExecutable).AddArgument($encodedCommand)
            ($worker.Invoke() -join '') | Should -Be $message
            $worker.HadErrors | Should -BeFalse
        } finally { $worker.Dispose() }
    }
}
