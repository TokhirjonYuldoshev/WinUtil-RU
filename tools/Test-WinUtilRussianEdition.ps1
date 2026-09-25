[CmdletBinding()]
param(
    [string]$OfficialTag,
    [string]$ExpectedOfficialCommit,
    [string]$UpstreamRepositoryUrl = 'https://github.com/ChrisTitusTech/winutil.git',
    [string]$UpstreamApiRepository = 'ChrisTitusTech/winutil',
    [string]$ReportPath,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Invoke-WinUtilGit {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        # Windows PowerShell 5.1 surfaces native stderr (for example git fetch
        # progress) as ErrorRecord objects. Keep those capturable without turning
        # successful native commands into terminating PowerShell errors.
        $ErrorActionPreference = 'Continue'
        $output = @(& git @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($exitCode -ne 0) {
        $rendered = ($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
        throw "git $($Arguments -join ' ') failed with exit code $exitCode.`n$rendered"
    }

    return $output
}

function Get-WinUtilGitTreeMap {
    param(
        [Parameter(Mandatory)]
        [string]$Ref,

        [Parameter(Mandatory)]
        [string[]]$PathSpecs
    )

    $arguments = @('ls-tree', '-r', $Ref, '--') + $PathSpecs
    $lines = @(Invoke-WinUtilGit -Arguments $arguments)
    $map = @{}

    foreach ($lineObject in $lines) {
        $line = [string]$lineObject
        if ($line -notmatch '^(?<Mode>\d+)\s+(?<Type>\S+)\s+(?<Sha>[0-9a-f]{40})\t(?<Path>.+)$') {
            throw "Unable to parse git ls-tree output: $line"
        }

        if ($Matches.Type -ne 'blob') {
            throw "Protected path is not a blob: $($Matches.Path) ($($Matches.Type))"
        }

        $map[$Matches.Path] = $Matches.Sha
    }

    return $map
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'git is required for WinUtil RU parity verification.'
}

Push-Location $repoRoot
try {
    $gitTopLevel = [string](@(Invoke-WinUtilGit -Arguments @('rev-parse', '--show-toplevel'))[0])
    if ([IO.Path]::GetFullPath($gitTopLevel.Trim()) -ne [IO.Path]::GetFullPath($repoRoot)) {
        throw "Preflight must run from the WinUtil RU repository. Git root: $gitTopLevel"
    }

    $localePath = Join-Path $repoRoot 'config\localization_ru.json'
    if (-not (Test-Path -LiteralPath $localePath)) {
        throw 'config/localization_ru.json is required.'
    }

    $locale = Get-Content -LiteralPath $localePath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([string]$locale.Meta.Language -ne 'ru-RU') {
        throw "Localization Meta.Language must be ru-RU, got '$($locale.Meta.Language)'."
    }
    if ([string]$locale.Meta.Fallback -ne 'en-US') {
        throw "Localization Meta.Fallback must be en-US, got '$($locale.Meta.Fallback)'."
    }

    if (-not $OfficialTag) {
        $publicVersion = [string]$locale.Meta.Version
        if ($publicVersion -notmatch '^(?<BaseVersion>.+)-RU$') {
            throw "Localization Meta.Version must end in -RU, got '$publicVersion'."
        }
        $OfficialTag = $Matches.BaseVersion
    }

    if ($OfficialTag -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
        throw "Official tag contains unsupported characters: '$OfficialTag'."
    }

    if ($ExpectedOfficialCommit -and $ExpectedOfficialCommit -notmatch '^[0-9a-fA-F]{40}$') {
        throw 'ExpectedOfficialCommit must be a full 40-character SHA.'
    }

    $headers = @{
        Accept = 'application/vnd.github+json'
        'User-Agent' = 'WinUtil-RU-strict-parity'
        'X-GitHub-Api-Version' = '2022-11-28'
    }
    if ($env:GITHUB_TOKEN) {
        $headers.Authorization = "Bearer $env:GITHUB_TOKEN"
    }

    $encodedTag = [Uri]::EscapeDataString($OfficialTag)
    $releaseUri = "https://api.github.com/repos/$UpstreamApiRepository/releases/tags/$encodedTag"
    try {
        $release = Invoke-RestMethod -Uri $releaseUri -Headers $headers -Method Get
    }
    catch {
        throw "Unable to verify official GitHub release '$OfficialTag': $($_.Exception.Message)"
    }

    if ([string]$release.tag_name -ne $OfficialTag) {
        throw "GitHub release tag mismatch: expected '$OfficialTag', got '$($release.tag_name)'."
    }
    if ([bool]$release.draft -or [bool]$release.prerelease) {
        throw "Official tag '$OfficialTag' is not an eligible stable release (draft=$($release.draft), prerelease=$($release.prerelease))."
    }

    $tagRef = "refs/tags/$OfficialTag"
    $peeledTagRef = "$tagRef^{}"
    $remoteLines = @(Invoke-WinUtilGit -Arguments @('ls-remote', '--tags', $UpstreamRepositoryUrl, $tagRef, $peeledTagRef))
    $directMatches = @()
    $peeledMatches = @()

    foreach ($remoteLineObject in $remoteLines) {
        $remoteLine = [string]$remoteLineObject
        $parts = $remoteLine -split "`t", 2
        if ($parts.Count -ne 2) {
            throw "Unable to parse git ls-remote output: $remoteLine"
        }

        if ($parts[1] -eq $tagRef) {
            $directMatches += $parts[0]
        }
        elseif ($parts[1] -eq $peeledTagRef) {
            $peeledMatches += $parts[0]
        }
    }

    if ($directMatches.Count -ne 1) {
        throw "Expected exactly one upstream tag ref '$tagRef', found $($directMatches.Count)."
    }
    if ($peeledMatches.Count -gt 1) {
        throw "Ambiguous peeled tag ref '$peeledTagRef'."
    }

    $advertisedCommit = if ($peeledMatches.Count -eq 1) {
        [string]$peeledMatches[0]
    }
    else {
        [string]$directMatches[0]
    }

    Invoke-WinUtilGit -Arguments @('fetch', '--no-tags', '--force', $UpstreamRepositoryUrl, $tagRef) | Out-Null
    $officialCommit = ([string](@(Invoke-WinUtilGit -Arguments @('rev-parse', 'FETCH_HEAD^{commit}'))[0])).Trim().ToLowerInvariant()
    $advertisedCommit = $advertisedCommit.Trim().ToLowerInvariant()

    if ($officialCommit -ne $advertisedCommit) {
        throw "Fetched official tag resolved to $officialCommit, but upstream advertised $advertisedCommit."
    }

    if ($ExpectedOfficialCommit -and $officialCommit -ne $ExpectedOfficialCommit.ToLowerInvariant()) {
        throw "Official tag '$OfficialTag' resolved to $officialCommit, expected $($ExpectedOfficialCommit.ToLowerInvariant())."
    }

    $candidateCommit = ([string](@(Invoke-WinUtilGit -Arguments @('rev-parse', 'HEAD'))[0])).Trim().ToLowerInvariant()

    & git merge-base --is-ancestor $officialCommit $candidateCommit *> $null
    $ancestorExitCode = $LASTEXITCODE
    if ($ancestorExitCode -eq 1) {
        throw "Candidate $candidateCommit is not descended from exact official tag commit $officialCommit."
    }
    if ($ancestorExitCode -ne 0) {
        throw "git merge-base --is-ancestor failed with exit code $ancestorExitCode."
    }

    # Protected runtime/config surface. New upstream files under these roots are
    # automatically included in the next candidate's parity check.
    $protectedPathSpecs = @(
        'functions',
        'scripts',
        'config',
        'xaml',
        'tools/autounattend.xml',
        'LICENSE'
    )

    # These upstream files are intentionally different because they implement only
    # visible localization, language selection, YTY/About, or fork launcher behavior.
    # Any new modified upstream path is a blocker until it is explicitly reviewed.
    $allowedModifiedPaths = @(
        'functions/private/Find-AppsByNameOrDescription.ps1',
        'functions/private/Get-WinUtilEntryToolTip.ps1',
        'functions/private/Initialize-InstallAppEntry.ps1',
        'functions/private/Initialize-InstallCategoryAppList.ps1',
        'functions/private/Reset-WPFCheckBoxes.ps1',
        'functions/private/Set-WinUtilTweaksProgressIndicator.ps1',
        'functions/private/Show-CustomDialog.ps1',
        'functions/public/Invoke-WPFSelectedCheckboxesUpdate.ps1',
        'functions/public/Invoke-WPFUIElements.ps1',
        'scripts/main.ps1',
        'scripts/start.ps1',
        'xaml/inputXML.xaml'
    )

    # Russian-only additions are allowed only in this explicit set inside protected roots.
    $allowedAddedPaths = @(
        'config/applications_ru.json',
        'config/localization_ru.json',
        'functions/private/Initialize-WinUtilRussianLocalization.ps1',
        'functions/private/Set-WinUtilLanguagePreference.ps1'
    )

    $officialTree = Get-WinUtilGitTreeMap -Ref $officialCommit -PathSpecs $protectedPathSpecs
    $candidateTree = Get-WinUtilGitTreeMap -Ref $candidateCommit -PathSpecs $protectedPathSpecs

    $equalPaths = @()
    $allowedDifferences = @()
    $missingPaths = @()
    $forbiddenDifferences = @()

    foreach ($path in @($officialTree.Keys | Sort-Object)) {
        if (-not $candidateTree.ContainsKey($path)) {
            $missingPaths += $path
            continue
        }

        if ([string]$candidateTree[$path] -eq [string]$officialTree[$path]) {
            $equalPaths += $path
        }
        elseif ($allowedModifiedPaths -contains $path) {
            $allowedDifferences += $path
        }
        else {
            $forbiddenDifferences += $path
        }
    }

    $allowedAdditions = @()
    $forbiddenAdditions = @()
    foreach ($path in @($candidateTree.Keys | Sort-Object)) {
        if ($officialTree.ContainsKey($path)) {
            continue
        }

        if ($allowedAddedPaths -contains $path) {
            $allowedAdditions += $path
        }
        else {
            $forbiddenAdditions += $path
        }
    }

    $missingRequiredAdditions = @(
        $allowedAddedPaths | Where-Object { -not $candidateTree.ContainsKey($_) }
    )

    $failures = @()
    if ($missingPaths.Count -gt 0) {
        $failures += "Missing protected upstream paths:`n  - $($missingPaths -join "`n  - ")"
    }
    if ($forbiddenDifferences.Count -gt 0) {
        $failures += "Forbidden modified upstream paths:`n  - $($forbiddenDifferences -join "`n  - ")"
    }
    if ($forbiddenAdditions.Count -gt 0) {
        $failures += "Forbidden additions inside protected roots:`n  - $($forbiddenAdditions -join "`n  - ")"
    }
    if ($missingRequiredAdditions.Count -gt 0) {
        $failures += "Required RU localization additions are missing:`n  - $($missingRequiredAdditions -join "`n  - ")"
    }

    $report = [ordered]@{
        SchemaVersion = 1
        UpstreamRepository = $UpstreamApiRepository
        OfficialTag = $OfficialTag
        OfficialCommit = $officialCommit
        CandidateCommit = $candidateCommit
        ReleaseDraft = [bool]$release.draft
        ReleasePrerelease = [bool]$release.prerelease
        ProtectedUpstreamPathCount = $officialTree.Count
        ExactBlobMatchCount = $equalPaths.Count
        AllowedModifiedPathCount = $allowedDifferences.Count
        MissingPathCount = $missingPaths.Count
        ForbiddenModifiedPathCount = $forbiddenDifferences.Count
        AllowedAdditionCount = $allowedAdditions.Count
        ForbiddenAdditionCount = $forbiddenAdditions.Count
        AllowedModifiedPaths = @($allowedDifferences)
        AllowedAddedPaths = @($allowedAdditions)
        MissingPaths = @($missingPaths)
        ForbiddenModifiedPaths = @($forbiddenDifferences)
        ForbiddenAddedPaths = @($forbiddenAdditions)
        MissingRequiredAdditions = @($missingRequiredAdditions)
        Passed = $failures.Count -eq 0
    }

    if ($ReportPath) {
        $resolvedReportPath = [IO.Path]::GetFullPath($ReportPath)
        $reportDirectory = Split-Path -Parent $resolvedReportPath
        if ($reportDirectory -and -not (Test-Path -LiteralPath $reportDirectory)) {
            New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
        }
        $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $resolvedReportPath -Encoding UTF8
    }

    if ($failures.Count -gt 0) {
        throw "WinUtil RU strict parity failed for '$OfficialTag' ($officialCommit).`n`n$($failures -join "`n`n")"
    }

    if (-not $Quiet) {
        Write-Host 'WinUtil RU strict parity PASSED.' -ForegroundColor Green
        Write-Host "Official release : $OfficialTag"
        Write-Host "Official commit  : $officialCommit"
        Write-Host "Candidate commit : $candidateCommit"
        Write-Host "Protected paths  : $($officialTree.Count)"
        Write-Host "Exact blob match : $($equalPaths.Count)"
        Write-Host "Allowed modified : $($allowedDifferences.Count)"
        Write-Host "Allowed additions: $($allowedAdditions.Count)"
        if ($allowedDifferences.Count -gt 0) {
            Write-Host 'Reviewed UI/launcher differences:'
            $allowedDifferences | ForEach-Object { Write-Host "  - $_" }
        }
    }
}
finally {
    Pop-Location
}
