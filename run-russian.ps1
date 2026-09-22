$ErrorActionPreference = 'Stop'

$repoZip = 'https://github.com/TokhirjonYuldoshev/WindowManager/archive/refs/heads/russian.zip'
$tempRoot = Join-Path $env:TEMP ('WindowManager-russian-' + [guid]::NewGuid().ToString('N'))
$zipPath = Join-Path $tempRoot 'russian.zip'
$extractPath = Join-Path $tempRoot 'src'

try {
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $extractPath -Force | Out-Null

    # GitHub requires modern TLS. Windows PowerShell 5.1 may otherwise fail with
    # "The underlying connection was closed" on older Windows/.NET defaults.
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    Write-Host 'Загрузка русской версии WindowManager...' -ForegroundColor Cyan
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            Invoke-WebRequest -Uri $repoZip -OutFile $zipPath -UseBasicParsing
            break
        }
        catch {
            if ($attempt -eq 3) {
                throw
            }
            Write-Host "Повтор загрузки ($attempt/3)..." -ForegroundColor Yellow
            Start-Sleep -Seconds (2 * $attempt)
        }
    }

    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
    $projectRoot = Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1 -ExpandProperty FullName
    if (-not $projectRoot -or -not (Test-Path (Join-Path $projectRoot 'Compile.ps1'))) {
        throw 'Не удалось найти Compile.ps1 в загруженном архиве.'
    }

    # Warm the favicon cache in a background PowerShell job. It never blocks the UI:
    # first launch can still use the remote image while subsequent launches use the local file.
    $iconCacheJob = $null
    try {
        $applicationsPath = Join-Path $projectRoot 'config\applications.json'
        $applications = Get-Content -LiteralPath $applicationsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $iconManifest = @(
            $applications.PSObject.Properties | ForEach-Object {
                if ($_.Value.link) {
                    [pscustomobject]@{
                        Key = $_.Name
                        Link = [string]$_.Value.link
                    }
                }
            }
        )

        $iconCachePath = Join-Path $env:LOCALAPPDATA 'YTY\WindowManager\IconCache'
        New-Item -ItemType Directory -Path $iconCachePath -Force | Out-Null

        $iconCacheJob = Start-Job -ArgumentList (,$iconManifest), $iconCachePath -ScriptBlock {
            param($Manifest, $CachePath)

            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
            foreach ($item in $Manifest) {
                $safeName = ($item.Key -replace '[^A-Za-z0-9_.-]', '_') + '.png'
                $target = Join-Path $CachePath $safeName
                if (Test-Path -LiteralPath $target) {
                    continue
                }

                $temporary = $target + '.tmp'
                try {
                    $faviconUrl = "https://www.google.com/s2/favicons?sz=64&domain_url=$([uri]::EscapeDataString([string]$item.Link))"
                    Invoke-WebRequest -Uri $faviconUrl -OutFile $temporary -UseBasicParsing -TimeoutSec 6
                    if ((Test-Path -LiteralPath $temporary) -and (Get-Item -LiteralPath $temporary).Length -gt 0) {
                        Move-Item -LiteralPath $temporary -Destination $target -Force
                    }
                } catch {
                    Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
                }
            }
        }
    } catch {
        # Icon caching is an optional performance optimization and must never block startup.
    }

    $shell = if (Get-Command pwsh.exe -ErrorAction SilentlyContinue) { 'pwsh.exe' } else { 'powershell.exe' }

    Push-Location $projectRoot
    try {
        & $shell -NoProfile -ExecutionPolicy Bypass -File '.\Compile.ps1' -Run
        if ($LASTEXITCODE -ne 0) {
            throw "WindowManager завершился с кодом $LASTEXITCODE."
        }
    }
    finally {
        Pop-Location
    }
}
finally {
    if ($iconCacheJob) {
        Stop-Job -Job $iconCacheJob -ErrorAction SilentlyContinue
        Remove-Job -Job $iconCacheJob -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
