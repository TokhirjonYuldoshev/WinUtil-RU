# Fail-closed release preparation. Do not run from a local workstation.
param([switch]$DryRun)
$ErrorActionPreference = 'Stop'
$repo = 'TokhirjonYuldoshev/WinUtil-RU'
$upstream = 'ChrisTitusTech/winutil'
if ($env:GITHUB_ACTIONS -ne 'true' -or $env:GITHUB_REPOSITORY -cne $repo) { throw 'Untrusted repository.' }
if (-not $DryRun -and ($env:GITHUB_REF -ne 'refs/heads/russian' -or $env:GITHUB_EVENT_NAME -notin @('schedule','workflow_dispatch'))) { throw 'Untrusted write context.' }
if (-not $env:GH_TOKEN) { throw 'Missing GitHub token.' }

function Invoke-Git {
    param([string[]]$ArgsList)
    & git @ArgsList
    if ($LASTEXITCODE -ne 0) { throw "Git failed: $($ArgsList -join ' ')" }
}
function Get-Sha {
    param([string[]]$ArgsList)
    $values = @(& git @ArgsList)
    if ($LASTEXITCODE -ne 0 -or $values.Count -ne 1 -or [string]$values[0] -notmatch '^[a-fA-F0-9]{40}$') { throw "Invalid git SHA: $($ArgsList -join ' ')" }
    ([string]$values[0]).ToLowerInvariant()
}
function Assert-Ancestor {
    param([string]$Older,[string]$Newer,[string]$Description)
    & git merge-base --is-ancestor $Older $Newer
    if ($LASTEXITCODE -ne 0) { throw "Divergent history ($Description). Refusing modification." }
}
function Get-Gh {
    param([string]$ApiPath)
    $result = @(& gh api $ApiPath)
    if ($LASTEXITCODE -ne 0 -or $result.Count -eq 0) { throw "GitHub query failed: $ApiPath" }
    ($result -join [Environment]::NewLine) | ConvertFrom-Json
}
function Set-WorkflowOutput {
    param([string]$Key,[string]$Value)
    if ($env:GITHUB_OUTPUT) { "$Key=$Value" | Add-Content -LiteralPath $env:GITHUB_OUTPUT -Encoding utf8 }
    Write-Host "$Key=$Value"
}

$checkout = Get-Sha -ArgsList @('rev-parse','HEAD')
Invoke-Git -ArgsList @('fetch','--no-tags','origin','+refs/heads/russian:refs/remotes/origin/russian','+refs/heads/main:refs/remotes/origin/main')
$russian = Get-Sha -ArgsList @('rev-parse','refs/remotes/origin/russian')
if ($checkout -ne $russian) { throw 'russian advanced after checkout; rerun.' }
$release = Get-Gh "repos/$upstream/releases/latest"
$tag = [string]$release.tag_name
if ($release.draft -or $release.prerelease -or $tag -notmatch '^\d{2}\.\d{2}\.\d{2}$') { throw 'Invalid stable upstream tag.' }
Invoke-Git -ArgsList @('fetch','--no-tags','https://github.com/ChrisTitusTech/winutil.git',"refs/tags/$tag")
$latest = Get-Sha -ArgsList @('rev-parse','FETCH_HEAD')
$remoteCommit = Get-Gh "repos/$upstream/commits/$tag"
if ([string]$remoteCommit.sha -ne $latest) { throw 'Official GitHub tag mismatch.' }
$baseline = Get-Content 'tools/WinUtilUpstreamBaseline.json' -Raw -Encoding utf8 | ConvertFrom-Json
if ($baseline.Repository -cne $upstream -or [string]$baseline.Commit -notmatch '^[a-fA-F0-9]{40}$') { throw 'Untrusted pinned baseline.' }
$previous = ([string]$baseline.Commit).ToLowerInvariant()
Assert-Ancestor $previous $latest 'official stable history'
Assert-Ancestor $previous $russian 'russian upstream ancestry'
$forkMain = Get-Sha -ArgsList @('rev-parse','refs/remotes/origin/main')
Assert-Ancestor $previous $forkMain 'fork main baseline'
Assert-Ancestor $forkMain $latest 'fork main fast-forward'
$version = "$tag-RU.1"
if ($previous -eq $latest) {
    Write-Host "Already on official $tag; no changes."
    Set-WorkflowOutput candidate false
    exit 0
}
$locale = Get-Content 'config/localization_ru.json' -Raw -Encoding utf8 | ConvertFrom-Json
if ([string]$locale.Meta.Version -notmatch ('^'+[regex]::Escape([string]$baseline.Tag)+'-RU(?:\.[1-9]\d*)?$')) { throw 'Locale and pinned tag mismatch.' }

