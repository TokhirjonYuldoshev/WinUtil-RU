function Publish-WinUtilStableCache {
    param(
        [Parameter(Mandatory)][string]$CompiledPath,
        [Parameter(Mandatory)][string]$CacheRoot,
        [Parameter(Mandatory)][string]$SourceCommit,
        [Parameter(Mandatory)][object]$Locale
    )
    if ($SourceCommit -notmatch '^[0-9a-f]{40}$') { throw 'A full source commit is required for the cache.' }
    $hash = (Get-FileHash -LiteralPath $CompiledPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $artifact = "versions/$SourceCommit-$hash/winutil-RU.ps1"
    $target = Join-Path $CacheRoot $artifact
    $directory = Split-Path -Parent $target
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    if (-not (Test-Path -LiteralPath $target)) {
        # Publish without overwriting an existing immutable artifact.
        $stagedScript = Join-Path $directory ("script-" + [guid]::NewGuid().ToString('N') + '.tmp')
        try {
            Copy-Item -LiteralPath $CompiledPath -Destination $stagedScript
            [IO.File]::Move($stagedScript, $target)
        } catch {
            if (-not (Test-Path -LiteralPath $target)) { throw }
        } finally {
            Remove-Item -LiteralPath $stagedScript -Force -ErrorAction SilentlyContinue
        }
    }
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $hash) {
        throw 'The cached artifact does not match the validated build.'
    }
    $manifest = [ordered]@{
        Product = 'WinUtil RU'; Channel = 'stable'
        Version = [string]$Locale.Meta.Version
        LocalizationVersion = [string]$Locale.Meta.LocalizationVersion
        SourceBranch = 'russian'; SourceCommit = $SourceCommit
        Artifact = $artifact; Sha256 = $hash; CachedAt = (Get-Date).ToString('o')
    }
    $pointer = Join-Path $CacheRoot 'release.json'
    $previous = Join-Path $CacheRoot 'release.previous.json'
    $temporary = Join-Path $CacheRoot ("manifest-" + [guid]::NewGuid().ToString('N') + '.tmp')
    $previousTemporary = $temporary + '.previous'
    try {
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        [IO.File]::WriteAllText($temporary, ($manifest | ConvertTo-Json), $utf8)
        # Back up only the exact pointer whose artifact was verified. A corrupt
        # active pointer must never replace an older, still valid recovery build.
        $verifiedPointer = Get-WinUtilVerifiedCachePointer -CacheRoot $CacheRoot -PointerPath $pointer
        if ($null -ne $verifiedPointer) {
            [IO.File]::WriteAllText($previousTemporary, $verifiedPointer, $utf8)
            if (Test-Path -LiteralPath $previous) { [IO.File]::Replace($previousTemporary, $previous, [System.Management.Automation.Language.NullString]::Value) }
            else { [IO.File]::Move($previousTemporary, $previous) }
        }
        if (Test-Path -LiteralPath $pointer) { [IO.File]::Replace($temporary, $pointer, [System.Management.Automation.Language.NullString]::Value) }
        else { [IO.File]::Move($temporary, $pointer) }
    } finally {
        Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $previousTemporary -Force -ErrorAction SilentlyContinue
    }
}

function Get-WinUtilVerifiedCachePointer {
    param([string]$CacheRoot, [string]$PointerPath)
    try {
        if (-not (Test-Path -LiteralPath $PointerPath -PathType Leaf)) { return $null }
        $text = Get-Content -LiteralPath $PointerPath -Raw -Encoding UTF8
        $manifest = $text | ConvertFrom-Json
        $artifact = [string]$manifest.Artifact
        if ([string]::IsNullOrWhiteSpace($artifact)) { $artifact = 'winutil-RU.ps1' }
        if ($artifact -ne 'winutil-RU.ps1' -and $artifact -notmatch '^versions/[0-9a-f]{40}-[0-9a-f]{64}/winutil-RU\.ps1$') { return $null }
        if ([string]$manifest.Sha256 -notmatch '^[0-9a-fA-F]{64}$') { return $null }
        $path = Join-Path $CacheRoot $artifact
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne [string]$manifest.Sha256) { return $null }
        return $text
    } catch { return $null }
}

function Test-WinUtilLauncherAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    try {
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } finally { $identity.Dispose() }
}

function Invoke-WinUtilLauncherApplication {
    param([Parameter(Mandatory)][string]$Shell, [Parameter(Mandatory)][string]$ScriptPath)
    if (Test-WinUtilLauncherAdministrator) {
        & $Shell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath | Out-Host
        return [int]$LASTEXITCODE
    }
    # Elevate before executing the temporary script, and wait for its process
    # tree. The compiled GUI's detached self-elevation cannot outlive cleanup.
    $literalPath = $ScriptPath.Replace("'", "''")
    $literalShell = [IO.Path]::GetFileName($Shell).Replace("'", "''")
    # Keep -File ownership/exit semantics inside the elevated host.
    $command = "`$env:WINDOWMANAGER_LAUNCHER_RESTART = '1'; try { & (Join-Path `$PSHOME '$literalShell') -NoProfile -ExecutionPolicy Bypass -File '$literalPath'; exit `$LASTEXITCODE } catch { Write-Error `$_ -ErrorAction Continue; exit 1 }"
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    $process = Start-Process -FilePath $Shell -Verb RunAs -ArgumentList @('-NoProfile', '-STA', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $encoded) -Wait -PassThru -ErrorAction Stop
    if ($null -eq $process.ExitCode) { throw 'The elevated application did not return an exit code.' }
    return [int]$process.ExitCode
}

