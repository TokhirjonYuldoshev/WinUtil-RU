function Initialize-WinUtilRussianLocalization {
    <#
    .SYNOPSIS
        Initializes the optional Russian display layer for WinUtil.

    .DESCRIPTION
        Internal control names, configuration keys, category IDs, commands, registry values,
        package identifiers and application names stay unchanged. Only presentation text is
        translated. The chosen language is persisted per user and applied at startup.
    #>

    $sync.preferences.language = 'ru-RU'
    try {
        $savedLanguage = (Get-ItemProperty -Path 'HKCU:\Software\YTY\WindowManager' -Name Language -ErrorAction Stop).Language
        if ($savedLanguage -in @('ru-RU', 'en-US')) {
            $sync.preferences.language = $savedLanguage
        }
    } catch {
        # Russian is the default; reading a missing preference changes nothing.
    }

    $sync.WinUtilRussianExactTranslations = @{}
    $sync.WinUtilRussianNormalizedTranslations = @{}
    $sync.WinUtilRussianPhraseTranslations = [ordered]@{}

    $russianLocale = $sync.configs.localization_ru
    if ($null -eq $russianLocale) {
        Write-Warning 'Russian locale data is unavailable; English display text will be used as fallback.'
    } else {
        foreach ($property in @($russianLocale.Exact.PSObject.Properties)) {
            $sync.WinUtilRussianExactTranslations[[string]$property.Name] = [string]$property.Value
            $normalized = ([string]$property.Name -replace '\s+', ' ').Trim()
            $sync.WinUtilRussianNormalizedTranslations[$normalized] = [string]$property.Value
        }

        foreach ($entry in @($russianLocale.Phrases)) {
            if (
                $null -ne $entry -and
                -not [string]::IsNullOrWhiteSpace([string]$entry.Source)
            ) {
                $sync.WinUtilRussianPhraseTranslations[[string]$entry.Source] = [string]$entry.Target
            }
        }
    }

    function script:Convert-WinUtilRussianText {
        param([AllowNull()][object]$Value)

        if ($null -eq $Value -or $Value -isnot [string]) {
            return $Value
        }

        $text = [string]$Value
        if ([string]::IsNullOrWhiteSpace($text) -or $text.StartsWith('{')) {
            return $text
        }

        if ($sync.preferences.language -ne 'ru-RU') {
            return $text
        }

        $trimmed = $text.Trim()
        if ($sync.WinUtilRussianExactTranslations.ContainsKey($trimmed)) {
            $translated = $sync.WinUtilRussianExactTranslations[$trimmed]
            $prefixLength = $text.Length - $text.TrimStart().Length
            $suffixLength = $text.Length - $text.TrimEnd().Length
            return (' ' * $prefixLength) + $translated + (' ' * $suffixLength)
        }

        $normalized = ($trimmed -replace '\s+', ' ').Trim()
        if ($sync.WinUtilRussianNormalizedTranslations.ContainsKey($normalized)) {
            return $sync.WinUtilRussianNormalizedTranslations[$normalized]
        }

        if ($trimmed -match '^Selected Apps:\s*(\d+)$') {
            return "Выбрано приложений: $($Matches[1])"
        }

        if ($trimmed -match '^Install or Upgrade\s+(.+)$') {
            return "Установить или обновить $($Matches[1])"
        }

        if ($trimmed -match '^Uninstall\s+(.+)$') {
            return "Удалить $($Matches[1])"
        }

        $websitePrefix = "Open the application's website in your default browser"
        if ($trimmed.StartsWith($websitePrefix, [StringComparison]::OrdinalIgnoreCase)) {
            $website = $trimmed.Substring($websitePrefix.Length).Trim()
            if ([string]::IsNullOrWhiteSpace($website)) {
                return 'Открыть сайт приложения в браузере'
            }
            return "Открыть сайт приложения в браузере$([Environment]::NewLine)$website"
        }

        if ($trimmed -match '^Installing Chocolatey packages\s+\((\d+)/(\d+)\)$') {
            return "Установка пакетов Chocolatey ($($Matches[1])/$($Matches[2]))"
        }
        if ($trimmed -match '^Installed Chocolatey packages\s+\((\d+)/(\d+)\)$') {
            return "Пакеты Chocolatey установлены ($($Matches[1])/$($Matches[2]))"
        }
        if ($trimmed -match '^Uninstalling Chocolatey packages\s+\((\d+)/(\d+)\)$') {
            return "Удаление пакетов Chocolatey ($($Matches[1])/$($Matches[2]))"
        }
        if ($trimmed -match '^Uninstalled Chocolatey packages\s+\((\d+)/(\d+)\)$') {
            return "Пакеты Chocolatey удалены ($($Matches[1])/$($Matches[2]))"
        }
        if ($trimmed -match '^Installing\s+(.+)\s+\((\d+)/(\d+)\)$') {
            return "Установка $($Matches[1]) ($($Matches[2])/$($Matches[3]))"
        }
        if ($trimmed -match '^Installed\s+(.+)\s+\((\d+)/(\d+)\)$') {
            return "Установлено: $($Matches[1]) ($($Matches[2])/$($Matches[3]))"
        }
        if ($trimmed -match '^Uninstalling\s+(.+)\s+\((\d+)/(\d+)\)$') {
            return "Удаление $($Matches[1]) ($($Matches[2])/$($Matches[3]))"
        }
        if ($trimmed -match '^Uninstalled\s+(.+)\s+\((\d+)/(\d+)\)$') {
            return "Удалено: $($Matches[1]) ($($Matches[2])/$($Matches[3]))"
        }

        foreach ($entry in $sync.WinUtilRussianPhraseTranslations.GetEnumerator()) {
            if ($trimmed.EndsWith($entry.Key, [StringComparison]::OrdinalIgnoreCase)) {
                $base = $trimmed.Substring(0, $trimmed.Length - $entry.Key.Length)
                if ($sync.WinUtilRussianExactTranslations.ContainsKey($base)) {
                    $base = $sync.WinUtilRussianExactTranslations[$base]
                }
                return $base + $entry.Value
            }
        }

        return $text
    }

    if ($sync.preferences.language -eq 'ru-RU') {
        try {
            [xml]$localizedXaml = $script:inputXML

            foreach ($node in $localizedXaml.SelectNodes('//*')) {
                $elementName = $node.LocalName

                $toolTipAttribute = $node.Attributes.GetNamedItem('ToolTip')
                if ($null -ne $toolTipAttribute) {
                    $toolTipAttribute.Value = Convert-WinUtilRussianText $toolTipAttribute.Value
                }

                if ($elementName -in @('Label', 'Button', 'TextBlock', 'Run', 'MenuItem', 'ToolTip')) {
                    foreach ($attributeName in @('Content', 'Text', 'Header')) {
                        $attribute = $node.Attributes.GetNamedItem($attributeName)
                        if ($null -ne $attribute) {
                            $attribute.Value = Convert-WinUtilRussianText $attribute.Value
                        }
                    }
                }

                if ($elementName -eq 'ToggleButton') {
                    $nameAttribute = $node.Attributes.GetNamedItem('Name')
                    $contentAttribute = $node.Attributes.GetNamedItem('Content')
                    if (
                        $null -ne $nameAttribute -and
                        $nameAttribute.Value -like 'WPFSearchChip*' -and
                        $null -ne $contentAttribute
                    ) {
                        $contentAttribute.Value = Convert-WinUtilRussianText $contentAttribute.Value
                    }
                }

                if ($elementName -in @('TextBlock', 'Run')) {
                    foreach ($child in @($node.ChildNodes)) {
                        if (
                            $child.NodeType -eq [System.Xml.XmlNodeType]::Text -and
                            -not [string]::IsNullOrWhiteSpace($child.Value)
                        ) {
                            $child.Value = Convert-WinUtilRussianText $child.Value
                        }
                    }
                }
            }

            # The visible navigation captions are split into Underline + trailing text in XAML.
            # Replace only their presentation TextBlock; the hidden TabItem headers stay English.
            $navCaptions = @{}
            foreach ($entry in @($russianLocale.Navigation.PSObject.Properties)) {
                $navCaptions[[string]$entry.Name] = [string]$entry.Value
            }
            foreach ($navName in $navCaptions.Keys) {
                $navNode = $localizedXaml.SelectSingleNode("//*[@Name='$navName']")
                if ($null -eq $navNode) {
                    continue
                }

                $textBlock = $navNode.SelectSingleNode(".//*[local-name()='TextBlock']")
                if ($null -eq $textBlock) {
                    continue
                }

                while ($textBlock.HasChildNodes) {
                    $textBlock.RemoveChild($textBlock.FirstChild) | Out-Null
                }
                $textBlock.AppendChild($localizedXaml.CreateTextNode($navCaptions[$navName])) | Out-Null
            }

            $win11StepHeaders = @{}
            foreach ($entry in @($russianLocale.Win11StepHeaders.PSObject.Properties)) {
                $win11StepHeaders[[string]$entry.Name] = [string]$entry.Value
            }
            foreach ($stepName in $win11StepHeaders.Keys) {
                $stepNode = $localizedXaml.SelectSingleNode("//*[@Name='$stepName']")
                if ($null -ne $stepNode) {
                    $headerAttribute = $stepNode.Attributes.GetNamedItem('Header')
                    if ($null -ne $headerAttribute) {
                        $headerAttribute.Value = $win11StepHeaders[$stepName]
                    }
                }
            }

            # The ISO workflow compares these English TextBox values with fixed sentinels.
            # Show Russian text above the untouched controls only while each sentinel is present.
            foreach ($placeholder in @(
                @{ Name = 'WPFWin11ISOPath'; GridPosition = 'Grid.Column="0"'; Margin = '7,0,14,0'; Alignment = 'Center'; Source = 'No ISO selected...' },
                @{ Name = 'WPFWin11ISOStatusLog'; GridPosition = 'Grid.Row="1"'; Margin = '7,7,18,7'; Alignment = 'Stretch'; Source = 'Ready. Please select a Windows 11 ISO to begin.' }
            )) {
                $control = $localizedXaml.SelectSingleNode("//*[@Name='$($placeholder.Name)']")
                if ($null -eq $control) {
                    continue
                }

                $translatedPlaceholder = [System.Security.SecurityElement]::Escape(
                    (Convert-WinUtilRussianText $placeholder.Source)
                )
                $fragment = $localizedXaml.CreateDocumentFragment()
                $fragment.InnerXml = @"
<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
           $($placeholder.GridPosition) Margin="$($placeholder.Margin)"
           VerticalAlignment="$($placeholder.Alignment)" TextWrapping="Wrap"
           IsHitTestVisible="False" Background="{DynamicResource MainBackgroundColor}"
           Foreground="{DynamicResource MainForegroundColor}" Text="$translatedPlaceholder">
  <TextBlock.Style>
    <Style TargetType="TextBlock">
      <Setter Property="Visibility" Value="Collapsed"/>
      <Style.Triggers>
        <DataTrigger Binding="{Binding Text, ElementName=$($placeholder.Name)}" Value="$($placeholder.Source)">
          <Setter Property="Visibility" Value="Visible"/>
        </DataTrigger>
      </Style.Triggers>
    </Style>
  </TextBlock.Style>
</TextBlock>
"@
                $control.ParentNode.AppendChild($fragment) | Out-Null
            }

            $script:inputXML = $localizedXaml.OuterXml
        } catch {
            Write-Warning "Russian localization could not process the XAML: $($_.Exception.Message)"
        }
    }

    try {
        $culture = [System.Globalization.CultureInfo]::GetCultureInfo($sync.preferences.language)
        [System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture
    } catch {
        # Text localization remains available even if culture setup is unavailable.
    }
}
