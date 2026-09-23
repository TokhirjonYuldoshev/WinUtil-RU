param(
    [switch]$SkipPreflight
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$distRoot = Join-Path $repoRoot 'dist'
$artifactPath = Join-Path $distRoot 'WindowManager-RU.ps1'
$manifestPath = Join-Path $distRoot 'release.json'

Push-Location $repoRoot
try {
    if (-not $SkipPreflight) {
        & (Join-Path $repoRoot 'tools\Test-WinUtilRussianEdition.ps1') -Quiet
        if ($LASTEXITCODE -ne 0) {
            throw "Russian edition preflight failed."
        }
    }

    & (Join-Path $repoRoot 'Compile.ps1')
    if ($LASTEXITCODE -ne 0) {
        throw "Compile.ps1 failed with exit code $LASTEXITCODE."
    }

    New-Item -ItemType Directory -Path $distRoot -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot 'winutil.ps1') -Destination $artifactPath -Force

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

    $manifest = [ordered]@{
        SchemaVersion = 1
        Product = 'WindowManager Russian Edition'
        Channel = 'stable'
        Version = [string]$locale.Meta.Version
        SourceCommit = $sourceCommit
        Artifact = 'WindowManager-RU.ps1'
        Sha256 = $artifactHash
        SizeBytes = $artifactSize
        BuiltAtUtc = (Get-Date).ToUniversalTime().ToString('o')
        IconCacheTtlDays = 30
        IconManifest = $iconManifest
    }

    $json = $manifest | ConvertTo-Json -Depth 8
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($manifestPath, $json + [Environment]::NewLine, $utf8NoBom)

    Write-Host "Built WindowManager RU $($manifest.Version)" -ForegroundColor Green
    Write-Host "Artifact: $artifactPath"
    Write-Host "SHA256:   $artifactHash"
    Write-Host "Manifest: $manifestPath"
}
finally {
    Pop-Location
}
