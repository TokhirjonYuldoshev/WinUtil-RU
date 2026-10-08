BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repoRoot 'tools/Test-WinUtilRussianIcons.ps1'), [ref]$null, [ref]$null)
    $definition = $ast.EndBlock.Statements | Where-Object { $_.Name -eq 'Get-WinUtilRussianIconDiagnostic' }
    . ([scriptblock]::Create($definition.Extent.Text))
    $links = [ordered]@{ chrome = 'https://www.google.com/chrome/' }
}
Describe 'Read-only favicon diagnostics' {
    BeforeEach {
        Mock Get-ItemProperty { [pscustomobject]@{ AppIconMode = 'CacheOnly' } }
        Mock Invoke-WebRequest {
            [pscustomobject]@{
                StatusCode = 200
                Headers = @{ 'Content-Type' = 'image/png' }
                RawContentStream = [IO.MemoryStream]::new([byte[]](137, 80, 78, 71, 13, 10, 26, 10))
            }
        }
        $cache = Join-Path $TestDrive 'cache'
        New-Item -ItemType Directory -Path $cache -Force | Out-Null
    }
    It 'reports the saved mode and valid image response without treating it as WPF success' {
        $beforeTls = [Net.ServicePointManager]::SecurityProtocol
        $result = Get-WinUtilRussianIconDiagnostic -Links $links -CacheRoot $cache
        $result.SavedWarmupMode | Should -Be 'CacheOnly'
        $result.WpfUsesWarmupCache | Should -BeTrue
        $result.Checks[0].HttpStatus | Should -Be 200
        $result.Checks[0].ImageSignature | Should -Be 'PNG'
        $result.Checks[0].CachedFileExists | Should -BeFalse
        @(Get-ChildItem $cache).Count | Should -Be 0
        [Net.ServicePointManager]::SecurityProtocol | Should -Be $beforeTls
        Should -Invoke Invoke-WebRequest -Times 1 -ParameterFilter { $TimeoutSec -eq 8 -and $Uri -like 'https://www.google.com/s2/favicons?*' -and -not $OutFile }
    }
    It 'detects an HTML response instead of accepting HTTP 200 as an image' {
        Mock Invoke-WebRequest { [pscustomobject]@{ StatusCode = 200; Headers = @{ 'Content-Type' = 'text/html' }; RawContentStream = [IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes('<html>blocked</html>')) } }
        $result = Get-WinUtilRussianIconDiagnostic -Links $links -CacheRoot $cache
        $result.Checks[0].ContentType | Should -Be 'text/html'
        $result.Checks[0].ImageSignature | Should -Be 'Unrecognized'
    }
    It 'reports request failure without writing cache data or exposing exception details' {
        Mock Invoke-WebRequest { throw 'simulated private network details' }
        $beforeTls = [Net.ServicePointManager]::SecurityProtocol
        $result = Get-WinUtilRussianIconDiagnostic -Links $links -CacheRoot $cache
        $result.Checks[0].ErrorType | Should -Not -BeNullOrEmpty
        $result.Checks[0].ImageSignature | Should -BeNullOrEmpty
        ($result | ConvertTo-Json -Depth 5) | Should -Not -Match 'private network details'
        [Net.ServicePointManager]::SecurityProtocol | Should -Be $beforeTls
        @(Get-ChildItem $cache).Count | Should -Be 0
    }
}
