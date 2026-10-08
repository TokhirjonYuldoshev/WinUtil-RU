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

# Load only display functions and the actual theme inputs for layout measurement.
foreach ($name in @('Invoke-WinutilThemeChange', 'Invoke-WinUtilFontScaling', 'Invoke-WinUtilAssets')) {
    $definition = @($ast.EndBlock.Statements | Where-Object {
        $_ -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $_.Name -eq $name
    })
    if ($definition.Count -ne 1) { throw "Missing display function: $name." }
    . ([scriptblock]::Create($definition[0].Extent.Text))
}
$themeAssignment = @($ast.EndBlock.Statements | Where-Object {
    $_ -is [System.Management.Automation.Language.AssignmentStatementAst] -and
    $_.Left.Extent.Text -eq '$sync.configs.themes'
})
if ($themeAssignment.Count -ne 1) { throw 'Missing compiled theme inputs.' }

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
    Write-Host "WPF bundled icons PASSED: $testLanguage ($(@($sync.configs.application_icons.Icons.PSObject.Properties).Count) images, no network)"
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
        $sync.Form = $window
        . ([scriptblock]::Create($themeAssignment[0].Extent.Text))
        [void]$window.FindName('NavLogoPanel').Children.Add((Invoke-WinUtilAssets -Type logo -Size 25))
        # An unshown Window does not consistently arrange its content after resizing.
        # Measure the real header independently, retaining the actual window resources.
        $header = $window.FindName('NavDockPanel').Parent
        [void]$window.Content.Children.Remove($header)
        # Reparenting resumes layout for the subtree removed from the unshown Window.
        $root = New-Object Windows.Controls.Border
        $root.Resources.MergedDictionaries.Add($window.Resources)
        $root.Child = $header
        foreach ($theme in @('Dark', 'Light')) {
            Invoke-WinutilThemeChange -theme $theme
            foreach ($scale in @(0.75, 1.0, 1.5, 2.0)) {
                Invoke-WinUtilFontScaling -ScaleFactor $scale
                # Process deferred resource invalidations as a running WPF dispatcher would.
                [void]$root.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)
                foreach ($width in @(800, 1280, 1920)) {
                    $root.Width = $width
                    $root.Measure([Windows.Size]::new($width, [double]::PositiveInfinity))
                    $root.Arrange([Windows.Rect]::new(0, 0, $width, $root.DesiredSize.Height))
                    $root.UpdateLayout()
                    foreach ($name in @('WPFTab1BT', 'WPFTab2BT', 'WPFTab3BT', 'WPFTab4BT', 'WPFTab5BT')) {
                        $button = $window.FindName($name)
                        $caption = $button.Content
                        $text = [Windows.Media.FormattedText]::new($caption.Text,
                            [Globalization.CultureInfo]::InvariantCulture, [Windows.FlowDirection]::LeftToRight,
                            [Windows.Media.Typeface]::new($caption.FontFamily, $caption.FontStyle,
                                $caption.FontWeight, $caption.FontStretch), $caption.FontSize,
                            [Windows.Media.Brushes]::Black, 1.0)
                        $origin = $caption.TranslatePoint([Windows.Point]::new(0, 0), $button)
                        if ($caption.ActualWidth + 1 -lt $text.WidthIncludingTrailingWhitespace -or
                            $origin.X -lt -1 -or $origin.X + $text.WidthIncludingTrailingWhitespace -gt $button.ActualWidth + 1 -or
                            $caption.ActualHeight + 1 -lt $text.Height) {
                            throw "Clipped navigation caption: $name ($testLanguage/$theme/$scale/$width); root=$($root.GetType().Name)/$($root.Visibility)/$($root.DesiredSize), nav=$($window.FindName('NavDockPanel').Visibility), buttonVisibility=$($button.Visibility); text=$($text.WidthIncludingTrailingWhitespace)x$($text.Height), actual=$($caption.ActualWidth)x$($caption.ActualHeight), button=$($button.ActualWidth), origin=$($origin.X)."
                        }
                        $position = $button.TranslatePoint([Windows.Point]::new(0, 0), $root)
                        if ($position.X -lt -1 -or $position.X + $button.ActualWidth -gt $width + 1) {
                            throw "Navigation button exceeds the window: $name ($testLanguage/$theme/$scale/$width)."
                        }
                    }
                    # At ordinary widths/scales the compact search must share the tab row.
                    $firstTab = $window.FindName('WPFTab1BT')
                    $search = $window.FindName('SearchBar')
                    if ($width -ge 1280 -and $scale -le 1.0) {
                        $tabPosition = $firstTab.TranslatePoint([Windows.Point]::new(0, 0), $root)
                        $searchPosition = $search.TranslatePoint([Windows.Point]::new(0, 0), $root)
                        if ([math]::Abs(($tabPosition.Y + $firstTab.ActualHeight / 2) -
                                ($searchPosition.Y + $search.ActualHeight / 2)) -gt 1) {
                            throw "Search must share the navigation row ($testLanguage/$theme/$scale/$width)."
                        }
                    }
                    if ($search.ActualWidth -lt 100 -or $search.ActualWidth -gt 360) {
                        throw "Compact search width is outside its usable range ($testLanguage/$theme/$scale/$width)."
                    }
                    $close = $window.FindName('WPFCloseButton')
                    $closePosition = $close.TranslatePoint([Windows.Point]::new(0, 0), $root)
                    if ([math]::Abs($width - ($closePosition.X + $close.ActualWidth) - 5) -gt 1) {
                        throw "Window controls must remain at the right edge ($testLanguage/$theme/$scale/$width)."
                    }
                    foreach ($name in @('SearchBar', 'ThemeButton', 'FontScalingButton', 'SettingsButton',
                            'WPFMinimizeButton', 'WPFMaximizeButton', 'WPFCloseButton')) {
                        $control = $window.FindName($name)
                        $position = $control.TranslatePoint([Windows.Point]::new(0, 0), $root)
                        if ($control.ActualWidth -le 0 -or $position.X -lt -1 -or
                            $position.X + $control.ActualWidth -gt $width + 1) {
                            throw "Top bar control exceeds the window: $name ($testLanguage/$theme/$scale/$width); x=$($position.X), control=$($control.ActualWidth), root=$($root.ActualWidth), row=$($control.Parent.Parent.ActualWidth), buttons=$($control.Parent.ActualWidth)/$($control.Parent.DesiredSize.Width)."
                        }
                    }
                }
            }
        }
        Write-Host "WPF navigation layout PASSED: $testLanguage (Dark/Light, 75-200%, 800/1280/1920 px)"
        Write-Host "WPF XAML load PASSED: $testLanguage"
    }
    finally {
        $reader.Close()
        if ($null -ne $window) { $window.Close() }
    }
}
