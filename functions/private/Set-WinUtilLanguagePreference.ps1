function Set-WinUtilLanguagePreference {
    <#
        .SYNOPSIS
            Saves the preferred UI language for the Russian edition.

        .DESCRIPTION
            Internal WinUtil logic keeps its stable English keys. The selected presentation
            language is persisted per user and applied on the next process start. When the
            online launcher is in use, the user can restart immediately without re-downloading
            or recompiling the project.
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet('ru-RU', 'en-US')]
        [string]$Language
    )

    $currentLanguage = if ($sync.preferences.language -in @('ru-RU', 'en-US')) {
        [string]$sync.preferences.language
    } else {
        'ru-RU'
    }

    if ($Language -eq $currentLanguage) {
        if ($null -ne $sync.RussianLanguageMenuItem) {
            $sync.RussianLanguageMenuItem.IsChecked = $Language -eq 'ru-RU'
        }
        if ($null -ne $sync.EnglishLanguageMenuItem) {
            $sync.EnglishLanguageMenuItem.IsChecked = $Language -eq 'en-US'
        }
        return
    }

    if ($sync.ActiveJob) {
        $busyMessage = if ($currentLanguage -eq 'ru-RU') {
            'Дождитесь завершения текущей операции перед сменой языка.'
        } else {
            'Wait for the current operation to finish before changing the language.'
        }
        Show-WinUtilMessage -Message $busyMessage -Title 'WinUtil RU' -Button 'OK' -Icon 'Warning' | Out-Null
        return
    }

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

    $canRestart = $env:WINDOWMANAGER_LAUNCHER_RESTART -eq '1'
    if (-not $canRestart) {
        $message = if ($currentLanguage -eq 'ru-RU') {
            'Язык сохранён. Изменение применится при следующем запуске WinUtil RU.'
        } else {
            'The language has been saved. The change will apply the next time WinUtil RU starts.'
        }

        Show-WinUtilMessage -Message $message -Title 'WinUtil RU' -Button 'OK' -Icon 'Information' | Out-Null
        return
    }

    $message = if ($currentLanguage -eq 'ru-RU') {
        'Язык сохранён. Перезапустить WinUtil RU сейчас, чтобы применить изменение?'
    } else {
        'The language has been saved. Restart WinUtil RU now to apply the change?'
    }

    $answer = Show-WinUtilMessage -Message $message -Title 'WinUtil RU' -Button 'YesNo' -Icon 'Question'
    if ("$answer" -ne 'Yes') {
        return
    }

    New-ItemProperty -Path $registryPath -Name 'RestartRequested' -Value 1 -PropertyType DWord -Force | Out-Null
    $sync.ForceClose = $true
    $sync.Form.Close()
}
