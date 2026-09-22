function Set-WinUtilLanguagePreference {
    <#
        .SYNOPSIS
            Saves the preferred UI language for the russian branch.

        .DESCRIPTION
            The language is applied the next time WinUtil starts. Keeping the switch at
            startup avoids mutating internal WPF values that WinUtil also uses as logic keys.
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet('ru-RU', 'en-US')]
        [string]$Language
    )

    $registryPath = 'HKCU:\Software\YTY\WindowManager'
    if (-not (Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
    }

    New-ItemProperty -Path $registryPath -Name 'Language' -Value $Language -PropertyType String -Force | Out-Null

    $sync.PendingLanguage = $Language
    if ($null -ne $sync.RussianLanguageMenuItem) {
        $sync.RussianLanguageMenuItem.IsChecked = $Language -eq 'ru-RU'
    }
    if ($null -ne $sync.EnglishLanguageMenuItem) {
        $sync.EnglishLanguageMenuItem.IsChecked = $Language -eq 'en-US'
    }

    $message = if ($Language -eq 'ru-RU') {
        'Русский язык сохранён. Изменение применится при следующем запуске WindowManager.'
    } else {
        'English has been saved. The change will apply the next time WindowManager starts.'
    }

    [System.Windows.MessageBox]::Show(
        $message,
        'WindowManager',
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Information
    ) | Out-Null
}
