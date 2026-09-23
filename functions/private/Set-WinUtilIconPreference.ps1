function Set-WinUtilIconPreference {
    <#
        .SYNOPSIS
            Saves the application icon loading mode or clears the icon cache.
    #>
    param(
        [ValidateSet('Auto', 'CacheOnly', 'Disabled')]
        [string]$Mode,
        [switch]$ClearCache
    )

    $registryPath = 'HKCU:\Software\YTY\WindowManager'
    $cachePath = Join-Path $env:LOCALAPPDATA 'YTY\WindowManager\IconCache'

    if ($ClearCache) {
        try {
            if (Test-Path -LiteralPath $cachePath) {
                Get-ChildItem -LiteralPath $cachePath -File -ErrorAction SilentlyContinue |
                    Remove-Item -Force -ErrorAction Stop
            }
            $message = Convert-WinUtilRussianText 'Icon cache cleared.'
            Show-WinUtilMessage -Message $message -Title 'WindowManager' -Button 'OK' -Icon 'Information' | Out-Null
        } catch {
            $message = Convert-WinUtilRussianText 'Unable to clear the icon cache.'
            Show-WinUtilMessage -Message $message -Title 'WindowManager' -Button 'OK' -Icon 'Warning' | Out-Null
        }
        return
    }

    if ([string]::IsNullOrWhiteSpace($Mode)) {
        return
    }

    if ($sync.ActiveJob) {
        $message = if ($sync.preferences.language -eq 'ru-RU') {
            'Wait for the current operation to finish before changing this setting.'
        } else {
            'Wait for the current operation to finish before changing this setting.'
        }
        $message = Convert-WinUtilRussianText $message
        Show-WinUtilMessage -Message $message -Title 'WindowManager' -Button 'OK' -Icon 'Warning' | Out-Null
        return
    }

    if (-not (Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
    }

    New-ItemProperty -Path $registryPath -Name 'AppIconMode' -Value $Mode -PropertyType String -Force | Out-Null
    $sync.preferences.iconMode = $Mode

    if ($null -ne $sync.AppIconsAutoMenuItem) {
        $sync.AppIconsAutoMenuItem.IsChecked = $Mode -eq 'Auto'
    }
    if ($null -ne $sync.AppIconsCacheOnlyMenuItem) {
        $sync.AppIconsCacheOnlyMenuItem.IsChecked = $Mode -eq 'CacheOnly'
    }
    if ($null -ne $sync.AppIconsDisabledMenuItem) {
        $sync.AppIconsDisabledMenuItem.IsChecked = $Mode -eq 'Disabled'
    }

    $canRestart = $env:WINDOWMANAGER_LAUNCHER_RESTART -eq '1'
    if (-not $canRestart) {
        $message = Convert-WinUtilRussianText 'App icon mode saved. The change will apply the next time WindowManager starts.'
        Show-WinUtilMessage -Message $message -Title 'WindowManager' -Button 'OK' -Icon 'Information' | Out-Null
        return
    }

    $message = Convert-WinUtilRussianText 'App icon mode saved. Restart WindowManager now to apply the change?'
    $answer = Show-WinUtilMessage -Message $message -Title 'WindowManager' -Button 'YesNo' -Icon 'Question'
    if ("$answer" -ne 'Yes') {
        return
    }

    New-ItemProperty -Path $registryPath -Name 'RestartRequested' -Value 1 -PropertyType DWord -Force | Out-Null
    $sync.ForceClose = $true
    $sync.Form.Close()
}