# A file edited by both upstream and russian requires manual review, except docs.
$upChanges = @(& git diff --name-only $previous $latest --)
if ($LASTEXITCODE -ne 0) { throw 'Upstream diff failed.' }
$ruChanges = @(& git diff --name-only $previous $russian --)
if ($LASTEXITCODE -ne 0) { throw 'Russian diff failed.' }
$overlap = @($upChanges | Where-Object { $ruChanges -ccontains $_ })
$conflicts = @($overlap | Where-Object { $_ -notmatch '^(README(\.en)?\.md|docs/.*\.mdx?|docs/.*\.json)$' })
if ($conflicts.Count) { throw "New upstream has overlapping changes requiring manual port: $($conflicts -join ', ')" }
$candidateBranch = "automation/rc-$($tag.Replace('.','-'))-ru-1"
$existing = @(& git ls-remote --heads origin "refs/heads/$candidateBranch")
if ($LASTEXITCODE -ne 0) { throw 'Failed to check existing candidate branch.' }
if ($existing.Count -gt 0) {
    Invoke-Git -ArgsList @('fetch','--no-tags','origin',"refs/heads/$candidateBranch")
    $candidateSha = Get-Sha -ArgsList @('rev-parse','FETCH_HEAD')
    Assert-Ancestor $latest $candidateSha 'candidate must contain official stable release'
    Assert-Ancestor $russian $candidateSha 'candidate must descend from exact current russian'
    $candidateLocaleRaw = @(& git show ('{0}:config/localization_ru.json' -f $candidateSha))
    if ($LASTEXITCODE -ne 0) { throw 'Cannot verify existing candidate locale.' }
    $candidateLocale = ($candidateLocaleRaw -join [Environment]::NewLine) | ConvertFrom-Json
    $candidateBaselineRaw = @(& git show ('{0}:tools/WinUtilUpstreamBaseline.json' -f $candidateSha))
    if ($LASTEXITCODE -ne 0) { throw 'Cannot verify existing candidate baseline.' }
    $candidateBaseline = ($candidateBaselineRaw -join [Environment]::NewLine) | ConvertFrom-Json
    if ([string]$candidateLocale.Meta.Version -ne $version -or [string]$candidateBaseline.Commit -ne $latest -or [string]$candidateBaseline.Tag -ne $tag) {
        throw 'Existing candidate does not match target stable release; manual review required.'
    }
    $rcTag = "$version-rc.1"
    $rcCheck = @(& gh release view $rcTag --repo $repo --json tagName 2>$null)
    if ($LASTEXITCODE -eq 0) {
        Write-Host "RC prerelease $rcTag already exists; refusing to rebuild or replace it."
        Set-WorkflowOutput candidate false
        exit 0
    }
    if ($DryRun) {
        Write-Host "DRY RUN: existing checked candidate $candidateBranch"
        Set-WorkflowOutput candidate false
        exit 0
    }
    # If a previous workflow failed after the push, resume safely using exact SHA.
    $existingPR = @(& gh pr list --repo $repo --state open --head $candidateBranch --json headRefOid --jq '.[].headRefOid')
    if ($LASTEXITCODE -ne 0) { throw 'Cannot verify existing candidate PR.' }
    if ($existingPR.Count -eq 0) {
        & gh pr create --repo $repo --base russian --head $candidateBranch --draft --title "RC: WinUtil $version ($tag)" --body "Resumed release candidate $candidateSha after interrupted automation. Test in Windows before owner approval."
        if ($LASTEXITCODE -ne 0) { throw 'Cannot resume RC PR.' }
    } elseif ($existingPR.Count -ne 1 -or [string]$existingPR[0] -ne $candidateSha) {
        throw 'Candidate branch / PR SHA mismatch.'
    }
    Set-WorkflowOutput candidate true
    Set-WorkflowOutput sha $candidateSha
    Set-WorkflowOutput tag $tag
    Set-WorkflowOutput rc_tag $rcTag
    Set-WorkflowOutput branch $candidateBranch
    exit 0
}
if ($DryRun) {
    Write-Host "DRY RUN: main $forkMain -> $latest; $candidateBranch from $russian."
    Set-WorkflowOutput candidate false
    exit 0
}
if ($forkMain -ne $latest) {
    Invoke-Git -ArgsList @('push','origin',"$($latest):refs/heads/main")
}
Invoke-Git -ArgsList @('config','user.name','github-actions[bot]')
Invoke-Git -ArgsList @('config','user.email','41898282+github-actions[bot]@users.noreply.github.com')
Invoke-Git -ArgsList @('switch','-c',$candidateBranch,$russian)
# "ours" applies only to unrelated doc conflicts; every code overlap was prohibited.
Invoke-Git -ArgsList @('merge','--no-ff','--no-commit','-X','ours',$latest)
$unmerged = @(& git ls-files -u)
if ($LASTEXITCODE -ne 0 -or $unmerged.Count) { throw 'Merge conflicts remain.' }

