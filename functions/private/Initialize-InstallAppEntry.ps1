function Initialize-InstallAppEntry {
    <#
        .SYNOPSIS
            Creates the app entry to be placed on the install tab for a given app
            Used to as part of the Install Tab UI generation
        .PARAMETER TargetElement
            The Element into which the Apps should be placed
        .PARAMETER appKey
            The Key of the app inside the $sync.configs.applicationsHashtable
    #>
        param(
            [Windows.Controls.WrapPanel]$TargetElement,
            $appKey
        )

        $app = $sync.configs.applicationsHashtable[$appKey]
        $handlers = Get-WinUtilAppEntryHandlers

        # Create the outer Border for the application type
        $border = New-Object Windows.Controls.Border
        $border.Style = $sync.Form.Resources.AppEntryBorderStyle
        $border.Tag = $appKey

        $catalogKey = $appKey -replace '^WPFInstall', ''
        $appDescription = $app.description
        if ($sync.preferences.language -eq 'ru-RU' -and $null -ne $sync.configs.applications_ru) {
            $localizedDescription = $sync.configs.applications_ru.PSObject.Properties[$catalogKey]
            if ($null -ne $localizedDescription -and -not [string]::IsNullOrWhiteSpace([string]$localizedDescription.Value)) {
                $appDescription = [string]$localizedDescription.Value
            }
        }
        $border.ToolTip = Get-WinUtilEntryToolTip -Description $appDescription -Key $appKey
        $border.Add_MouseLeftButtonUp($handlers.BorderClick)
        $border.Add_MouseEnter($handlers.MouseEnter)
        $border.Add_MouseLeave($handlers.MouseLeave)
        $border.Add_MouseRightButtonUp($handlers.RightClick)

        $checkBox = New-Object Windows.Controls.CheckBox
        # Sanitize the name for WPF
        $checkBox.Name = $appKey -replace '-', '_'
        # Store the original appKey in Tag
        $checkBox.Tag = $appKey
        $checkbox.Style = $sync.Form.Resources.AppEntryCheckboxStyle
        $checkbox.Add_Checked($handlers.Checked)
        $checkbox.Add_Unchecked($handlers.Unchecked)

        $contentPanel = New-Object Windows.Controls.StackPanel
        $contentPanel.Orientation = "Horizontal"
        $contentPanel.VerticalAlignment = [Windows.VerticalAlignment]::Center

        $icon = New-Object Windows.Controls.Grid
        $icon.SetResourceReference([Windows.FrameworkElement]::WidthProperty, "AppEntryIconSize")
        $icon.SetResourceReference([Windows.FrameworkElement]::HeightProperty, "AppEntryIconSize")
        $icon.Margin = New-Object Windows.Thickness(0, 0, 8, 0)
        $fallback = New-Object Windows.Controls.TextBlock
        $fallback.Text = $app.content.TrimStart(".").Substring(0, 1).ToUpper()
        $fallback.FontWeight = "Bold"; $fallback.HorizontalAlignment = "Center"; $fallback.VerticalAlignment = "Center"
        $fallback.SetResourceReference([Windows.Controls.TextBlock]::FontSizeProperty, "AppEntryFontSize")
        $fallback.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "ToggleButtonOnColor")
        [void]$icon.Children.Add($fallback)
        $iconMode = if ($sync.preferences.iconMode -in @('Auto', 'CacheOnly', 'Disabled')) {
            [string]$sync.preferences.iconMode
        } else {
            'Auto'
        }

        if ($app.link -and $iconMode -ne 'Disabled') {
            $safeIconName = ($catalogKey -replace '[^A-Za-z0-9_.-]', '_') + '.png'
            $iconCachePath = Join-Path $env:LOCALAPPDATA 'YTY\WindowManager\IconCache'
            $cachedIcon = Join-Path $iconCachePath $safeIconName

            if (Test-Path -LiteralPath $cachedIcon) {
                try {
                    $logo = New-Object Windows.Controls.Image
                    $logo.Stretch = [Windows.Media.Stretch]::Uniform
                    $logo.Source = [Windows.Media.Imaging.BitmapImage]::new([Uri]::new($cachedIcon))
                    $fallback.Visibility = "Collapsed"
                    [void]$icon.Children.Add($logo)
                } catch {
                    # Leave the letter fallback visible if a cached icon is invalid.
                }
            } elseif ($iconMode -eq 'Auto') {
                $logo = New-Object Windows.Controls.Image
                $logo.Stretch = [Windows.Media.Stretch]::Uniform
                $logo.Add_ImageFailed($handlers.ImageFailed)
                $logo.Source = "https://www.google.com/s2/favicons?sz=64&domain_url=$([uri]::EscapeDataString($app.link))"
                [void]$icon.Children.Add($logo)
            }
        }
        [void]$contentPanel.Children.Add($icon)

        # Create the TextBlock for the application name
        $appName = New-Object Windows.Controls.TextBlock
        $appName.Style = $sync.Form.Resources.AppEntryNameStyle
        $appName.Text = $app.content

        # Add FOSS label after the name if FOSS
        [void]$contentPanel.Children.Add($appName)
        $checkBox.Content = $contentPanel

        # Add accessibility properties to make the elements screen reader friendly
        $checkBox.SetValue([Windows.Automation.AutomationProperties]::NameProperty, $app.content)
        $border.SetValue([Windows.Automation.AutomationProperties]::NameProperty, $app.content)

        # Keep the same layout for every entry so the checkbox handlers can reach the border
        $entryLayout = New-Object Windows.Controls.Grid
        [void]$entryLayout.Children.Add($checkBox)

        # Mark FOSS apps with a corner badge, bled into the border padding so it sits on the edge
        if ($app.foss -eq $true) {
            $fossBadge = New-WinUtilFossBadge
            $fossBadge.HorizontalAlignment = "Right"
            $fossBadge.VerticalAlignment = "Top"
            $fossBadge.Margin = New-Object Windows.Thickness(0, -4, -6, 0)

            [void]$entryLayout.Children.Add($fossBadge)
        }

        $border.Child = $entryLayout
        if ($sync.selectedApps -contains $appKey) {
            $checkBox.IsChecked = $true
        }
        # Add the border to the corresponding Category
        $TargetElement.Children.Add($border) | Out-Null
        return $checkbox
    }
