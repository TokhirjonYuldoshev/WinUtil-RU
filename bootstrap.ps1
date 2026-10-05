# WinUtil RU bootstrap.
# Keep this file ASCII-only and without a UTF-8 BOM so Windows PowerShell 5.1
# can execute it safely through: irm <raw-url> | iex

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

if (-not [string]::IsNullOrWhiteSpace($env:WINUTIL_RU_BRANCH)) {
    $branch = $env:WINUTIL_RU_BRANCH
}
elseif (-not [string]::IsNullOrWhiteSpace($env:WINDOWMANAGER_BRANCH)) {
    # Backward compatibility with the previous WindowManager RU launcher.
    $branch = $env:WINDOWMANAGER_BRANCH
}
else {
    $branch = 'russian'
}

$env:WINUTIL_RU_BRANCH = $branch
$repoBase = 'https://raw.githubusercontent.com/TokhirjonYuldoshev/WinUtil-RU'
$launcherUrl = "$repoBase/$branch/run-russian.ps1"

function Get-WMRemoteText {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [int]$Attempts = 3,
        [int]$TimeoutSec = 20
    )

    $lastError = $null
    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        try {
            $response = Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec $TimeoutSec -Headers @{ 'User-Agent' = 'WinUtil-RU' }
            return [string]$response.Content
        }
        catch {
            $lastError = $_
            if ($attempt -lt $Attempts) {
                Start-Sleep -Seconds 2
            }
        }
    }

    if ($lastError) {
        throw $lastError
    }
    return $null
}

function Invoke-WMStandalone {
    param([Parameter(Mandatory = $true)][string]$ScriptPath)

    $previousRestartCapability = $env:WINDOWMANAGER_LAUNCHER_RESTART
    $env:WINDOWMANAGER_LAUNCHER_RESTART = '1'
    $shell = if (Get-Command pwsh.exe -ErrorAction SilentlyContinue) { 'pwsh.exe' } else { 'powershell.exe' }
    $restartRegistryPath = 'HKCU:\Software\YTY\WindowManager'

    try {
        do {
            if (Test-Path $restartRegistryPath) {
                Remove-ItemProperty -Path $restartRegistryPath -Name 'RestartRequested' -ErrorAction SilentlyContinue
            }

            & $shell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath
            if ($LASTEXITCODE -ne 0) {
                throw "WinUtil RU exited with code $LASTEXITCODE."
            }

            $restartRequested = $false
            try {
                $restartRequested = [bool]((Get-ItemProperty -Path $restartRegistryPath -Name 'RestartRequested' -ErrorAction Stop).RestartRequested)
            }
            catch {
                $restartRequested = $false
            }
        } while ($restartRequested)

        Remove-ItemProperty -Path $restartRegistryPath -Name 'RestartRequested' -ErrorAction SilentlyContinue
    }
    finally {
        if ($null -eq $previousRestartCapability) {
            Remove-Item Env:\WINDOWMANAGER_LAUNCHER_RESTART -ErrorAction SilentlyContinue
        }
        else {
            $env:WINDOWMANAGER_LAUNCHER_RESTART = $previousRestartCapability
        }
    }
}

# Development always downloads current source, runs preflight, and compiles.
if ($branch -eq 'russian-dev') {
    $launcherText = Get-WMRemoteText -Uri $launcherUrl -Attempts 3 -TimeoutSec 30
    $launcherText = $launcherText.TrimStart([char]0xFEFF)
    Invoke-Expression $launcherText
    return
}

# Stable channel uses a persistent compiled cache.
$cacheRoot = Join-Path $env:LOCALAPPDATA 'YTY\WindowManager\Stable'
$cachedScript = Join-Path $cacheRoot 'winutil-RU.ps1'
$cachedManifest = Join-Path $cacheRoot 'release.json'
$remoteLocaleUrl = "$repoBase/$branch/config/localization_ru.json"
$remoteBranchApiUrl = "https://api.github.com/repos/TokhirjonYuldoshev/WinUtil-RU/branches/$branch"

$remoteVersion = $null
try {
    $localeText = Get-WMRemoteText -Uri $remoteLocaleUrl -Attempts 2 -TimeoutSec 10
    $locale = $localeText | ConvertFrom-Json
    $remoteVersion = [string]$locale.Meta.Version
}
catch {
    # A cached stable build must remain usable when GitHub is temporarily unavailable.
}

$remoteCommit = $null
try {
    $branchText = Get-WMRemoteText -Uri $remoteBranchApiUrl -Attempts 2 -TimeoutSec 10
    $branchInfo = $branchText | ConvertFrom-Json
    $remoteCommit = [string]$branchInfo.commit.sha
}
catch {
    # Version-only cache validation remains available if the GitHub API is temporarily unavailable.
}

$localVersion = $null
$localCommit = $null
$cacheIntegrityOk = $false
if ((Test-Path -LiteralPath $cachedManifest) -and (Test-Path -LiteralPath $cachedScript)) {
    try {
        $localManifest = Get-Content -LiteralPath $cachedManifest -Raw -Encoding UTF8 | ConvertFrom-Json
        $localVersion = [string]$localManifest.Version
        $localCommit = [string]$localManifest.SourceCommit
        $expectedHash = [string]$localManifest.Sha256
        if (-not [string]::IsNullOrWhiteSpace($expectedHash)) {
            $actualHash = (Get-FileHash -LiteralPath $cachedScript -Algorithm SHA256).Hash.ToLowerInvariant()
            $cacheIntegrityOk = $actualHash -eq $expectedHash.ToLowerInvariant()
        }
    }
    catch {
        $localVersion = $null
        $localCommit = $null
        $cacheIntegrityOk = $false
    }
}

$versionMatches = [string]::IsNullOrWhiteSpace($remoteVersion) -or $remoteVersion -eq $localVersion
$commitMatches = [string]::IsNullOrWhiteSpace($remoteCommit) -or $remoteCommit -eq $localCommit

if (
    $cacheIntegrityOk -and
    $versionMatches -and
    $commitMatches
) {
    Write-Host "WinUtil RU $localVersion - local cache" -ForegroundColor Green
    Invoke-WMStandalone -ScriptPath $cachedScript
    return
}

# No cache or a new stable version/commit is available. The stable launcher downloads source,
# validates it, compiles once, and refreshes the persistent compiled cache.
try {
    $launcherText = Get-WMRemoteText -Uri $launcherUrl -Attempts 3 -TimeoutSec 30
    $launcherText = $launcherText.TrimStart([char]0xFEFF)
    Invoke-Expression $launcherText
}
catch {
    if ($cacheIntegrityOk) {
        Write-Warning "Stable update failed; starting the last verified local cache."
        Invoke-WMStandalone -ScriptPath $cachedScript
        return
    }
    throw
}
