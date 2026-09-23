param(
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$failures = @()

function Add-WinUtilValidationFailure {
    param([string]$Message)
    $script:failures += $Message
}

# Windows PowerShell 5.1 requires a UTF-8 BOM for source files that contain
# non-ASCII text. Without it, Russian strings are decoded as ANSI and can even
# turn into parser errors when multibyte sequences are misread.
$utf8BomRequired = @(
    'run-russian.ps1'
    'functions\private\Convert-WinUtilRussianRuntimeText.ps1'
    'functions\private\Get-WinUtilEntryToolTip.ps1'
    'functions\private\Initialize-WinUtilRussianLocalization.ps1'
    'functions\private\Set-WinUtilLanguagePreference.ps1'
    'functions\private\Start-WinUtilUserInterface.ps1'
    'tools\Test-WinUtilRussianEdition.ps1'
)

foreach ($relativePath in $utf8BomRequired) {
    $sourcePath = Join-Path $repoRoot $relativePath
    $bytes = [System.IO.File]::ReadAllBytes($sourcePath)
    $hasUtf8Bom = (
        $bytes.Length -ge 3 -and
        $bytes[0] -eq 0xEF -and
        $bytes[1] -eq 0xBB -and
        $bytes[2] -eq 0xBF
    )
    if (-not $hasUtf8Bom) {
        Add-WinUtilValidationFailure "$relativePath must be UTF-8 with BOM for Windows PowerShell 5.1."
    }
}

# Parse all executable PowerShell sources with the engine that is about to run them.
$powerShellFiles = @(
    Get-ChildItem -Path (Join-Path $repoRoot 'functions'), (Join-Path $repoRoot 'scripts') -Filter *.ps1 -Recurse -File
)
$powerShellFiles += @(
    Get-Item -LiteralPath (Join-Path $repoRoot 'Compile.ps1')
    Get-Item -LiteralPath (Join-Path $repoRoot 'run-russian.ps1')
)

foreach ($file in $powerShellFiles) {
    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $file.FullName,
        [ref]$tokens,
        [ref]$parseErrors
    )
    foreach ($parseError in @($parseErrors)) {
        Add-WinUtilValidationFailure "$($file.FullName):$($parseError.Extent.StartLineNumber) $($parseError.Message)"
    }
}

# Every config must be valid JSON.
foreach ($file in (Get-ChildItem -LiteralPath (Join-Path $repoRoot 'config') -Filter *.json -File)) {
    try {
        Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null
    } catch {
        Add-WinUtilValidationFailure "$($file.Name): invalid JSON - $($_.Exception.Message)"
    }
}

# XAML must be valid XML before WPF attempts to load it.
$xamlPath = Join-Path $repoRoot 'xaml\inputXML.xaml'
try {
    [xml]$xaml = Get-Content -LiteralPath $xamlPath -Raw -Encoding UTF8
} catch {
    Add-WinUtilValidationFailure "xaml/inputXML.xaml: invalid XML - $($_.Exception.Message)"
}

if ($null -ne $xaml) {
    $expectedCoreHeaders = @{
        WPFTab1 = 'Install'
        WPFTab2 = 'Tweaks'
        WPFTab3 = 'Config'
        WPFTab4 = 'Updates'
        WPFTab5 = 'Win11ISO'
        WPFTab6 = 'AppX'
    }

    foreach ($name in $expectedCoreHeaders.Keys) {
        $node = $xaml.SelectSingleNode("//*[local-name()='TabItem'][@Name='$name']")
        if ($null -eq $node) {
            Add-WinUtilValidationFailure "Missing core TabItem $name"
            continue
        }
        if ($node.GetAttribute('Header') -ne $expectedCoreHeaders[$name]) {
            Add-WinUtilValidationFailure "$name header must remain '$($expectedCoreHeaders[$name])' for internal routing."
        }
    }

    foreach ($languageControl in @('RussianLanguageMenuItem', 'EnglishLanguageMenuItem')) {
        if ($null -eq $xaml.SelectSingleNode("//*[@Name='$languageControl']")) {
            Add-WinUtilValidationFailure "Missing language control $languageControl"
        }
    }

    foreach ($iconControl in @('AppIconsMenuItem', 'AppIconsAutoMenuItem', 'AppIconsCacheOnlyMenuItem', 'AppIconsDisabledMenuItem', 'ClearIconCacheMenuItem')) {
        if ($null -eq $xaml.SelectSingleNode("//*[@Name='$iconControl']")) {
            Add-WinUtilValidationFailure "Missing icon settings control $iconControl"
        }
    }
}

