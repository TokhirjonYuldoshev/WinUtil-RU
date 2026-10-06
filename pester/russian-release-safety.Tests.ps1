BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    foreach ($file in @('Publish-WinUtilRussianRelease.ps1', 'Set-WinUtilForkAutomation.ps1')) {
        $tokens = $null; $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $repoRoot "tools/$file"), [ref]$tokens, [ref]$errors)
        if ($errors.Count) { throw ($errors.Message -join '; ') }
        foreach ($definition in @($ast.EndBlock.Statements | Where-Object { $_ -is [System.Management.Automation.Language.FunctionDefinitionAst] })) {
            . ([scriptblock]::Create($definition.Extent.Text))
        }
    }
    function git { param([Parameter(ValueFromRemainingArguments)][string[]]$Arguments) }
    function gh { param([Parameter(ValueFromRemainingArguments)][string[]]$Arguments) }
    $repository = 'TokhirjonYuldoshev/WinUtil-RU'
    $expectedCommit = 'b' * 40
    $wrongCommit = 'a' * 40
    $tag = '26.09.29-RU'
    $originalExitCode = $global:LASTEXITCODE
    $originalEnvironment = @{}
    foreach ($key in @('GITHUB_ACTIONS', 'GITHUB_REPOSITORY', 'GITHUB_REF', 'GITHUB_EVENT_NAME', 'GITHUB_SHA')) {
        $originalEnvironment[$key] = [Environment]::GetEnvironmentVariable($key)
    }
}
AfterAll {
    $global:LASTEXITCODE = $originalExitCode
    foreach ($key in $originalEnvironment.Keys) { [Environment]::SetEnvironmentVariable($key, $originalEnvironment[$key]) }
}

