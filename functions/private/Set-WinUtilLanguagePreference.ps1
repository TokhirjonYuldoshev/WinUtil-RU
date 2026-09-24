function Set-WinUtilLanguagePreference {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('ru-RU', 'en-US')]
        [string]$Language
    )

    $sync.RussianLanguageMenuItem.IsChecked = $Language -eq 'ru-RU'
    $sync.EnglishLanguageMenuItem.IsChecked = $Language -eq 'en-US'
    if ($sync.preferences.language -eq $Language) {
        return
    }

    $path = 'HKCU:\Software\YTY\WindowManager'
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }
    New-ItemProperty -Path $path -Name Language -Value $Language -PropertyType String -Force | Out-Null

    $message = if ($sync.preferences.language -eq 'ru-RU') {
        'Язык сохранён. Перезапустите WinUtil RU, чтобы применить изменение.'
    } else {
        'Language saved. Restart WinUtil RU to apply the change.'
    }
    [System.Windows.MessageBox]::Show($message, 'WinUtil RU', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
}