$localeFile = 'config/localization_ru.json'
$jsonText = Get-Content $localeFile -Raw -Encoding utf8
$regex = [regex]::new('("Version"\s*:\s*")'+[regex]::Escape([string]$locale.Meta.Version)+'(")')
if ($regex.Matches($jsonText).Count -ne 1) { throw 'Unsafe locale version substitution.' }
$jsonText = $regex.Replace($jsonText, [System.Text.RegularExpressions.MatchEvaluator]{
    param($m)
    return $m.Groups[1].Value + $version + $m.Groups[2].Value
})
[System.IO.File]::WriteAllText((Join-Path (Get-Location) $localeFile),$jsonText,[Text.UTF8Encoding]::new($false))
$treeSha = Get-Sha -ArgsList @('rev-parse',"$latest^{tree}")
$newBaseline = [ordered]@{
    SchemaVersion = 1
    Repository = $upstream
    Tag = $tag
    Commit = $latest
    Tree = $treeSha
    Release = [ordered]@{ tag_name = $tag; draft = $false; prerelease = $false }
    VerifiedStableRun = [string]$baseline.VerifiedStableRun
}
$newBaseline | ConvertTo-Json -Depth 6 | Set-Content 'tools/WinUtilUpstreamBaseline.json' -Encoding utf8
Invoke-Git -ArgsList @('add','config/localization_ru.json','tools/WinUtilUpstreamBaseline.json')
Invoke-Git -ArgsList @('commit','-m',"chore(ru): prepare $version from official stable $latest")
$sha = Get-Sha -ArgsList @('rev-parse','HEAD')
Invoke-Git -ArgsList @('push','origin',"$($sha):refs/heads/$candidateBranch")
$existingPR = @(& gh pr list --repo $repo --state all --head $candidateBranch --json number --jq '.[].number')
if ($LASTEXITCODE -ne 0 -or $existingPR.Count) { throw 'Candidate PR already exists or cannot be verified.' }
& gh pr create --repo $repo --base russian --head $candidateBranch --draft --title "RC: WinUtil $version ($tag)" --body "Automated candidate at $sha from verified upstream $latest. Only test builds may be published automatically; stable merge and release require owner approval."
if ($LASTEXITCODE -ne 0) { throw 'Candidate pushed but PR creation failed.' }
Set-WorkflowOutput candidate true
Set-WorkflowOutput sha $sha
Set-WorkflowOutput tag $tag
Set-WorkflowOutput rc_tag "$version-rc.1"
Set-WorkflowOutput branch $candidateBranch
