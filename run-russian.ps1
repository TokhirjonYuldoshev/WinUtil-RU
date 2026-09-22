$ErrorActionPreference = 'Stop'

$repoZip = 'https://github.com/TokhirjonYuldoshev/WindowManager/archive/refs/heads/russian.zip'
$tempRoot = Join-Path $env:TEMP ('WindowManager-russian-' + [guid]::NewGuid().ToString('N'))
$zipPath = Join-Path $tempRoot 'russian.zip'
$extractPath = Join-Path $tempRoot 'src'

try {
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $extractPath -Force | Out-Null

    Write-Host 'Загрузка русской версии WindowManager...' -ForegroundColor Cyan
    Invoke-WebRequest -Uri $repoZip -OutFile $zipPath -UseBasicParsing

    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
    $projectRoot = Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1 -ExpandProperty FullName
    if (-not $projectRoot -or -not (Test-Path (Join-Path $projectRoot 'Compile.ps1'))) {
        throw 'Не удалось найти Compile.ps1 в загруженном архиве.'
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
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
