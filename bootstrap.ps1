# WindowManager Russian edition bootstrap.
# Keep this file ASCII-only and without a UTF-8 BOM so Windows PowerShell 5.1
# can execute it safely through: irm <raw-url> | iex

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

if ([string]::IsNullOrWhiteSpace($env:WINDOWMANAGER_BRANCH)) {
    $env:WINDOWMANAGER_BRANCH = 'russian'
}

$branch = $env:WINDOWMANAGER_BRANCH
$launcherUrl = "https://raw.githubusercontent.com/TokhirjonYuldoshev/WindowManager/$branch/run-russian.ps1"
$launcherText = $null
$lastError = $null

for ($attempt = 1; $attempt -le 3 -and -not $launcherText; $attempt++) {
    try {
        $response = Invoke-WebRequest -Uri $launcherUrl -UseBasicParsing -TimeoutSec 30
        $launcherText = [string]$response.Content
    }
    catch {
        $lastError = $_
        if ($attempt -lt 3) {
            Start-Sleep -Seconds 2
        }
    }
}

if ([string]::IsNullOrWhiteSpace($launcherText)) {
    if ($lastError) {
        throw "Unable to download WindowManager launcher from GitHub after 3 attempts. $($lastError.Exception.Message)"
    }
    throw "Unable to download WindowManager launcher from GitHub after 3 attempts."
}

$launcherText = $launcherText.TrimStart([char]0xFEFF)
Invoke-Expression $launcherText
