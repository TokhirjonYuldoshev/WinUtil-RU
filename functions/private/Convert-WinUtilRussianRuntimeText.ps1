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

    if ($trimmed -match '^(.+?) is still running\. Wait for it to finish before starting another action\.$') {
        $jobName = Resolve-WinUtilRussianRuntimeBase $Matches[1]
        return "$jobName всё ещё выполняется. Дождитесь завершения перед запуском другого действия."
    }
    if ($trimmed.StartsWith('The previously verified ISO is still mounted and could not be dismounted:', [StringComparison]::OrdinalIgnoreCase)) {
        $rest = $trimmed.Substring('The previously verified ISO is still mounted and could not be dismounted:'.Length)
        $rest = $rest.Replace('Dismount it yourself, then select an ISO again.', 'Отключите его вручную, затем снова выберите ISO.')
        return "Ранее проверенный ISO всё ещё подключён и не может быть отключён:$rest"
    }
    if ($trimmed.StartsWith('A previous WinUtil ISO working directory was found:', [StringComparison]::OrdinalIgnoreCase)) {
        $rest = $trimmed.Substring('A previous WinUtil ISO working directory was found:'.Length)
        $rest = $rest.Replace('(Last modified:', '(Последнее изменение:')
        $rest = $rest.Replace('The output step has been restored so you can save the already-modified image.', 'Этап вывода восстановлен, поэтому уже изменённый образ можно сохранить.')
        $rest = $rest.Replace("Click 'Start Over' there if you want to start over.", 'Нажмите «Начать заново», если хотите начать сначала.')
        return "Найдена предыдущая рабочая папка ISO WinUtil:$rest"
    }
    if ($trimmed.StartsWith('This will delete the temporary working directory:', [StringComparison]::OrdinalIgnoreCase)) {
        $rest = $trimmed.Substring('This will delete the temporary working directory:'.Length)
        $rest = $rest.Replace('And reset the interface back to the start.', 'Интерфейс также будет возвращён к начальному шагу.')
        $rest = $rest.Replace('Continue?', 'Продолжить?')
        return "Будет удалена временная рабочая папка:$rest"
    }
    if ($trimmed -match "(?s)^This ISO uses an install\.esd file that is (\d+) MB\. WinUtil's FAT32 USB format cannot store files larger than 4 GB\.\s+Export an ISO instead or use media with install\.wim\.$") {
        return "В этом ISO используется файл install.esd размером $($Matches[1]) МБ. Формат FAT32, используемый WinUtil для USB, не поддерживает файлы больше 4 ГБ.`n`nЭкспортируйте ISO или используйте носитель с install.wim."
    }
    if ($trimmed -match '(?s)^ALL data on Disk (\d+) \((.+?), ([\d.,]+) GB\) will be PERMANENTLY ERASED\.\s+Are you sure you want to continue\?$') {
        return "ВСЕ данные на диске $($Matches[1]) ($($Matches[2]), $($Matches[3]) ГБ) будут БЕЗВОЗВРАТНО УДАЛЕНЫ.`n`nПродолжить?"
    }

    if ($trimmed -match "^Unable to apply registry state '(.+)'\.$") {
        return "Не удалось применить состояние реестра '$($Matches[1])'."
    }

    if ($trimmed -match "^WinUtil's window is closed\. (.+) is still running here, and this window will close when it finishes\.$") {
        $jobName = Resolve-WinUtilRussianRuntimeBase $Matches[1]
        return "Окно WinUtil закрыто. $jobName продолжает выполняться в этой консоли; после завершения окно закроется."
    }
    if ($trimmed -match '^Waiting for (.+) to finish\.\.\.$') {
        return "Ожидание завершения: $(Resolve-WinUtilRussianRuntimeBase $Matches[1])..."
    }
    if ($trimmed -match '^(.+) is taking longer than ([\d.,]+) minutes\. Exiting\.$') {
        return "$(Resolve-WinUtilRussianRuntimeBase $Matches[1]) выполняется дольше $($Matches[2]) мин. Завершение программы."
    }
    if ($trimmed -match '^(.+) finished\. Closing\.$') {
        return "$(Resolve-WinUtilRussianRuntimeBase $Matches[1]) завершено. Закрытие."
    }

    return $text
}
