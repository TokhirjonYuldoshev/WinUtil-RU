param(
    [ValidateSet('stable', 'beta')]
    [string]$Channel = 'stable'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$distRoot = Join-Path $repoRoot 'dist'
$artifactPath = Join-Path $distRoot 'winutil-RU.ps1'
$manifestPath = Join-Path $distRoot 'release.json'
$licenseAssetPath = Join-Path $distRoot 'LICENSE'

Push-Location $repoRoot
try {
    if (-not $SkipPreflight) {
        & (Join-Path $repoRoot 'tools\Test-WinUtilRussianEdition.ps1') -Quiet
        if ($LASTEXITCODE -ne 0) {
            throw "Russian edition preflight failed."
        }
    }

    & (Join-Path $repoRoot 'Compile.ps1')
    if (-not $?) {
        throw "Compile.ps1 failed."
    }

    New-Item -ItemType Directory -Path $distRoot -Force | Out-Null

    # The standalone release must carry the original MIT notice even when the user
    # downloads only the PowerShell artifact rather than the whole repository.
    $compiledPath = Join-Path $repoRoot 'winutil.ps1'
    if (-not (Test-Path -LiteralPath $compiledPath)) {
        throw "Compile.ps1 did not create winutil.ps1."
    }
    $compiledText = Get-Content -LiteralPath $compiledPath -Raw -Encoding UTF8
    $licenseSourcePath = Join-Path $repoRoot 'LICENSE'
    $licenseText = Get-Content -LiteralPath $licenseSourcePath -Raw -Encoding UTF8
    $licenseHeader = @"
<#
WinUtil RU
Independent Russian localization/fork of Chris Titus Tech's WinUtil.
Original project: https://github.com/ChrisTitusTech/winutil

$licenseText
#>

"@
    $utf8Bom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($artifactPath, $licenseHeader + $compiledText, $utf8Bom)
    Copy-Item -LiteralPath $licenseSourcePath -Destination $licenseAssetPath -Force

    $locale = Get-Content -LiteralPath (Join-Path $repoRoot 'config\localization_ru.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $applications = Get-Content -LiteralPath (Join-Path $repoRoot 'config\applications.json') -Raw -Encoding UTF8 | ConvertFrom-Json

    $sourceCommit = $null
    if (Get-Command git.exe -ErrorAction SilentlyContinue) {
        try {
            $sourceCommit = (& git.exe rev-parse HEAD 2>$null).Trim()
        } catch {
            $sourceCommit = $null
        }
    }

    $iconManifest = @(
        $applications.PSObject.Properties | ForEach-Object {
            if ($_.Value.link) {
                [ordered]@{
                    Key = $_.Name
                    Link = [string]$_.Value.link
                }
            }
        }
    )

    $artifactHash = (Get-FileHash -LiteralPath $artifactPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $artifactSize = (Get-Item -LiteralPath $artifactPath).Length

    $publicVersion = [string]$locale.Meta.Version
    $baseVersion = $publicVersion -replace '-RU$', ''

    $isPrerelease = $Channel -eq 'beta'

    $manifest = [ordered]@{
        SchemaVersion = 2
        Product = 'WinUtil RU'
        Channel = $Channel
        Prerelease = $isPrerelease
        Version = $publicVersion
        BaseVersion = $baseVersion
        LocalizationVersion = [string]$locale.Meta.LocalizationVersion
        SourceCommit = $sourceCommit
        Artifact = 'winutil-RU.ps1'
        License = 'LICENSE'
        Sha256 = $artifactHash
        SizeBytes = $artifactSize
        BuiltAtUtc = (Get-Date).ToUniversalTime().ToString('o')
        IconCacheTtlDays = 30
        IconManifest = $iconManifest
    }

    $json = $manifest | ConvertTo-Json -Depth 8
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($manifestPath, $json + [Environment]::NewLine, $utf8NoBom)

    $displaySuffix = if ($isPrerelease) { '-Beta' } else { '' }
    Write-Host "Built WinUtil RU $($manifest.Version)$displaySuffix" -ForegroundColor Green
    Write-Host "Artifact: $artifactPath"
    Write-Host "SHA256:   $artifactHash"
    Write-Host "Manifest: $manifestPath"
}
finally {
    Pop-Location
}