Describe 'Stable release tag and source binding' {
    BeforeEach {
        $dist = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $dist | Out-Null
        [IO.File]::WriteAllText((Join-Path $dist 'winutil-RU.ps1'), 'verified release fixture')
        [IO.File]::WriteAllText((Join-Path $dist 'LICENSE'), 'MIT fixture')
        $manifest = @{ Version = $tag; Channel = 'stable'; Prerelease = $false; SourceCommit = $expectedCommit; Sha256 = (Get-FileHash (Join-Path $dist 'winutil-RU.ps1')).Hash.ToLowerInvariant() }
        $manifest | ConvertTo-Json | Set-Content (Join-Path $dist 'release.json')
        $script:remoteTag = $null; $script:annotatedTag = $false
        $script:releasePages = '[[]]'
        $script:tagReadExit = 0; $script:apiExit = 0; $script:pushExit = 0
        $script:tagReads = 0; $script:raceBeforePublish = $false
        $script:releaseCreated = $false; $script:changeAfterPublish = $false
        Mock git {
            if ($Arguments[0] -eq 'ls-remote') {
                $script:tagReads++
                $global:LASTEXITCODE = $script:tagReadExit
                if ($script:raceBeforePublish -and $script:tagReads -gt 1) { $script:remoteTag = $wrongCommit }
                if ($null -ne $script:remoteTag) {
                    if ($script:annotatedTag) {
                        "$('d' * 40)`trefs/tags/$tag"
                        "$script:remoteTag`trefs/tags/$tag^{}"
                    } else { "$script:remoteTag`trefs/tags/$tag" }
                }
            } elseif ($Arguments[0] -eq 'push') {
                $global:LASTEXITCODE = $script:pushExit
                if ($script:pushExit -eq 0) { $script:remoteTag = $expectedCommit }
            } else { throw 'Unexpected Git operation in release fixture.' }
        }
        Mock gh {
            if ($Arguments[0] -eq 'api') {
                $global:LASTEXITCODE = $script:apiExit
                return $script:releasePages
            }
            if ($Arguments[0] -eq 'release' -and $Arguments[1] -eq 'create') {
                $script:releaseCreated = $true
                if ($script:changeAfterPublish) { $script:remoteTag = $wrongCommit }
                $global:LASTEXITCODE = 0
                return
            }
            throw 'Unexpected GitHub operation in release fixture.'
        }
    }
    It 'rejects an orphan tag at another commit before making any GitHub write' {
        $script:remoteTag = $wrongCommit
        { Publish-WinUtilRussianRelease $repository $expectedCommit $dist } | Should -Throw '*Refusing to reuse or replace*'
        Should -Invoke gh -Times 0
        Should -Invoke git -Times 0 -ParameterFilter { $Arguments[0] -eq 'push' }
    }
    It 'rejects a misleading release target when the actual Git tag points elsewhere' {
        $script:remoteTag = $wrongCommit
        $script:releasePages = '[[{"tag_name":"26.09.29-RU","target_commitish":"' + $expectedCommit + '","draft":false,"prerelease":false}]]'
        { Publish-WinUtilRussianRelease $repository $expectedCommit $dist } | Should -Throw '*Git tag*'
        $script:releaseCreated | Should -BeFalse
    }
    It 'peels annotated tags to the commit and publishes only with verify-tag' {
        $script:remoteTag = $expectedCommit; $script:annotatedTag = $true
        Publish-WinUtilRussianRelease $repository $expectedCommit $dist
        $script:releaseCreated | Should -BeTrue
        Should -Invoke gh -Times 1 -ParameterFilter { $Arguments[0] -eq 'release' -and $Arguments -contains '--verify-tag' }
        Should -Invoke git -Times 0 -ParameterFilter { $Arguments[0] -eq 'push' }
    }
    It 'rejects an annotated tag peeled to another commit' {
        $script:remoteTag = $wrongCommit; $script:annotatedTag = $true
        { Publish-WinUtilRussianRelease $repository $expectedCommit $dist } | Should -Throw '*Git tag*'
        Should -Invoke gh -Times 0
    }
    It 'creates an absent tag at the exact source commit without forcing a ref' {
        Publish-WinUtilRussianRelease $repository $expectedCommit $dist
        Should -Invoke git -Times 1 -ParameterFilter { $Arguments[0] -eq 'push' -and $Arguments[1] -eq 'origin' -and $Arguments[2] -eq "${expectedCommit}:refs/tags/$tag" -and $Arguments -notcontains '--force' }
        $script:remoteTag | Should -Be $expectedCommit
        $script:releaseCreated | Should -BeTrue
    }
    It 'rejects a failed tag creation or concurrent existing tag' {
        $script:pushExit = 1
        { Publish-WinUtilRussianRelease $repository $expectedCommit $dist } | Should -Throw '*Failed to create exact Git tag*'
        $script:releaseCreated | Should -BeFalse
    }
    It 'fails closed when remote tag lookup fails' {
        $script:tagReadExit = 1
        { Publish-WinUtilRussianRelease $repository $expectedCommit $dist } | Should -Throw '*read remote Git tags*'
        Should -Invoke gh -Times 0
    }
    It 'fails closed when release inventory is unavailable' {
        $script:apiExit = 1
        { Publish-WinUtilRussianRelease $repository $expectedCommit $dist } | Should -Throw '*read existing releases*'
        Should -Invoke git -Times 0 -ParameterFilter { $Arguments[0] -eq 'push' }
        $script:releaseCreated | Should -BeFalse
    }
    It 'does not replace an existing verified stable release whose metadata names a branch' {
        $script:remoteTag = $expectedCommit
        $script:releasePages = '[[{"tag_name":"other"}],[{"tag_name":"26.09.29-RU","target_commitish":"russian","draft":false,"prerelease":false}]]'
        Publish-WinUtilRussianRelease $repository $expectedCommit $dist
        $script:releaseCreated | Should -BeFalse
        Should -Invoke git -Times 0 -ParameterFilter { $Arguments[0] -eq 'push' }
    }
    It 'does not convert an existing draft into a stable release' {
        $script:remoteTag = $expectedCommit
        $script:releasePages = '[[{"tag_name":"26.09.29-RU","draft":true,"prerelease":false}]]'
        { Publish-WinUtilRussianRelease $repository $expectedCommit $dist } | Should -Throw '*unexpected state*'
        $script:releaseCreated | Should -BeFalse
    }
    It 'checks the tag again immediately before publication' {
        $script:remoteTag = $expectedCommit; $script:raceBeforePublish = $true
        { Publish-WinUtilRussianRelease $repository $expectedCommit $dist } | Should -Throw '*changed before publication*'
        $script:releaseCreated | Should -BeFalse
    }
    It 'reports a tag changed concurrently after publication' {
        $script:remoteTag = $expectedCommit; $script:changeAfterPublish = $true
        { Publish-WinUtilRussianRelease $repository $expectedCommit $dist } | Should -Throw '*Published release Git tag*'
    }
    It 'refuses mismatched artifact bytes before any API or ref write' {
        [IO.File]::WriteAllText((Join-Path $dist 'winutil-RU.ps1'), 'corrupt artifact')
        { Publish-WinUtilRussianRelease $repository $expectedCommit $dist } | Should -Throw '*SHA256*'
        Should -Invoke gh -Times 0
        Should -Invoke git -Times 0
    }
    It 'refuses a manifest from another source commit' {
        $manifest.SourceCommit = $wrongCommit
        $manifest | ConvertTo-Json | Set-Content (Join-Path $dist 'release.json')
        { Publish-WinUtilRussianRelease $repository $expectedCommit $dist } | Should -Throw '*expected source commit*'
        Should -Invoke gh -Times 0
    }
}

