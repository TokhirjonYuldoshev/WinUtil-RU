[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$CompiledScriptPath
)

$ErrorActionPreference = 'Stop'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'WPF XAML validation requires Windows.'
}
if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    throw 'Run WPF XAML validation with powershell.exe -STA.'
}
Add-Type -AssemblyName PresentationFramework

# Extract only the embedded display inputs. Never execute the utility's startup,
# event handlers, package managers or system operations during this check.
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path -LiteralPath $CompiledScriptPath).Path, [ref]$tokens, [ref]$parseErrors
)
if ($parseErrors.Count -gt 0) {
    throw ($parseErrors.Message -join [Environment]::NewLine)
}
$initializer = @($ast.EndBlock.Statements | Where-Object {
    $_ -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
    $_.Name -eq 'Initialize-WinUtilRussianLocalization'
})
$localeAssignment = @($ast.EndBlock.Statements | Where-Object {
    $_ -is [System.Management.Automation.Language.AssignmentStatementAst] -and
    $_.Left.Extent.Text -eq '$sync.configs.localization_ru'
})
$xamlAssignment = @($ast.EndBlock.Statements | Where-Object {
    $_ -is [System.Management.Automation.Language.AssignmentStatementAst] -and
    $_.Left.Extent.Text -eq '$inputXML' -and
    $_.Right.Extent.Text.TrimStart().StartsWith("@'")
})
if ($initializer.Count -ne 1 -or $localeAssignment.Count -ne 1 -or $xamlAssignment.Count -ne 1) {
    throw 'The compiled script must contain exactly one localization function, locale and XAML input.'
}
. ([scriptblock]::Create($initializer[0].Extent.Text))
$iconResolver = @($ast.EndBlock.Statements | Where-Object {
    $_ -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
    $_.Name -eq 'Get-WinUtilAppIconSource'
})
$iconAssignment = @($ast.EndBlock.Statements | Where-Object {
    $_ -is [System.Management.Automation.Language.AssignmentStatementAst] -and
    $_.Left.Extent.Text -eq '$sync.configs.application_icons'
})
if ($iconResolver.Count -ne 1 -or $iconAssignment.Count -ne 1) {
    throw 'The compiled script must contain the offline app icon resolver and catalog.'
}
. ([scriptblock]::Create($iconResolver[0].Extent.Text))

# Supply a saved-language result locally without reading or writing user settings.
function Get-ItemProperty {
    param($Path, $Name, $ErrorAction)
    [pscustomobject]@{ Language = $testLanguage }
}

foreach ($testLanguage in @('ru-RU', 'en-US', 'ru-RU')) {
    $script:sync = @{ preferences = @{}; configs = @{} }
    . ([scriptblock]::Create($localeAssignment[0].Extent.Text))
    . ([scriptblock]::Create($xamlAssignment[0].Extent.Text))
    $script:inputXML = $inputXML
    Initialize-WinUtilRussianLocalization
    . ([scriptblock]::Create($iconAssignment[0].Extent.Text))
    $sync.WinUtilAppIconMode = 'CacheOnly'
    foreach ($entry in $sync.configs.application_icons.Icons.PSObject.Properties) {
        $bitmap = Get-WinUtilAppIconSource -AppKey ('WPFInstall' + $entry.Name) -Link 'https://example.invalid/'
        if ($bitmap -isnot [Windows.Media.Imaging.BitmapImage] -or -not $bitmap.IsFrozen -or
            $bitmap.PixelWidth -le 0 -or $bitmap.PixelHeight -le 0) {
            throw "Bundled icon failed to decode: $($entry.Name) ($testLanguage)."
        }
    }
    Write-Host "WPF bundled icons PASSED: $testLanguage (13 images, no network)"
    if ($sync.preferences.language -ne $testLanguage) {
        throw "Language setup failed for $testLanguage."
    }

    [xml]$xaml = $script:inputXML
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $window = $null
    try {
        $window = [Windows.Markup.XamlReader]::Load($reader)
        foreach ($name in @('WPFTab1BT', 'WPFTab2BT', 'WPFTab3BT', 'WPFTab4BT', 'WPFTab5BT',
                'RussianLanguageMenuItem', 'EnglishLanguageMenuItem', 'WPFWin11ISOPath', 'WPFWin11ISOStatusLog')) {
            if ($null -eq $window.FindName($name)) {
                throw "Missing runtime control: $name ($testLanguage)."
            }
        }
        if ($window.FindName('WPFWin11ISOPath').Text -ne 'No ISO selected...' -or
            $window.FindName('WPFWin11ISOStatusLog').Text -ne 'Ready. Please select a Windows 11 ISO to begin.') {
            throw "Original ISO sentinel values changed ($testLanguage)."
        }
        Write-Host "WPF XAML load PASSED: $testLanguage"
    }
    finally {
        $reader.Close()
        if ($null -ne $window) { $window.Close() }
    }
}
