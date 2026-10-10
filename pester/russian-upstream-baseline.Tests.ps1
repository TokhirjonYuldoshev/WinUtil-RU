BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $nativeGit = (Get-Command git -CommandType Application | Select-Object -First 1).Source
    $fixture = Join-Path $TestDrive 'upstream-baseline-fixture'
    & $nativeGit clone --quiet --no-hardlinks $repoRoot $fixture
    if ($LASTEXITCODE) { throw 'Unable to clone upstream baseline fixture.' }
    $officialCommit = (& $nativeGit -C $fixture rev-parse HEAD).Trim()
    $officialTree = (& $nativeGit -C $fixture rev-parse 'HEAD^{tree}').Trim()
    $baselinePath = Join-Path $fixture 'tools/WinUtilUpstreamBaseline.json'
    $baseline = Get-Content -LiteralPath $baselinePath -Raw | ConvertFrom-Json
    $baseline.Commit = $officialCommit
    $baseline.Tree = $officialTree
    $baseline | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $baselinePath
    & $nativeGit -C $fixture add tools/WinUtilUpstreamBaseline.json
    & $nativeGit -C $fixture -c user.name='WinUtil Test' -c user.email='test@example.invalid' commit --quiet -m 'Prepare isolated historical baseline'
    if ($LASTEXITCODE) { throw 'Unable to commit baseline fixture.' }
    $fixtureCommit = (& $nativeGit -C $fixture rev-parse HEAD).Trim()
    $verifier = Join-Path $fixture 'tools/Test-WinUtilRussianEdition.ps1'
    $reportPath = Join-Path $TestDrive 'baseline-report.json'

    if (-not ('WinUtilBaselineHttpException' -as [type])) {
        Add-Type @'
using System;
public class WinUtilBaselineHttpResponse {
    public int StatusCode { get; set; }
}
public class WinUtilBaselineHttpException : Exception {
    public WinUtilBaselineHttpResponse Response { get; private set; }
    public WinUtilBaselineHttpException(int code) : base("Simulated HTTP failure") {
        Response = new WinUtilBaselineHttpResponse { StatusCode = code };
    }
}
'@
    }
    function git { param([Parameter(ValueFromRemainingArguments)][string[]]$Arguments) }
    function Save-WinUtilBaselineFixture {
        $script:baseline | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $baselinePath
        & $nativeGit -C $fixture add tools/WinUtilUpstreamBaseline.json
        & $nativeGit -C $fixture -c user.name='WinUtil Test' -c user.email='test@example.invalid' commit --quiet -m 'Change isolated baseline policy'
        if ($LASTEXITCODE) { throw 'Unable to commit test policy.' }
    }
}
AfterAll {
    Remove-Variable -Name WinUtilBaselineTestState -Scope Global -ErrorAction SilentlyContinue
    if ($fixture -and (Test-Path -LiteralPath $fixture)) {
        Remove-Item -LiteralPath $fixture -Recurse -Force
    }
}
Describe 'Pinned historical upstream release verification' {
    BeforeEach {
        & $nativeGit -C $fixture reset --hard --quiet $fixtureCommit
        & $nativeGit -C $fixture clean -fdx --quiet
        Remove-Item -LiteralPath $reportPath -ErrorAction SilentlyContinue
        $script:baseline = Get-Content -LiteralPath $baselinePath -Raw | ConvertFrom-Json
        $global:WinUtilBaselineTestState = @{}
        $global:WinUtilBaselineTestState.HttpStatus = 404
        $global:WinUtilBaselineTestState.TransportFailure = $false
        $global:WinUtilBaselineTestState.WrappedFailure = $false
        $global:WinUtilBaselineTestState.AdvertisedCommit = $officialCommit
        $global:WinUtilBaselineTestState.FetchedCommit = $officialCommit
        $global:WinUtilBaselineTestState.ExpectedTag = [string]$script:baseline.Tag
        $global:WinUtilBaselineTestState.LiveRelease = [pscustomobject]@{ tag_name = $global:WinUtilBaselineTestState.ExpectedTag; draft = $false; prerelease = $false }
        Mock Invoke-RestMethod {
            if ($global:WinUtilBaselineTestState.TransportFailure) { throw [Exception]::new('404 appears in a transport error message') }
            if ($global:WinUtilBaselineTestState.HttpStatus -ne 200) {
                $httpException = [WinUtilBaselineHttpException]::new($global:WinUtilBaselineTestState.HttpStatus)
                if ($global:WinUtilBaselineTestState.WrappedFailure) { throw [Exception]::new('Wrapped API failure', $httpException) }
                throw $httpException
            }
            return $global:WinUtilBaselineTestState.LiveRelease
        }
        Mock git {
            if ($Arguments[0] -eq 'ls-remote') {
                $global:LASTEXITCODE = 0
                "$($global:WinUtilBaselineTestState.AdvertisedCommit)`trefs/tags/$($global:WinUtilBaselineTestState.ExpectedTag)"
            } elseif ($Arguments[0] -eq 'fetch') {
                & $nativeGit -C $fixture fetch --quiet --no-tags $fixture $global:WinUtilBaselineTestState.FetchedCommit
            } else { & $nativeGit @Arguments }
        }
    }
    It 'verifies the committed historical identity and real Git blobs when Release metadata is missing' {
        & $verifier -Quiet -ReportPath $reportPath
        $report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
        $report.Passed | Should -BeTrue
        $report.OfficialTag | Should -Be $script:baseline.Tag
        $report.OfficialCommit | Should -Be $officialCommit
        $report.OfficialTree | Should -Be $officialTree
        $report.CandidateCommit | Should -Be $fixtureCommit
        $report.ReleaseVerification | Should -Be 'pinned-historical-stable'
        $report.ReleaseMetadataAvailable | Should -BeFalse
        $report.PinnedBaselineVerificationRun | Should -Be $script:baseline.VerifiedStableRun
        $report.ExactBlobMatchCount | Should -BeGreaterThan 0
        $report.ForbiddenModifiedPathCount | Should -Be 0
    }
    It 'builds the revised stable manifest while verifying the original upstream tag' {
        & (Join-Path $fixture 'tools/Build-WinUtilRussianRelease.ps1') -Channel stable
        $manifest = Get-Content (Join-Path $fixture 'dist/release.json') -Raw | ConvertFrom-Json
        $expectedLocale = Get-Content (Join-Path $fixture 'config/localization_ru.json') -Raw | ConvertFrom-Json
        $manifest.Version | Should -Be $expectedLocale.Meta.Version
        $manifest.BaseVersion | Should -Be $script:baseline.Tag
        $manifest.LocalizationVersion | Should -Be $expectedLocale.Meta.LocalizationVersion
        $manifest.Channel | Should -Be 'stable'
        $manifest.Prerelease | Should -BeFalse
        $manifest.SourceCommit | Should -Be $fixtureCommit
        $manifest.Sha256 | Should -Be (Get-FileHash (Join-Path $fixture 'dist/winutil-RU.ps1')).Hash.ToLowerInvariant()
        Should -Invoke Invoke-RestMethod -ParameterFilter { $Uri -eq ('https://api.github.com/repos/ChrisTitusTech/winutil/releases/tags/' + $global:WinUtilBaselineTestState.ExpectedTag) }
    }
    It 'uses live metadata when available and retains the pinned identity' {
        $global:WinUtilBaselineTestState.HttpStatus = 200
        & $verifier -Quiet -ReportPath $reportPath
        $report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
        $report.ReleaseVerification | Should -Be 'live-github-release'
        $report.ReleaseMetadataAvailable | Should -BeTrue
        $report.PinnedBaselineCommit | Should -Be $officialCommit
    }
    It 'classifies a wrapped typed HTTP 404 without parsing its message' {
        $global:WinUtilBaselineTestState.WrappedFailure = $true
        & $verifier -Quiet -ReportPath $reportPath
        (Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json).Passed | Should -BeTrue
    }
    It 'fails closed for HTTP <Status>' -ForEach @(
        @{ Status = 401 }; @{ Status = 403 }; @{ Status = 429 }; @{ Status = 500 }
    ) {
        $global:WinUtilBaselineTestState.HttpStatus = $Status
        { & $verifier -Quiet } | Should -Throw '*Unable to verify official GitHub release*'
        Should -Invoke git -Times 0 -ParameterFilter { $Arguments[0] -eq 'fetch' }
    }
    It 'does not mistake a transport error containing 404 for a missing Release' {
        $global:WinUtilBaselineTestState.TransportFailure = $true
        { & $verifier -Quiet } | Should -Throw '*Unable to verify official GitHub release*'
    }
    It 'rejects available <Flag> metadata instead of using its historical record' -ForEach @(
        @{ Flag = 'draft' }; @{ Flag = 'prerelease' }
    ) {
        $global:WinUtilBaselineTestState.HttpStatus = 200
        $global:WinUtilBaselineTestState.LiveRelease.$Flag = $true
        { & $verifier -Quiet } | Should -Throw '*not an eligible stable release*'
    }
    It 'rejects a mismatched live Release tag' {
        $global:WinUtilBaselineTestState.HttpStatus = 200
        $global:WinUtilBaselineTestState.LiveRelease.tag_name = 'other'
        { & $verifier -Quiet } | Should -Throw '*release tag mismatch*'
    }
    It 'does not use the historical record for an unpinned missing tag' {
        { & $verifier -Quiet -OfficialTag '99.99.99' } | Should -Throw '*Unable to verify official GitHub release*'
    }
    It 'does not use the historical record for a different <Override>' -ForEach @(
        @{ Override = 'api' }; @{ Override = 'git' }
    ) {
        if ($Override -eq 'api') {
            { & $verifier -Quiet -UpstreamApiRepository 'example/untrusted' } | Should -Throw '*Unable to verify official GitHub release*'
        } else {
            { & $verifier -Quiet -UpstreamRepositoryUrl 'https://example.invalid/other.git' } | Should -Throw '*Unable to verify official GitHub release*'
        }
    }
    It 'rejects a changed tag even with <Status> metadata' -ForEach @(
        @{ Status = 200 }; @{ Status = 404 }
    ) {
        $global:WinUtilBaselineTestState.HttpStatus = $Status
        $global:WinUtilBaselineTestState.AdvertisedCommit = $fixtureCommit
        $global:WinUtilBaselineTestState.FetchedCommit = $fixtureCommit
        { & $verifier -Quiet } | Should -Throw '*resolved to*expected*'
    }
    It 'rejects a fetch result that differs from the advertised tag' {
        $global:WinUtilBaselineTestState.AdvertisedCommit = $fixtureCommit
        { & $verifier -Quiet } | Should -Throw '*upstream advertised*'
    }
    It 'rejects a conflicting explicit expected commit' {
        { & $verifier -Quiet -ExpectedOfficialCommit ('a' * 40) } | Should -Throw '*conflicts with the committed upstream baseline*'
        Should -Invoke Invoke-RestMethod -Times 0
    }
    It 'rejects a mismatched recorded Git tree' {
        $script:baseline.Tree = 'a' * 40
        Save-WinUtilBaselineFixture
        { & $verifier -Quiet } | Should -Throw '*Official tree*does not match*'
    }
    It 'rejects an invalid historical record: <Variant>' -ForEach @(
        @{ Variant = 'schema' }; @{ Variant = 'repository' }; @{ Variant = 'commit' }
        @{ Variant = 'draft' }; @{ Variant = 'prerelease' }; @{ Variant = 'missing-status' }
        @{ Variant = 'tag' }; @{ Variant = 'evidence' }
    ) {
        switch ($Variant) {
            'schema' { $script:baseline.SchemaVersion = 2 }
            'repository' { $script:baseline.Repository = 'example/other' }
            'commit' { $script:baseline.Commit = 'main' }
            'draft' { $script:baseline.Release.draft = $true }
            'prerelease' { $script:baseline.Release.prerelease = $true }
            'missing-status' { $script:baseline.Release.PSObject.Properties.Remove('draft') }
            'tag' { $script:baseline.Release.tag_name = 'other' }
            'evidence' { $script:baseline.VerifiedStableRun = '' }
        }
        Save-WinUtilBaselineFixture
        { & $verifier -Quiet } | Should -Throw '*not a valid previously verified stable release*'
    }
    It 'rejects a missing committed policy' {
        & $nativeGit -C $fixture rm --quiet tools/WinUtilUpstreamBaseline.json
        & $nativeGit -C $fixture -c user.name='WinUtil Test' -c user.email='test@example.invalid' commit --quiet -m 'Remove fixture policy'
        { & $verifier -Quiet } | Should -Throw '*Unable to read committed upstream baseline*'
    }
    It 'rejects actual policy changes concealed with assume-unchanged' {
        & $nativeGit -C $fixture update-index --assume-unchanged tools/WinUtilUpstreamBaseline.json
        try {
            [IO.File]::AppendAllText($baselinePath, "`nUNCOMMITTED_POLICY_MARKER")
            { & $verifier -Quiet } | Should -Throw '*Build inputs must match committed HEAD*'
            Should -Invoke Invoke-RestMethod -Times 0
        } finally {
            & $nativeGit -C $fixture update-index --no-assume-unchanged tools/WinUtilUpstreamBaseline.json
        }
    }
    It 'still rejects a committed protected backend change after HTTP 404' {
        [IO.File]::AppendAllText((Join-Path $fixture 'functions/private/Set-WinUtilDNS.ps1'), "`n# forbidden backend marker")
        & $nativeGit -C $fixture add functions/private/Set-WinUtilDNS.ps1
        & $nativeGit -C $fixture -c user.name='WinUtil Test' -c user.email='test@example.invalid' commit --quiet -m 'Change protected fixture backend'
        { & $verifier -Quiet -ReportPath $reportPath } | Should -Throw '*Forbidden modified upstream paths*'
        (Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json).Passed | Should -BeFalse
    }
    It 'still requires the candidate to descend from the pinned commit' {
        & $nativeGit -C $fixture switch --orphan unrelated-baseline --quiet
        & $nativeGit -C $fixture read-tree $fixtureCommit
        & $nativeGit -C $fixture checkout-index -a -f
        & $nativeGit -C $fixture -c user.name='WinUtil Test' -c user.email='test@example.invalid' commit --quiet -m 'Unrelated fixture history'
        { & $verifier -Quiet } | Should -Throw '*not descended from exact official tag commit*'
    }
}
