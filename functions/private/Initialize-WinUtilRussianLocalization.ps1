function Initialize-WinUtilRussianLocalization {
    <#
    .SYNOPSIS
        Initializes the optional Russian display layer for WinUtil.

    .DESCRIPTION
        Internal control names, configuration keys, category IDs, commands, registry values,
        package identifiers and application names stay unchanged. Only presentation text is
        translated. The selected language is stored per user and applied at startup.
    #>

    $language = 'ru-RU'
    try {
        $savedLanguage = (Get-ItemProperty -Path 'HKCU:\Software\YTY\WindowManager' -Name 'Language' -ErrorAction Stop).Language
        if ($savedLanguage -in @('ru-RU', 'en-US')) {
            $language = $savedLanguage
        }
    } catch {
        # Russian is the default for this branch.
    }
    $sync.preferences.language = $language

    $sync.WinUtilRussianExactTranslations = @{}
    $sync.WinUtilRussianPhraseTranslations = [ordered]@{}

    $russianLocale = $sync.configs.localization_ru
    if ($null -eq $russianLocale) {
        Write-Warning 'Russian locale data is unavailable; English display text will be used as fallback.'
    } else {
        foreach ($property in @($russianLocale.Exact.PSObject.Properties)) {
            $sync.WinUtilRussianExactTranslations[[string]$property.Name] = [string]$property.Value
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

        if ($trimmed -match '^Removing\s+(.+)\s+\((\d+)/(\d+)\)
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
) {
            return "Удаление $($Matches[1]) ($($Matches[2])/$($Matches[3]))"
        }
        if ($trimmed -match '^Removed\s+(.+)\s+\((\d+)/(\d+)\)
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
) {
            return "Удалено: $($Matches[1]) ($($Matches[2])/$($Matches[3]))"
        }
        if ($trimmed -match '^Applying\s+(.+)\s+\((\d+)/(\d+)\)
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
) {
            return "Применение $($Matches[1]) ($($Matches[2])/$($Matches[3]))"
        }
        if ($trimmed -match '^Undoing\s+(.+)\s+\((\d+)/(\d+)\)
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
) {
            return "Отмена $($Matches[1]) ($($Matches[2])/$($Matches[3]))"
        }
        if ($trimmed -match '^File size:\s*(.+)
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
) {
            return "Размер файла: $($Matches[1])"
        }
        if ($trimmed -match '^ISO saved to\s+(.+)
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
) {
            return "ISO сохранён: $($Matches[1])"
        }
        if ($trimmed -match '^Disk\s+(\d+)\s+is ready to boot from\.
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
) {
            return "Диск $($Matches[1]) готов к загрузке."
        }
        if ($trimmed -match '^Deleting files in\s+(.+?)\.\.\.\s+\((\d+)\s*/\s*(\d+)\)
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
) {
            return "Удаление файлов из $($Matches[1])... ($($Matches[2]) / $($Matches[3]))"
        }
        if ($trimmed -match '^Stopping\s+(.+)
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
) {
            $jobName = $Matches[1]
            if ($sync.WinUtilRussianExactTranslations.ContainsKey($jobName)) {
                $jobName = $sync.WinUtilRussianExactTranslations[$jobName]
            }
            return "Остановка: $jobName"
        }
        if ($trimmed -match '^(.+)\s+is still running
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
) {
            $jobName = $Matches[1]
            if ($sync.WinUtilRussianExactTranslations.ContainsKey($jobName)) {
                $jobName = $sync.WinUtilRussianExactTranslations[$jobName]
            }
            return "$jobName всё ещё выполняется"
        }
        if ($trimmed -match '^(.+)\s+finished with\s+(\d+)\s+error\(s\)
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
) {
            $jobName = $Matches[1]
            if ($sync.WinUtilRussianExactTranslations.ContainsKey($jobName)) {
                $jobName = $sync.WinUtilRussianExactTranslations[$jobName]
            }
            return "$jobName завершено с ошибками: $($Matches[2])"
        }
        if ($trimmed -match '^(.+)\s+finished with\s+(\d+)\s+warning\(s\)
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
) {
            $jobName = $Matches[1]
            if ($sync.WinUtilRussianExactTranslations.ContainsKey($jobName)) {
                $jobName = $sync.WinUtilRussianExactTranslations[$jobName]
            }
            return "$jobName завершено с предупреждениями: $($Matches[2])"
        }
        if ($trimmed -match '^(.+)\s+(finished|failed|could not start)
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
) {
            $jobName = $Matches[1]
            $state = $Matches[2]
            if ($sync.WinUtilRussianExactTranslations.ContainsKey($jobName)) {
                $jobName = $sync.WinUtilRussianExactTranslations[$jobName]
            }
            switch ($state) {
                'finished' { return "$jobName завершено" }
                'failed' { return "$jobName завершилось с ошибкой" }
                'could not start' { return "Не удалось запустить: $jobName" }
            }
        }
        if ($trimmed -match '^(.+)\s+\((\d+)/(\d+)\)
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
) {
            $base = $Matches[1]
            if ($sync.WinUtilRussianExactTranslations.ContainsKey($base)) {
                return "$($sync.WinUtilRussianExactTranslations[$base]) ($($Matches[2])/$($Matches[3]))"
            }
        }
        if ($trimmed -match '^(.+)\s+\((\d+)%\)
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
) {
            $base = $Matches[1]
            if ($sync.WinUtilRussianExactTranslations.ContainsKey($base)) {
                return "$($sync.WinUtilRussianExactTranslations[$base]) ($($Matches[2])%)"
            }
        }

        # Dynamic dialog bodies: translate the stable explanatory text while preserving
        # paths, package names, disk numbers and raw exception details.
        if ($trimmed -match '(?s)^(.+?) has not finished yet\.\s+Close the window and let it finish in the console\?') {
            $jobName = $Matches[1]
            if ($sync.WinUtilRussianExactTranslations.ContainsKey($jobName)) {
                $jobName = $sync.WinUtilRussianExactTranslations[$jobName]
            }
            return "$jobName ещё не завершено.`n`nЗакрыть окно и продолжить выполнение в консоли?`n`nWindowManager завершится автоматически после окончания операции. Если выбрать «Нет», операция будет остановлена и программа закроется. «Отмена» оставит WindowManager открытым."
        }
        if ($trimmed.StartsWith('This will uninstall the following applications:', [StringComparison]::OrdinalIgnoreCase)) {
            $details = $trimmed.Substring('This will uninstall the following applications:'.Length)
            return "Будут удалены следующие приложения:$details"
        }
        if ($trimmed.StartsWith('The environment report could not be exported. ', [StringComparison]::OrdinalIgnoreCase)) {
            return "Не удалось экспортировать отчёт о системе. " + $trimmed.Substring('The environment report could not be exported. '.Length)
        }
        if ($trimmed.StartsWith('ISO export failed:', [StringComparison]::OrdinalIgnoreCase)) {
            return "Ошибка экспорта ISO:" + $trimmed.Substring('ISO export failed:'.Length)
        }
        if ($trimmed.StartsWith('USB write failed:', [StringComparison]::OrdinalIgnoreCase)) {
            return "Ошибка записи USB:" + $trimmed.Substring('USB write failed:'.Length)
        }
        if ($trimmed.StartsWith('An error occurred during install.wim modification:', [StringComparison]::OrdinalIgnoreCase)) {
            return "Ошибка при изменении install.wim:" + $trimmed.Substring('An error occurred during install.wim modification:'.Length)
        }
        if ($trimmed.StartsWith('ISO exported successfully!', [StringComparison]::OrdinalIgnoreCase)) {
            return "ISO успешно экспортирован!" + $trimmed.Substring('ISO exported successfully!'.Length)
        }
        if ($trimmed.StartsWith('A logs file already exists at:', [StringComparison]::OrdinalIgnoreCase)) {
            $rest = $trimmed.Substring('A logs file already exists at:'.Length)
            $rest = $rest.Replace('Choose another report filename or include and replace the existing logs.', 'Выберите другое имя отчёта или включите журналы и замените существующий файл.')
            $rest = $rest.Replace('Replace it?', 'Заменить его?')
            return "Файл журналов уже существует:$rest"
        }
        if ($trimmed.StartsWith('Supported settings were imported. The following retired settings were skipped:', [StringComparison]::OrdinalIgnoreCase)) {
            $rest = $trimmed.Substring('Supported settings were imported. The following retired settings were skipped:'.Length)
            $rest = $rest -replace '\.\.\.and (\d+) more\. See the WinUtil log for details\.', '...и ещё $1. Подробности смотрите в журнале WinUtil.'
            return "Поддерживаемые настройки импортированы. Следующие устаревшие настройки пропущены:$rest"
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
