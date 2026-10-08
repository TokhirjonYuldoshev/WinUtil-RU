param(
    [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$')][string]$Repository,
    [Parameter(Mandatory)][ValidatePattern('^[0-9a-fA-F]{40}$')][string]$SourceCommit,
    [string]$DistRoot = (Join-Path $PSScriptRoot '../dist')
)

$ErrorActionPreference = 'Stop'

function Get-WinUtilRemoteTagCommit {
    param([Parameter(Mandatory)][string]$Tag)
    $ref = "refs/tags/$Tag"
    $lines = @(& git ls-remote --tags origin $ref "$ref^{}")
    if ($LASTEXITCODE -ne 0) { throw 'Failed to read remote Git tags; refusing publication.' }
    $targets = @{}
    foreach ($line in $lines) {
        if ([string]$line -notmatch '^([0-9a-fA-F]{40})\s+(refs/tags/.+)$') { throw 'Invalid remote tag response.' }
        $sha = $Matches[1].ToLowerInvariant()
        $name = $Matches[2]
        if ($name -notin @($ref, "$ref^{}") -or $targets.ContainsKey($name)) { throw 'Ambiguous remote tag response.' }
        $targets[$name] = $sha
    }
    if ($targets.Count -eq 0) { return $null }
    if (-not $targets.ContainsKey($ref)) { throw 'The remote tag has no direct reference.' }
    # ls-remote returns the peeled object for annotated tags, and the direct
    # commit for lightweight tags. Local checkout tags are not authoritative.
    if ($targets.ContainsKey("$ref^{}")) { return $targets["$ref^{}"] }
    return $targets[$ref]
}

function Publish-WinUtilRussianRelease {
    param([string]$Repository, [string]$SourceCommit, [string]$DistRoot)
    $SourceCommit = $SourceCommit.ToLowerInvariant()
    $manifest = Get-Content -LiteralPath (Join-Path $DistRoot 'release.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $tag = [string]$manifest.Version
    if ($tag -notmatch '^\d{2}\.\d{2}\.\d{2}-RU(?:\.[1-9]\d*)?$') { throw 'Invalid stable release tag.' }
    if ([string]$manifest.Channel -ne 'stable' -or [bool]$manifest.Prerelease -or [string]$manifest.SourceCommit -ne $SourceCommit) {
        throw 'The stable manifest does not match the expected source commit.'
    }
    $scriptPath = Join-Path $DistRoot 'winutil-RU.ps1'
    $licensePath = Join-Path $DistRoot 'LICENSE'
    if (-not (Test-Path -LiteralPath $licensePath -PathType Leaf)) { throw 'The release LICENSE asset is missing.' }
    $hash = (Get-FileHash -LiteralPath $scriptPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -ne [string]$manifest.Sha256) { throw 'The stable artifact SHA256 does not match its manifest.' }

    $target = Get-WinUtilRemoteTagCommit -Tag $tag
    if ($null -ne $target -and $target -ne $SourceCommit) {
        throw "Git tag $tag points at $target, expected $SourceCommit. Refusing to reuse or replace it."
    }

    # Listing succeeds with an empty list when there is no release. API or
    # authentication errors must not be mistaken for an absent release.
    $releaseJson = & gh api "repos/$Repository/releases?per_page=100" --paginate --slurp
    if ($LASTEXITCODE -ne 0) { throw 'Failed to read existing releases; refusing publication.' }
    $pages = ($releaseJson -join [Environment]::NewLine) | ConvertFrom-Json
    $existing = @($pages | ForEach-Object { $_ } | Where-Object { [string]$_.tag_name -eq $tag })
    if ($existing.Count -gt 0) {
        if ($existing.Count -ne 1 -or $null -eq $target -or [bool]$existing[0].draft -or [bool]$existing[0].prerelease) {
            throw "Stable release $tag exists in an unexpected state. Refusing to change it."
        }
        Write-Host "Stable release $tag already has the verified Git tag at $SourceCommit."
        return
    }

    if ($null -eq $target) {
        # A non-forced push atomically creates the exact tag or rejects a race.
        # gh release create must never choose an existing, unverified tag.
        & git push origin "${SourceCommit}:refs/tags/$tag" | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "Failed to create exact Git tag $tag; refusing publication." }
    }
    if ((Get-WinUtilRemoteTagCommit -Tag $tag) -ne $SourceCommit) { throw 'The Git tag changed before publication.' }
    & gh release create $tag $scriptPath (Join-Path $DistRoot 'release.json') $licensePath --repo $Repository --verify-tag --target $SourceCommit --title "WinUtil RU $tag" --generate-notes --latest | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "Failed to publish stable release $tag." }
    if ((Get-WinUtilRemoteTagCommit -Tag $tag) -ne $SourceCommit) { throw 'Published release Git tag does not match its source commit.' }
    Write-Host "Stable release published: $tag -> $SourceCommit"
}

Publish-WinUtilRussianRelease -Repository $Repository -SourceCommit $SourceCommit -DistRoot $DistRoot