Describe 'Repository-wide upstream automation isolation' {
    BeforeEach {
        $env:GITHUB_ACTIONS = 'true'; $env:GITHUB_REPOSITORY = $repository
        $env:GITHUB_REF = 'refs/heads/russian'; $env:GITHUB_EVENT_NAME = 'push'; $env:GITHUB_SHA = $expectedCommit
        $script:disabled = @{}; $script:wrongPath = $false; $script:inspectFailure = $false
        $script:disableFailure = $false; $script:verifyFailure = $false
        Mock git { $global:LASTEXITCODE = 0; $expectedCommit }
        Mock gh {
            $endpoint = @($Arguments | Where-Object { $_ -like 'repos/*' })[0]
            $name = ($endpoint -split '/')[5]
            if ($Arguments -contains 'PUT') {
                $global:LASTEXITCODE = if ($script:disableFailure) { 1 } else { 0 }
                if (-not $script:disableFailure) { $script:disabled[$name] = $true }
                return
            }
            $global:LASTEXITCODE = if ($script:inspectFailure -and $name -eq 'close-discussion-on-pr.yaml') { 1 } else { 0 }
            $state = if ($script:disabled.ContainsKey($name) -and -not $script:verifyFailure) { 'disabled_manually' } else { 'active' }
            $path = if ($script:wrongPath) { '.github/workflows/russian-release.yaml' } else { ".github/workflows/$name" }
            @{ path = $path; state = $state } | ConvertTo-Json
        }
    }
    It 'inspects all seven workflows without changing settings in dry run' {
        Set-WinUtilForkAutomation -Repository $repository
        Should -Invoke gh -Times 7
        Should -Invoke gh -Times 0 -ParameterFilter { $Arguments -contains 'PUT' }
        Should -Invoke git -Times 0
    }
    It 'disables and verifies exactly seven upstream-only workflows without touching RU release or CI' {
        $reportPath = Join-Path $TestDrive 'policy.json'
        Set-WinUtilForkAutomation -Repository $repository -Apply -ReportPath $reportPath
        $script:disabled.Count | Should -Be 7
        $script:disabled.ContainsKey('russian-release.yaml') | Should -BeFalse
        $script:disabled.ContainsKey('compile-check.yaml') | Should -BeFalse
        $script:disabled.ContainsKey('unittests.yaml') | Should -BeFalse
        $script:disabled.ContainsKey('russian-parity-check.yaml') | Should -BeFalse
        $report = Get-Content $reportPath -Raw | ConvertFrom-Json
        $report.Applied | Should -BeTrue
        @($report.Workflows | Where-Object { $_.After -ne 'disabled_manually' }).Count | Should -Be 0
        Should -Invoke gh -Times 7 -ParameterFilter { $Arguments -contains 'PUT' }
    }
    It 'refuses changes from a pull request ref before reading or writing settings' {
        $env:GITHUB_REF = 'refs/pull/6/merge'; $env:GITHUB_EVENT_NAME = 'pull_request'
        { Set-WinUtilForkAutomation -Repository $repository -Apply } | Should -Throw '*trusted russian branch*'
        Should -Invoke gh -Times 0
    }
    It 'refuses changes from the preserved original main branch' {
        $env:GITHUB_REF = 'refs/heads/main'
        { Set-WinUtilForkAutomation -Repository $repository -Apply } | Should -Throw '*trusted russian branch*'
        Should -Invoke gh -Times 0
    }
    It 'refuses operation against the upstream repository' {
        { Set-WinUtilForkAutomation -Repository 'ChrisTitusTech/winutil' -Apply } | Should -Throw '*only to the WinUtil RU fork*'
        Should -Invoke gh -Times 0
    }
    It 'refuses a checkout different from the trusted workflow commit' {
        Mock git { $global:LASTEXITCODE = 0; $wrongCommit }
        { Set-WinUtilForkAutomation -Repository $repository -Apply } | Should -Throw '*checkout*'
        Should -Invoke gh -Times 0
    }
    It 'completes inspection before making any change and fails closed on an API error' {
        $script:inspectFailure = $true
        { Set-WinUtilForkAutomation -Repository $repository -Apply } | Should -Throw '*inspect workflow*'
        Should -Invoke gh -Times 0 -ParameterFilter { $Arguments -contains 'PUT' }
    }
    It 'rejects a workflow path outside the allowlist before any change' {
        $script:wrongPath = $true
        { Set-WinUtilForkAutomation -Repository $repository -Apply } | Should -Throw '*Unexpected workflow path*'
        Should -Invoke gh -Times 0 -ParameterFilter { $Arguments -contains 'PUT' }
    }
    It 'does not claim success after a failed disable operation' {
        $script:disableFailure = $true
        { Set-WinUtilForkAutomation -Repository $repository -Apply } | Should -Throw '*Failed to disable*'
    }
    It 'does not claim success when the API still reports an active workflow' {
        $script:verifyFailure = $true
        { Set-WinUtilForkAutomation -Repository $repository -Apply } | Should -Throw '*not disabled at repository level*'
    }
    It 'is idempotent when all seven workflows are already disabled' {
        foreach ($name in @('pre-release.yaml', 'auto-merge-docs.yaml', 'sponsors.yaml', 'generate-title-screen.yaml', 'docs.yaml', 'close-old-issues.yaml', 'close-discussion-on-pr.yaml')) { $script:disabled[$name] = $true }
        Set-WinUtilForkAutomation -Repository $repository -Apply
        Should -Invoke gh -Times 0 -ParameterFilter { $Arguments -contains 'PUT' }
    }
}