# Russian application descriptions must track the source catalog one-for-one.
try {
    $applications = Get-Content -LiteralPath (Join-Path $repoRoot 'config\applications.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $applicationsRu = Get-Content -LiteralPath (Join-Path $repoRoot 'config\applications_ru.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $sourceKeys = @($applications.PSObject.Properties.Name | Sort-Object)
    $russianKeys = @($applicationsRu.PSObject.Properties.Name | Sort-Object)
    $keyDiff = @(Compare-Object $sourceKeys $russianKeys)
    if ($keyDiff.Count -gt 0) {
        Add-WinUtilValidationFailure "applications_ru.json does not match applications.json: $($keyDiff | Out-String)"
    }

    $blankDescriptions = @(
        $applicationsRu.PSObject.Properties |
            Where-Object { [string]::IsNullOrWhiteSpace([string]$_.Value) } |
            ForEach-Object Name
    )
    if ($blankDescriptions.Count -gt 0) {
        Add-WinUtilValidationFailure "Blank Russian application descriptions: $($blankDescriptions -join ', ')"
    }
} catch {
    Add-WinUtilValidationFailure "Application catalog validation failed: $($_.Exception.Message)"
}

# Locale metadata and minimum coverage.
try {
    $locale = Get-Content -LiteralPath (Join-Path $repoRoot 'config\localization_ru.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($locale.Meta.Language -ne 'ru-RU') {
        Add-WinUtilValidationFailure "localization_ru.json Meta.Language must be ru-RU"
    }
    if (@($locale.Exact.PSObject.Properties).Count -lt 400) {
        Add-WinUtilValidationFailure "Russian exact translation coverage unexpectedly dropped below 400 entries."
    }
    if (@($locale.Phrases).Count -lt 10) {
        Add-WinUtilValidationFailure "Russian phrase translation coverage unexpectedly dropped below 10 entries."
    }

    $duplicateExactKeys = @(
        $locale.Exact.PSObject.Properties.Name |
            Group-Object { $_.ToLowerInvariant() } |
            Where-Object Count -gt 1 |
            ForEach-Object Name
    )
    if ($duplicateExactKeys.Count -gt 0) {
        Add-WinUtilValidationFailure "Case-insensitive duplicate Russian locale keys: $($duplicateExactKeys -join ', ')"
    }

    if ([string]$locale.Navigation.WPFTab5BT -ne 'Windows 11') {
        Add-WinUtilValidationFailure "Russian Windows 11 navigation caption must stay compact."
    }
} catch {
    Add-WinUtilValidationFailure "Russian locale validation failed: $($_.Exception.Message)"
}

# Guard the WPF Image regression that previously stopped all Install cards from rendering.
$installEntryPath = Join-Path $repoRoot 'functions\private\Initialize-InstallAppEntry.ps1'
$installEntrySource = Get-Content -LiteralPath $installEntryPath -Raw -Encoding UTF8
if ($installEntrySource -match 'Add_ImageOpened') {
    Add-WinUtilValidationFailure "Unsupported WPF Image Add_ImageOpened handler was reintroduced."
}
if ($installEntrySource -notmatch '\$safeIconName\s*=\s*\(\$catalogKey\s*-replace') {
    Add-WinUtilValidationFailure "Install icon cache is not keyed by the raw application catalog key."
}
if ($installEntrySource -notmatch '\$iconMode\s+-ne\s+''Disabled''') {
    Add-WinUtilValidationFailure "Install cards do not honor the Disabled icon mode."
}
if ($installEntrySource -notmatch '\$iconMode\s+-eq\s+''Auto''') {
    Add-WinUtilValidationFailure "Install cards do not honor the Auto icon mode."
}

if ($failures.Count -gt 0) {
    Write-Host ''
    Write-Host 'Проверка русской версии НЕ пройдена:' -ForegroundColor Red
    foreach ($failure in $failures) {
        Write-Host " - $failure" -ForegroundColor Red
    }
    exit 1
}

if (-not $Quiet) {
    Write-Host 'Preflight русской версии: OK' -ForegroundColor Green
}
exit 0
