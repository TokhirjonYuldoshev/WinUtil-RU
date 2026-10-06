# WinUtil RU bootstrap. ASCII-only, no BOM for Windows PowerShell 5.1 irm | iex.
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

function Get-WMRemoteText {
    param([Parameter(Mandatory = $true)][string]$Uri, [int]$Attempts = 3, [int]$TimeoutSec = 20)
    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        try {
            $response = Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec $TimeoutSec -Headers @{ 'User-Agent' = 'WinUtil-RU' }
            return [string]$response.Content
        } catch {
            if ($attempt -eq $Attempts) { throw }
            Start-Sleep -Seconds 2
        }
    }
}

function Get-WMSourceCommit {
    param([Parameter(Mandatory = $true)][string]$Branch)
    $encodedBranch = [Uri]::EscapeDataString($Branch)
    $info = Get-WMRemoteText -Uri "https://api.github.com/repos/TokhirjonYuldoshev/WinUtil-RU/branches/$encodedBranch" -Attempts 2 -TimeoutSec 10 | ConvertFrom-Json
    $commit = [string]$info.commit.sha
    if ($commit -notmatch '^[0-9a-fA-F]{40}$') { throw 'GitHub did not return a valid source commit.' }
    return $commit.ToLowerInvariant()
}

function Get-WMCachedBuild {
    param([Parameter(Mandatory = $true)][string]$CacheRoot)
    # A manifest is the only mutable pointer. Old scripts remain at immutable paths.
    foreach ($name in @('release.json', 'release.previous.json')) {
        try {
            $manifestPath = Join-Path $CacheRoot $name
            if (-not (Test-Path -LiteralPath $manifestPath)) { continue }
            $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $artifact = [string]$manifest.Artifact
            if ([string]::IsNullOrWhiteSpace($artifact)) { $artifact = 'winutil-RU.ps1' }
            if ($artifact -ne 'winutil-RU.ps1' -and $artifact -notmatch '^versions/[0-9a-f]{40}-[0-9a-f]{64}/winutil-RU\.ps1$') { continue }
            if ([string]$manifest.Sha256 -notmatch '^[0-9a-fA-F]{64}$') { continue }
            $path = Join-Path $CacheRoot $artifact
            if (-not (Test-Path -LiteralPath $path)) { continue }
            $actualHash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
            if ($actualHash -ne [string]$manifest.Sha256) { continue }
            return [pscustomobject]@{ ScriptPath = $path; Manifest = $manifest }
        } catch {
            # A corrupt current pointer must not hide a valid previous build.
            continue
        }
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
            if ($LASTEXITCODE -ne 0) { throw "WinUtil RU exited with code $LASTEXITCODE." }
            $restartRequested = $false
            try {
                $restartRequested = [bool]((Get-ItemProperty -Path $restartRegistryPath -Name 'RestartRequested' -ErrorAction Stop).RestartRequested)
            } catch {
                $restartRequested = $false
            }
        } while ($restartRequested)
        Remove-ItemProperty -Path $restartRegistryPath -Name 'RestartRequested' -ErrorAction SilentlyContinue
    } finally {
        if ($null -eq $previousRestartCapability) { Remove-Item Env:\WINDOWMANAGER_LAUNCHER_RESTART -ErrorAction SilentlyContinue }
        else { $env:WINDOWMANAGER_LAUNCHER_RESTART = $previousRestartCapability }
    }
}

function Invoke-WMUpdate {
    param([Parameter(Mandatory = $true)][string]$Commit)
    $previousCommit = $env:WINUTIL_RU_COMMIT
    try {
        $env:WINUTIL_RU_COMMIT = $Commit
        $launcher = Get-WMRemoteText -Uri "https://raw.githubusercontent.com/TokhirjonYuldoshev/WinUtil-RU/$Commit/run-russian.ps1" -Attempts 3 -TimeoutSec 30
        Invoke-Expression $launcher.TrimStart([char]0xFEFF)
    } finally {
        if ($null -eq $previousCommit) { Remove-Item Env:\WINUTIL_RU_COMMIT -ErrorAction SilentlyContinue }
        else { $env:WINUTIL_RU_COMMIT = $previousCommit }
    }
}

function Invoke-WMSourceBootstrap {
    param([Parameter(Mandatory = $true)][string]$Branch)
    $cacheRoot = Join-Path $env:LOCALAPPDATA 'YTY\WindowManager\Stable'
    $cached = if ($Branch -eq 'russian') { Get-WMCachedBuild -CacheRoot $cacheRoot } else { $null }
    try { $commit = Get-WMSourceCommit -Branch $Branch }
    catch {
        if ($null -eq $cached) { throw }
        Write-Warning 'GitHub commit lookup failed; starting the verified local cache.'
        Invoke-WMStandalone -ScriptPath $cached.ScriptPath
        return
    }
    if ($null -ne $cached -and [string]$cached.Manifest.SourceCommit -eq $commit) {
        Write-Host "WinUtil RU $($cached.Manifest.Version) - local cache" -ForegroundColor Green
        Invoke-WMStandalone -ScriptPath $cached.ScriptPath
        return
    }
    try { Invoke-WMUpdate -Commit $commit }
    catch {
        if ($null -eq $cached) { throw }
        # This path was verified before the update and was never overwritten.
        Write-Warning 'Stable update failed; starting the previous verified local cache.'
        Invoke-WMStandalone -ScriptPath $cached.ScriptPath
    }
}

$branch = if (-not [string]::IsNullOrWhiteSpace($env:WINUTIL_RU_BRANCH)) { $env:WINUTIL_RU_BRANCH }
elseif (-not [string]::IsNullOrWhiteSpace($env:WINDOWMANAGER_BRANCH)) { $env:WINDOWMANAGER_BRANCH }
else { 'russian' }
if ($branch -notin @('russian', 'russian-dev')) { throw 'Unsupported WinUtil RU branch.' }
$env:WINUTIL_RU_BRANCH = $branch
Invoke-WMSourceBootstrap -Branch $branch
