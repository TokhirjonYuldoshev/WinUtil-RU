function Convert-WinUtilRussianRuntimeText {
    <#
        .SYNOPSIS
            Translates dynamic presentation text whose variable parts cannot live in the locale JSON.

        .DESCRIPTION
            This layer is presentation-only. Package IDs, commands, registry names, paths and raw
            diagnostic details are preserved. Static text stays in config/localization_ru.json.
    #>
    param([AllowNull()][object]$Value)

    if ($null -eq $Value -or $Value -isnot [string]) {
        return $Value
    }

    $text = [string]$Value
    if ($sync.preferences.language -ne 'ru-RU' -or [string]::IsNullOrWhiteSpace($text)) {
        return $text
    }

    $trimmed = $text.Trim()

    function Resolve-WinUtilRussianRuntimeBase {
        param([string]$Base)

        if ($sync.WinUtilRussianExactTranslations.ContainsKey($Base)) {
            return [string]$sync.WinUtilRussianExactTranslations[$Base]
        }
        return $Base
    }

    if ($trimmed -match '^Removing\s+(.+)\s+\((\d+)/(\d+)\)$') {
        return "Удаление $($Matches[1]) ($($Matches[2])/$($Matches[3]))"
    }
    if ($trimmed -match '^Removed\s+(.+)\s+\((\d+)/(\d+)\)$') {
        return "Удалено: $($Matches[1]) ($($Matches[2])/$($Matches[3]))"
    }
    if ($trimmed -match '^Applying\s+(.+)\s+\((\d+)/(\d+)\)$') {
        return "Применение $($Matches[1]) ($($Matches[2])/$($Matches[3]))"
    }
    if ($trimmed -match '^Undoing\s+(.+)\s+\((\d+)/(\d+)\)$') {
        return "Отмена $($Matches[1]) ($($Matches[2])/$($Matches[3]))"
    }
    if ($trimmed -match '^File size:\s*(.+)$') {
        return "Размер файла: $($Matches[1])"
    }
    if ($trimmed -match '^ISO saved to\s+(.+)$') {
        return "ISO сохранён: $($Matches[1])"
    }
    if ($trimmed -match '^Disk\s+(\d+)\s+is ready to boot from\.$') {
        return "Диск $($Matches[1]) готов к загрузке."
    }
    if ($trimmed -match '^Deleting files in\s+(.+?)\.\.\.\s+\((\d+)\s*/\s*(\d+)\)$') {
        return "Удаление файлов из $($Matches[1])... ($($Matches[2]) / $($Matches[3]))"
    }
    if ($trimmed -match '^Stopping\s+(.+)$') {
        return "Остановка: $(Resolve-WinUtilRussianRuntimeBase $Matches[1])"
    }
    if ($trimmed -match '^(.+)\s+is still running$') {
        return "$(Resolve-WinUtilRussianRuntimeBase $Matches[1]) всё ещё выполняется"
    }
    if ($trimmed -match '^(.+)\s+finished with\s+(\d+)\s+error\(s\)$') {
        return "$(Resolve-WinUtilRussianRuntimeBase $Matches[1]) завершено с ошибками: $($Matches[2])"
    }
    if ($trimmed -match '^(.+)\s+finished with\s+(\d+)\s+warning\(s\)$') {
        return "$(Resolve-WinUtilRussianRuntimeBase $Matches[1]) завершено с предупреждениями: $($Matches[2])"
    }
    if ($trimmed -match '^(.+)\s+(finished|failed|could not start)$') {
        $jobName = Resolve-WinUtilRussianRuntimeBase $Matches[1]
        switch ($Matches[2]) {
            'finished' { return "$jobName завершено" }
            'failed' { return "$jobName завершилось с ошибкой" }
            'could not start' { return "Не удалось запустить: $jobName" }
        }
    }

    # Generic "label (current/total)" and "label (percent%)" forms use the locale dictionary
    # only when the whole label has a known translation.
    if ($trimmed -match '^(.+)\s+\((\d+)/(\d+)\)$') {
        $base = $Matches[1]
        if ($sync.WinUtilRussianExactTranslations.ContainsKey($base)) {
            return "$($sync.WinUtilRussianExactTranslations[$base]) ($($Matches[2])/$($Matches[3]))"
        }
    }
    if ($trimmed -match '^(.+)\s+\((\d+)%\)$') {
        $base = $Matches[1]
        if ($sync.WinUtilRussianExactTranslations.ContainsKey($base)) {
            return "$($sync.WinUtilRussianExactTranslations[$base]) ($($Matches[2])%)"
        }
    }

    # Dialog bodies with paths, names or raw exception details.
    if ($trimmed -match '(?s)^(.+?) has not finished yet\.\s+Close the window and let it finish in the console\?') {
        $jobName = Resolve-WinUtilRussianRuntimeBase $Matches[1]
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

    return $text
}
