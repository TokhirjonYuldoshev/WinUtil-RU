BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    . (Join-Path $repoRoot 'tools/Test-WinUtilBuildInputs.ps1')
    $nativeGit = (Get-Command git -CommandType Application | Select-Object -First 1).Source
    $fixture = Join-Path $TestDrive 'build-input-fixture'
    & $nativeGit clone --quiet --shared $repoRoot $fixture
    if ($LASTEXITCODE) { throw 'Unable to create isolated build fixture.' }
    foreach ($file in @('Test-WinUtilBuildInputs.ps1', 'Test-WinUtilRussianEdition.ps1', 'Build-WinUtilRussianRelease.ps1')) {
        Copy-Item -LiteralPath (Join-Path $repoRoot "tools/$file") -Destination (Join-Path $fixture "tools/$file") -Force
    }
    # Exercise real Git/preflight/compiler/package bytes. The separate Compile
    # & Check gate tests actual WPF in Windows STA, independently of this fixture.
    [IO.File]::WriteAllText((Join-Path $fixture 'tools/Test-WinUtilRussianXaml.ps1'), 'param($CompiledScriptPath)')
    & $nativeGit -C $fixture add tools
    & $nativeGit -C $fixture -c user.name='WinUtil Test' -c user.email='test@example.invalid' commit --quiet -m 'Prepare isolated build input fixture'
    if ($LASTEXITCODE) { throw 'Unable to commit build fixture.' }
    $fixtureCommit = (& $nativeGit -C $fixture rev-parse HEAD).Trim()
    # Use the fixture's clean tree as the mocked upstream release. CI checkouts
    # may be shallow; the real official-tag comparison runs in strict-parity.
    $officialCommit = $fixtureCommit
    function git { param([Parameter(ValueFromRemainingArguments)][string[]]$Arguments) }
}
Describe 'Release build input binding' {
    BeforeEach {
        & $nativeGit -C $fixture reset --hard --quiet $fixtureCommit
        & $nativeGit -C $fixture clean -fdx --quiet
        [IO.File]::WriteAllText((Join-Path $fixture '.git/info/exclude'), '')
        Mock git {
            if ($Arguments[0] -eq 'ls-remote') {
                $global:LASTEXITCODE = 0
                "$officialCommit`trefs/tags/26.09.29"
            } elseif ($Arguments[0] -eq 'fetch') {
                & $nativeGit -C $fixture fetch --quiet --no-tags $fixture $officialCommit
            } else { & $nativeGit @Arguments }
        }
        Mock Invoke-RestMethod { [pscustomobject]@{ tag_name = '26.09.29'; draft = $false; prerelease = $false } }
    }
    It 'builds a clean checkout and permits unrelated dist/generated output' {
        New-Item -ItemType Directory (Join-Path $fixture 'dist') -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $fixture 'dist/unrelated.txt'), 'allowed output')
        [IO.File]::WriteAllText((Join-Path $fixture 'winutil.ps1'), 'old generated output')
        & (Join-Path $fixture 'tools/Build-WinUtilRussianRelease.ps1')
        $manifest = Get-Content (Join-Path $fixture 'dist/release.json') -Raw | ConvertFrom-Json
        $manifest.SourceCommit | Should -Be $fixtureCommit
        (Get-FileHash (Join-Path $fixture 'dist/winutil-RU.ps1')).Hash | Should -Be $manifest.Sha256
        [IO.File]::ReadAllText((Join-Path $fixture 'dist/unrelated.txt')) | Should -Be 'allowed output'
        Test-WinUtilBuildInputs -RepositoryRoot $fixture | Should -Be $fixtureCommit
    }
    It 'rejects changed <Path> before compiling' -ForEach @(
        @{ Path = 'functions/private/Set-WinUtilDNS.ps1' }
        @{ Path = 'scripts/start.ps1' }
        @{ Path = 'config/applications.json' }
        @{ Path = 'xaml/inputXML.xaml' }
        @{ Path = 'tools/autounattend.xml' }
        @{ Path = 'LICENSE' }
        @{ Path = 'Compile.ps1' }
    ) {
        [IO.File]::AppendAllText((Join-Path $fixture $Path), "`nUNCOMMITTED_TEST_MARKER`n")
        { & (Join-Path $fixture 'tools/Build-WinUtilRussianRelease.ps1') } | Should -Throw '*Build inputs must match committed HEAD*'
        Test-Path (Join-Path $fixture 'dist/winutil-RU.ps1') | Should -BeFalse
        Should -Invoke Invoke-RestMethod -Times 0
    }
    It 'rejects staged changes and files marked assume-unchanged' {
        $path = 'functions/private/Set-WinUtilDNS.ps1'
        [IO.File]::AppendAllText((Join-Path $fixture $path), "`n# staged marker`n")
        & $nativeGit -C $fixture add $path
        { Test-WinUtilBuildInputs -RepositoryRoot $fixture } | Should -Throw '*Build inputs*'
        & $nativeGit -C $fixture reset --hard --quiet
        & $nativeGit -C $fixture update-index --assume-unchanged $path
        try {
            [IO.File]::AppendAllText((Join-Path $fixture $path), "`n# concealed marker`n")
            { Test-WinUtilBuildInputs -RepositoryRoot $fixture } | Should -Throw '*Build inputs*'
        } finally { & $nativeGit -C $fixture update-index --no-assume-unchanged $path }
    }
    It 'rejects extra <Path> including non-script files consumed by the compiler' -ForEach @(
        @{ Path = 'functions/private/Invoke-Extra.ps1' }
        @{ Path = 'functions/private/extra.txt' }
        @{ Path = 'config/extra.json' }
    ) {
        [IO.File]::WriteAllText((Join-Path $fixture $Path), '# extra compiler input')
        { & (Join-Path $fixture 'tools/Test-WinUtilRussianEdition.ps1') -Quiet } | Should -Throw '*Build inputs*'
        { & (Join-Path $fixture 'tools/Build-WinUtilRussianRelease.ps1') } | Should -Throw '*Build inputs*'
        Test-Path (Join-Path $fixture 'dist/winutil-RU.ps1') | Should -BeFalse
    }
    It 'rejects ignored compiler inputs' {
        [IO.File]::WriteAllText((Join-Path $fixture '.git/info/exclude'), 'functions/private/ignored.txt')
        [IO.File]::WriteAllText((Join-Path $fixture 'functions/private/ignored.txt'), '# ignored compiler input')
        { Test-WinUtilBuildInputs -RepositoryRoot $fixture } | Should -Throw '*ignored.txt*'
    }
    It 'rejects missing committed inputs' {
        Remove-Item -LiteralPath (Join-Path $fixture 'functions/private/Set-WinUtilDNS.ps1')
        { Test-WinUtilBuildInputs -RepositoryRoot $fixture } | Should -Throw '*Set-WinUtilDNS.ps1*'
    }
    It 'refuses to bind the manifest to a source commit that changed during compilation' {
        { Test-WinUtilBuildInputs -RepositoryRoot $fixture -ExpectedCommit ('a' * 40) } | Should -Throw '*Source commit changed*'
    }
    It 'rechecks actual inputs after the compiler has run' {
        [IO.File]::AppendAllText((Join-Path $fixture 'Compile.ps1'), "`n[IO.File]::AppendAllText((Join-Path `$PWD 'functions/private/Set-WinUtilDNS.ps1'), '# changed during compile')`n")
        & $nativeGit -C $fixture add Compile.ps1
        & $nativeGit -C $fixture -c user.name='WinUtil Test' -c user.email='test@example.invalid' commit --quiet -m 'Simulate edit during compilation'
        { & (Join-Path $fixture 'tools/Build-WinUtilRussianRelease.ps1') } | Should -Throw '*Build inputs*'
        Test-Path (Join-Path $fixture 'winutil.ps1') | Should -BeTrue
        Test-Path (Join-Path $fixture 'dist/release.json') | Should -BeFalse
    }
}