$ErrorActionPreference = 'Stop'

$previousRestartCapability = $env:WINDOWMANAGER_LAUNCHER_RESTART
$env:WINDOWMANAGER_LAUNCHER_RESTART = '1'

$requestedBranch = if ($env:WINUTIL_RU_BRANCH) { $env:WINUTIL_RU_BRANCH } else { $env:WINDOWMANAGER_BRANCH }
$branch = if ($requestedBranch -in @('russian', 'russian-dev')) { $requestedBranch } else { 'russian' }
$tempRoot = Join-Path $env:TEMP ("WindowManager-$branch-" + [guid]::NewGuid().ToString('N'))
$zipPath = Join-Path $tempRoot "$branch.zip"
$extractPath = Join-Path $tempRoot 'src'

try {
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $extractPath -Force | Out-Null

    # GitHub requires modern TLS. Windows PowerShell 5.1 may otherwise fail with
    # "The underlying connection was closed" on older Windows/.NET defaults.
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $sourceCommit = $env:WINUTIL_RU_COMMIT
    if ([string]::IsNullOrWhiteSpace($sourceCommit)) {
        $encodedBranch = [Uri]::EscapeDataString($branch)
        $branchInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/TokhirjonYuldoshev/WinUtil-RU/branches/$encodedBranch" -Headers @{ 'User-Agent' = 'WinUtil-RU' } -TimeoutSec 15
        $sourceCommit = [string]$branchInfo.commit.sha
    }
    if ($sourceCommit -notmatch '^[0-9a-fA-F]{40}$') { throw 'GitHub did not return a valid source commit.' }
    $sourceCommit = $sourceCommit.ToLowerInvariant()
    $repoZip = "https://github.com/TokhirjonYuldoshev/WinUtil-RU/archive/$sourceCommit.zip"

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
        Write-Host 'Сборка WinUtil RU...' -ForegroundColor Cyan
        & $shell -NoProfile -ExecutionPolicy Bypass -File '.\Compile.ps1'
        if ($LASTEXITCODE -ne 0) {
            throw "Не удалось собрать WinUtil RU. Код завершения: $LASTEXITCODE."
        }

        $runTarget = Join-Path $projectRoot 'winutil.ps1'

        $tokens = $null
        $parseErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($runTarget, [ref]$tokens, [ref]$parseErrors) | Out-Null
        if ($parseErrors.Count -gt 0) { throw ($parseErrors.Message -join [Environment]::NewLine) }
        # ZIP launch checks generated syntax and WPF; Git parity is a CI/release check.
        & powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File (Join-Path $projectRoot 'tools/Test-WinUtilRussianXaml.ps1') -CompiledScriptPath $runTarget
        if ($LASTEXITCODE -ne 0) { throw 'The Russian interface failed WPF validation.' }

        $restartRegistryPath = 'HKCU:\Software\YTY\WindowManager'
        do {
            if (Test-Path $restartRegistryPath) {
                Remove-ItemProperty -Path $restartRegistryPath -Name 'RestartRequested' -ErrorAction SilentlyContinue
            }

            Write-Host 'Запуск интерфейса WinUtil RU...' -ForegroundColor Green
            $appExitCode = Invoke-WinUtilLauncherApplication -Shell $shell -ScriptPath $runTarget
            if ($appExitCode -ne 0) {
                throw "WinUtil RU завершился с кодом $appExitCode."
            }

            $restartRequested = $false
            try {
                $restartRequested = [bool]((Get-ItemProperty -Path $restartRegistryPath -Name 'RestartRequested' -ErrorAction Stop).RestartRequested)
            } catch {
                $restartRequested = $false
            }
        } while ($restartRequested)

        Remove-ItemProperty -Path $restartRegistryPath -Name 'RestartRequested' -ErrorAction SilentlyContinue

        # The old build remains available until the new validated build exits successfully.
        if ($branch -eq 'russian') {
            try {
                $locale = Get-Content -LiteralPath (Join-Path $projectRoot 'config/localization_ru.json') -Raw -Encoding UTF8 | ConvertFrom-Json
                $cacheRoot = Join-Path $env:LOCALAPPDATA 'YTY\WindowManager\Stable'
                Publish-WinUtilStableCache -CompiledPath $runTarget -CacheRoot $cacheRoot -SourceCommit $sourceCommit -Locale $locale
                Write-Host "Локальный кэш WinUtil RU обновлён: $($locale.Meta.Version)" -ForegroundColor DarkGreen
            } catch {
                # The application already completed successfully. A cache write
                # failure must not make bootstrap launch an older application.
                Write-Warning "WinUtil RU завершил работу, но кэш не обновлён: $($_.Exception.Message)"
            }
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

    if ($null -eq $previousRestartCapability) {
        Remove-Item Env:\WINDOWMANAGER_LAUNCHER_RESTART -ErrorAction SilentlyContinue
    } else {
        $env:WINDOWMANAGER_LAUNCHER_RESTART = $previousRestartCapability
    }
}
