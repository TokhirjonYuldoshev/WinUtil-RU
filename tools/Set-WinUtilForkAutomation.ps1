param(
    [Parameter(Mandatory)][string]$Repository,
    [switch]$Apply,
    [string]$ReportPath
)

$ErrorActionPreference = 'Stop'

function Set-WinUtilForkAutomation {
    param([string]$Repository, [switch]$Apply, [string]$ReportPath)
    if ($Repository -ne 'TokhirjonYuldoshev/WinUtil-RU') { throw 'This policy applies only to the WinUtil RU fork.' }
    if ($Apply) {
        if ($env:GITHUB_ACTIONS -ne 'true' -or $env:GITHUB_REPOSITORY -ne $Repository -or
            $env:GITHUB_REF -ne 'refs/heads/russian' -or $env:GITHUB_EVENT_NAME -notin @('push', 'workflow_dispatch') -or
            $env:GITHUB_SHA -notmatch '^[0-9a-fA-F]{40}$') {
            throw 'Automation changes require a trusted russian branch workflow run.'
        }
        $checkoutCommit = & git rev-parse HEAD
        if ($LASTEXITCODE -ne 0 -or [string]$checkoutCommit -ne $env:GITHUB_SHA) { throw 'Workflow checkout does not match the trusted source commit.' }
    }

    # Repository-level disable also covers unguarded definitions on retained
    # upstream branches/tags. Never rewrite those refs or disable fork CI.
    $names = @('pre-release.yaml', 'auto-merge-docs.yaml', 'sponsors.yaml',
        'generate-title-screen.yaml', 'docs.yaml', 'close-old-issues.yaml', 'close-discussion-on-pr.yaml')
    $workflows = @()
    foreach ($name in $names) {
        $response = & gh api "repos/$Repository/actions/workflows/$name"
        if ($LASTEXITCODE -ne 0) { throw "Failed to inspect workflow $name." }
        $workflow = ($response -join [Environment]::NewLine) | ConvertFrom-Json
        if ([string]$workflow.path -ne ".github/workflows/$name") { throw "Unexpected workflow path for $name." }
        $workflows += [pscustomobject]@{ File = $name; Before = [string]$workflow.state; After = [string]$workflow.state }
    }
    foreach ($workflow in $workflows) {
        if ($Apply -and $workflow.Before -ne 'disabled_manually') {
            & gh api --method PUT "repos/$Repository/actions/workflows/$($workflow.File)/disable" | Out-Host
            if ($LASTEXITCODE -ne 0) { throw "Failed to disable workflow $($workflow.File)." }
        }
        if ($Apply) {
            $response = & gh api "repos/$Repository/actions/workflows/$($workflow.File)"
            if ($LASTEXITCODE -ne 0) { throw "Failed to verify workflow $($workflow.File)." }
            $verified = ($response -join [Environment]::NewLine) | ConvertFrom-Json
            if ([string]$verified.path -ne ".github/workflows/$($workflow.File)" -or [string]$verified.state -ne 'disabled_manually') {
                throw "Workflow $($workflow.File) is not disabled at repository level."
            }
            $workflow.After = [string]$verified.state
        }
    }
    $report = [ordered]@{ Repository = $Repository; Applied = [bool]$Apply; SourceCommit = $env:GITHUB_SHA; Workflows = $workflows }
    if ($ReportPath) { $report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ReportPath -Encoding UTF8 }
    $workflows | Format-Table -AutoSize | Out-String | Write-Host
    if ($Apply) { Write-Host 'Verified repository-level disable for all seven upstream-only workflows.' }
    else { Write-Host 'Inspection only: no workflow settings changed.' }
}

Set-WinUtilForkAutomation -Repository $Repository -Apply:$Apply -ReportPath $ReportPath
