$ErrorActionPreference = 'Stop'

$previousRestartCapability = $env:WINDOWMANAGER_LAUNCHER_RESTART
$env:WINDOWMANAGER_LAUNCHER_RESTART = '1'

$requestedBranch = if ($env:WINUTIL_RU_BRANCH) { $env:WINUTIL_RU_BRANCH } else { $env:WINDOWMANAGER_BRANCH }
$branch = if ($requestedBranch -in @('russian', 'russian-dev')) { $requestedBranch } else { 'russian' }
$repoZip = "https://github.com/TokhirjonYuldoshev/WindowManager/archive/refs/heads/$branch.zip"
$tempRoot = Join-Path $env:TEMP ("WindowManager-$branch-" + [guid]::NewGuid().ToString('N'))
$zipPath = Join-Path $tempRoot "$branch.zip"
$extractPath = Join-Path $tempRoot 'src'

try {
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $extractPath -Force | Out-Null

    # GitHub requires modern TLS. Windows PowerShell 5.1 may otherwise fail with
    # "The underlying connection was closed" on older Windows/.NET defaults.
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    Write-Host 'Загрузка WinUtil RU...' -ForegroundColor Cyan
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            Write-Host "Скачивание архива GitHub (попытка $attempt/3)..." -ForegroundColor DarkCyan
            Invoke-WebRequest -Uri $repoZip -OutFile $zipPath -UseBasicParsing -TimeoutSec 45
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

    Write-Host 'Распаковка архива...' -ForegroundColor Cyan
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
    $projectRoot = Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1 -ExpandProperty FullName
    if (-not $projectRoot -or -not (Test-Path (Join-Path $projectRoot 'Compile.ps1'))) {
        throw 'Не удалось найти Compile.ps1 в загруженном архиве.'
    }

    # Warm the favicon cache only in Auto mode. CacheOnly and Disabled never make
    # background favicon network requests.
    $iconCacheJob = $null
    $iconMode = 'Auto'
    try {
        $savedIconMode = (Get-ItemProperty -Path 'HKCU:\Software\YTY\WindowManager' -Name 'AppIconMode' -ErrorAction Stop).AppIconMode
        if ($savedIconMode -in @('Auto', 'CacheOnly', 'Disabled')) {
            $iconMode = [string]$savedIconMode
        }
    } catch {
        # Auto is the default.
    }

    if ($iconMode -eq 'Auto') {
        Write-Host 'Кэш иконок будет обновляться в фоне.' -ForegroundColor DarkGray
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
                        $age = (Get-Date) - (Get-Item -LiteralPath $target).LastWriteTime
                        if ($age.TotalDays -lt 30) {
                            continue
                        }
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
            # Icon caching is optional and must never block startup.
        }
    }

    $shell = if (Get-Command pwsh.exe -ErrorAction SilentlyContinue) { 'pwsh.exe' } else { 'powershell.exe' }

    Push-Location $projectRoot
    try {
        Write-Host "Preflight-проверка ($shell)..." -ForegroundColor Cyan
        & $shell -NoProfile -ExecutionPolicy Bypass -File '.\tools\Test-WinUtilRussianEdition.ps1' -Quiet
        if ($LASTEXITCODE -ne 0) {
            throw "Preflight-проверка WinUtil RU не пройдена."
        }

        Write-Host 'Сборка WinUtil RU...' -ForegroundColor Cyan
        & $shell -NoProfile -ExecutionPolicy Bypass -File '.\Compile.ps1'
        if ($LASTEXITCODE -ne 0) {
            throw "Не удалось собрать WinUtil RU. Код завершения: $LASTEXITCODE."
        }

        $runTarget = Join-Path $projectRoot 'winutil.ps1'

        if ($branch -eq 'russian') {
            $stableCacheRoot = Join-Path $env:LOCALAPPDATA 'YTY\WindowManager\Stable'
            $stableScript = Join-Path $stableCacheRoot 'winutil-RU.ps1'
            $stableManifestPath = Join-Path $stableCacheRoot 'release.json'

            New-Item -ItemType Directory -Path $stableCacheRoot -Force | Out-Null
            Copy-Item -LiteralPath $runTarget -Destination $stableScript -Force
            $legacyStableScript = Join-Path $stableCacheRoot 'WindowManager-RU.ps1'
            if (Test-Path -LiteralPath $legacyStableScript) {
                Remove-Item -LiteralPath $legacyStableScript -Force -ErrorAction SilentlyContinue
            }

            $localeInfo = Get-Content -LiteralPath (Join-Path $projectRoot 'config\localization_ru.json') -Raw -Encoding UTF8 | ConvertFrom-Json
            $stableHash = (Get-FileHash -LiteralPath $stableScript -Algorithm SHA256).Hash.ToLowerInvariant()
            $stableManifest = [ordered]@{
                Product = 'WinUtil RU'
                Channel = 'beta'
                Version = [string]$localeInfo.Meta.Version
                LocalizationVersion = [string]$localeInfo.Meta.LocalizationVersion
                SourceBranch = $branch
                Sha256 = $stableHash
                CachedAt = (Get-Date).ToString('o')
            }
            $stableManifest | ConvertTo-Json | Set-Content -LiteralPath $stableManifestPath -Encoding UTF8

            $runTarget = $stableScript
            Write-Host "Локальный кэш WinUtil RU обновлён: $($stableManifest.Version) Beta" -ForegroundColor DarkGreen
        }

        $restartRegistryPath = 'HKCU:\Software\YTY\WindowManager'
        do {
            if (Test-Path $restartRegistryPath) {
                Remove-ItemProperty -Path $restartRegistryPath -Name 'RestartRequested' -ErrorAction SilentlyContinue
            }

            Write-Host 'Запуск интерфейса WinUtil RU...' -ForegroundColor Green
            & $shell -NoProfile -ExecutionPolicy Bypass -File $runTarget
            if ($LASTEXITCODE -ne 0) {
                throw "WinUtil RU завершился с кодом $LASTEXITCODE."
            }

            $restartRequested = $false
            try {
                $restartRequested = [bool]((Get-ItemProperty -Path $restartRegistryPath -Name 'RestartRequested' -ErrorAction Stop).RestartRequested)
            } catch {
                $restartRequested = $false
            }
        } while ($restartRequested)

        Remove-ItemProperty -Path $restartRegistryPath -Name 'RestartRequested' -ErrorAction SilentlyContinue
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

    if ($null -eq $previousRestartCapability) {
        Remove-Item Env:\WINDOWMANAGER_LAUNCHER_RESTART -ErrorAction SilentlyContinue
    } else {
        $env:WINDOWMANAGER_LAUNCHER_RESTART = $previousRestartCapability
    }
}
