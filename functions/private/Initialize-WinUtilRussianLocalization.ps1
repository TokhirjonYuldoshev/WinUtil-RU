function Initialize-WinUtilRussianLocalization {
    <#
    .SYNOPSIS
        Applies Russian localization to user-facing WinUtil text.

    .DESCRIPTION
        Keeps control names, config keys, commands, registry paths and other execution data
        unchanged. Only text presented to the user is localized so upstream behavior remains
        intact and future upstream changes are easier to merge into the russian branch.
    #>

    $script:WinUtilRussianExactTranslations = @{
        # Window chrome and common UI
        'Change the WinUtil UI Theme' = 'Изменить тему интерфейса WinUtil'
        'Theme' = 'Тема'
        'Auto' = 'Авто'
        'Follow the Windows Theme' = 'Следовать теме Windows'
        'Dark' = 'Тёмная'
        'Use Dark Theme' = 'Использовать тёмную тему'
        'Light' = 'Светлая'
        'Use Light Theme' = 'Использовать светлую тему'
        'Adjust Font Scaling for Accessibility' = 'Настроить масштаб шрифта'
        'Font Scaling' = 'Масштаб шрифта'
        'Small' = 'Меньше'
        'Large' = 'Больше'
        'Reset' = 'Сбросить'
        'Apply' = 'Применить'
        'Settings' = 'Настройки'
        'Import' = 'Импорт'
        'Import Configuration from exported file.' = 'Импортировать конфигурацию из экспортированного файла.'
        'Export' = 'Экспорт'
        'Export Selected Elements and copy execution command to clipboard.' = 'Экспортировать выбранные элементы и скопировать команду запуска в буфер обмена.'
        'Export Environment Report' = 'Экспорт отчёта о системе'
        'Export a read-only diagnostics report for troubleshooting.' = 'Экспортировать диагностический отчёт только для чтения.'
        'About' = 'О программе'
        'Documentation' = 'Документация'
        'Sponsors' = 'Спонсоры'
        'Minimize' = 'Свернуть'
        'Maximize' = 'Развернуть'
        'Restore' = 'Восстановить'
        'Close' = 'Закрыть'
        'Cut' = 'Вырезать'
        'Copy' = 'Копировать'
        'Paste' = 'Вставить'
        'Search' = 'Поиск'
        'Clear' = 'Очистить'
        'Back' = 'Назад'
        'Next' = 'Далее'
        'Cancel' = 'Отмена'
        'Yes' = 'Да'
        'No' = 'Нет'
        'OK' = 'ОК'

        # Main navigation
        'Install' = 'Установка'
        'Tweaks' = 'Настройки системы'
        'Config' = 'Инструменты'
        'Updates' = 'Обновления'
        'Win11ISO' = 'ISO Windows 11'

        # Install tab
        'Filter by category. Ctrl click to select more than one.' = 'Фильтр по категории. Ctrl+щелчок позволяет выбрать несколько категорий.'
        'All' = 'Все'
        'Browsers' = 'Браузеры'
        'Communications' = 'Связь'
        'Development' = 'Разработка'
        'Document' = 'Документы'
        'Games' = 'Игры'
        'Microsoft Tools' = 'Инструменты Microsoft'
        'Multimedia Tools' = 'Мультимедиа'
        'Pro Tools' = 'Профессиональные инструменты'
        'Selfhosted Tools' = 'Самостоятельный хостинг'
        'Utilities' = 'Утилиты'
        'Install/Upgrade Applications' = 'Установить/обновить приложения'
        'Install or upgrade the selected applications' = 'Установить или обновить выбранные приложения'
        'Uninstall Applications' = 'Удалить приложения'
        'Uninstall the selected applications' = 'Удалить выбранные приложения'
        'Upgrade all Applications' = 'Обновить все приложения'
        'Upgrade all applications to the latest version' = 'Обновить все приложения до последних версий'
        'Collapse All Categories' = 'Свернуть все категории'
        'Collapse all application categories' = 'Свернуть все категории приложений'
        'Expand All Categories' = 'Развернуть все категории'
        'Expand all application categories' = 'Развернуть все категории приложений'
        'Clear Selection' = 'Очистить выбор'
        'Clear the selection of applications' = 'Снять выбор со всех приложений'
        'Show Installed Apps' = 'Показать установленные приложения'
        'Show installed applications' = 'Показать установленные приложения'
        'Selected Apps: 0' = 'Выбрано приложений: 0'
        'Show the selected applications' = 'Показать выбранные приложения'
        'Free and Open Source Software' = 'Свободное ПО с открытым исходным кодом'
        'Information about the #FOSS label on application entries' = 'Информация о метке #FOSS у приложений'
        'Package Manager' = 'Менеджер пакетов'
        'Use WinGet for package management' = 'Использовать WinGet для управления пакетами'
        'Use Chocolatey for package management' = 'Использовать Chocolatey для управления пакетами'
        'Actions' = 'Действия'
        'Selection' = 'Выбор'

        # Tweaks tab
        'Recommended Selections:' = 'Рекомендуемые варианты:'
        'Standard' = 'Стандартный'
        'Minimal' = 'Минимальный'
        'Advanced' = 'Расширенный'
        'Get Installed Tweaks' = 'Определить применённые настройки'
        'AppX Removal' = 'Удаление AppX'
        'Run Tweaks' = 'Применить настройки'
        'Undo Selected Tweaks' = 'Отменить выбранные настройки'
        'Note: Hover over items to get a better description. Please be careful as many of these tweaks will heavily modify your system.' = 'Примечание: наведите указатель на пункт, чтобы увидеть подробное описание. Будьте внимательны: многие настройки существенно изменяют систему.'
        'Recommended selections are for normal users and if you are unsure do NOT check anything else!' = 'Рекомендуемые варианты подходят большинству пользователей. Если вы не уверены, не выбирайте дополнительные настройки.'
        'Essential Tweaks' = 'Основные настройки'
        'Advanced Tweaks - CAUTION' = 'Расширенные настройки — ОСТОРОЖНО'
        'z__Advanced Tweaks - CAUTION' = 'z__Расширенные настройки — ОСТОРОЖНО'

        # Common tweak names
        'Activity History' = 'История активности'
        'Hibernation' = 'Гибернация'
        'Widgets' = 'Виджеты'
        'Start Menu Previous Layout' = 'Предыдущий вид меню «Пуск»'
        'Microsoft Store Recommended Search Results' = 'Рекомендуемые результаты Microsoft Store в поиске'
        'Location Tracking' = 'Отслеживание местоположения'
        'Services' = 'Службы'
        'Brave Browser' = 'Браузер Brave'
        'RDP Unsigned File Warnings' = 'Предупреждения о неподписанных RDP-файлах'
        'Microsoft Edge' = 'Microsoft Edge'
        'Consumer Features' = 'Потребительские функции'
        'Telemetry' = 'Телеметрия'
        'Advertising ID' = 'Рекламный идентификатор'
        'Background Apps' = 'Фоновые приложения'
        'Windows Search' = 'Поиск Windows'
        'Location Services' = 'Службы геолокации'
        'Taskbar' = 'Панель задач'
        'Start Menu' = 'Меню «Пуск»'
        'Lock Screen' = 'Экран блокировки'
        'Notifications' = 'Уведомления'
        'Mouse Acceleration' = 'Ускорение мыши'
        'Sticky Keys' = 'Залипание клавиш'
        'Classic Context Menu' = 'Классическое контекстное меню'
        'Show File Extensions' = 'Показывать расширения файлов'
        'Hidden Files' = 'Скрытые файлы'
        'Dark Mode' = 'Тёмный режим'
        'End Task' = 'Завершение задачи'
        'Debloat' = 'Очистить от лишнего'

        # Config / features tab
        'Features' = 'Компоненты'
        'Fixes' = 'Исправления'
        'Legacy Windows Panels' = 'Классические панели Windows'
        'Powershell Profile Powershell 7+ Only' = 'Профиль PowerShell — только PowerShell 7+'
        'Remote Access' = 'Удалённый доступ'
        '.NET Framework (Versions 2, 3, 4)' = '.NET Framework (версии 2, 3, 4)'
        'NTP Server' = 'Сервер NTP'
        'Legacy Media Components (WMP, DirectPlay)' = 'Устаревшие мультимедийные компоненты (WMP, DirectPlay)'
        'Windows Subsystem for Linux (WSL)' = 'Подсистема Windows для Linux (WSL)'
        'Network File System (NFS)' = 'Сетевая файловая система (NFS)'
        'Registry Backup (Daily Task 12:30am)' = 'Резервное копирование реестра (ежедневно в 00:30)'
        'Legacy F8 Boot Recovery' = 'Классическое восстановление загрузки по F8'
        'Windows Sandbox' = 'Песочница Windows'
        'Install Features' = 'Установить компоненты'
        'Windows Update' = 'Центр обновления Windows'
        'Network' = 'Сеть'
        'System Corruption Scan' = 'Проверка целостности системы'
        'Computer Management' = 'Управление компьютером'
        'Control Panel' = 'Панель управления'
        'Mouse Properties' = 'Свойства мыши'
        'Network Connections' = 'Сетевые подключения'
        'Power Panel' = 'Электропитание'
        'Printer Panel' = 'Принтеры'
        'Programs and Features' = 'Программы и компоненты'
        'Region' = 'Регион'
        'Security and Maintenance' = 'Безопасность и обслуживание'
        'Sound Settings' = 'Параметры звука'
        'System Properties' = 'Свойства системы'
        'Time and Date' = 'Дата и время'
        'Windows Defender Firewall' = 'Брандмауэр Защитника Windows'
        'Windows Restore' = 'Восстановление Windows'
        'CTT PowerShell Profile' = 'Профиль CTT PowerShell'
        'OpenSSH Server' = 'Сервер OpenSSH'

        # Updates tab
        'Windows Update Profiles' = 'Профили обновления Windows'
        'Choose how Windows receives updates. Each profile replaces the Windows Update settings managed by WinUtil.' = 'Выберите способ получения обновлений Windows. Каждый профиль заменяет параметры Центра обновления Windows, которыми управляет WinUtil.'
        'Recommended' = 'Рекомендуемый'
        'Balanced security and stability' = 'Баланс безопасности и стабильности'
        '- Defers feature updates for 365 days' = '- Откладывает обновления функций на 365 дней'
        '- Defers quality updates for 4 days' = '- Откладывает качественные обновления на 4 дня'
        '- Excludes drivers from quality updates' = '- Исключает драйверы из качественных обновлений'
        '- Prevents automatic restarts while a user is signed in' = '- Запрещает автоматическую перезагрузку, пока пользователь вошёл в систему'
        'Available on Windows Pro, Enterprise, and Education editions.' = 'Доступно в редакциях Windows Pro, Enterprise и Education.'
        'Apply Recommended' = 'Применить рекомендуемый'
        'Windows Default' = 'По умолчанию Windows'
        'Return control to Windows' = 'Вернуть управление Windows'
        '- Removes Windows Update policies applied by WinUtil' = '- Удаляет политики обновления Windows, применённые WinUtil'
        '- Restores update service startup settings' = '- Восстанавливает параметры запуска служб обновления'
        '- Re-enables update scheduled tasks' = '- Повторно включает задания обновления в планировщике'
        'Use this to undo the Recommended or Disable profile.' = 'Используйте этот вариант, чтобы отменить профиль «Рекомендуемый» или «Отключить обновления».'
        'Restore Defaults' = 'Восстановить значения по умолчанию'
        'Disable Updates' = 'Отключить обновления'
        'Advanced use only' = 'Только для опытных пользователей'
        '- Disables automatic update policy' = '- Отключает политику автоматических обновлений'
        '- Stops update services and scheduled tasks' = '- Останавливает службы обновления и задания планировщика'
        '- Clears downloaded update files' = '- Удаляет загруженные файлы обновлений'
        'Security updates will not be installed while this profile is active.' = 'Пока этот профиль активен, обновления безопасности устанавливаться не будут.'
        'Changes apply system-wide. Restart Windows after switching profiles. Use Restore Defaults to undo WinUtil update policies.' = 'Изменения применяются ко всей системе. После смены профиля перезагрузите Windows. Для отмены политик WinUtil используйте «Восстановить значения по умолчанию».'

        # Windows 11 ISO tab
        'Back to the previous step' = 'Вернуться к предыдущему шагу'
        'Forward to the next step' = 'Перейти к следующему шагу'
        '1   Select ISO' = '1   Выбор ISO'
        'Select your Windows 11 ISO' = 'Выберите ISO-образ Windows 11'
        'Choose an official Windows 11 ISO downloaded from Microsoft. It will be mounted and checked before anything is changed.' = 'Выберите официальный ISO-образ Windows 11, загруженный с сайта Microsoft. Перед изменениями образ будет подключён и проверен.'
        'ISO file' = 'ISO-файл'
        'No ISO selected...' = 'ISO-образ не выбран...'
        'Browse' = 'Обзор'
        'File size:' = 'Размер файла:'
        'Mount & Verify ISO' = 'Подключить и проверить ISO'
        'You must use an official Microsoft ISO' = 'Необходимо использовать официальный ISO-образ Microsoft'
        'On the download page choose Windows 11, your language, and 64-bit (x64).' = 'На странице загрузки выберите Windows 11, нужный язык и 64-разрядную версию (x64).'
        'Open Microsoft Download Page' = 'Открыть страницу загрузки Microsoft'
        '2   Modify Image' = '2   Изменение образа'
        'Modify the image' = 'Изменение образа'
        'Mounted at' = 'Подключено как'
        'Image file' = 'Файл образа'
        'Windows edition' = 'Редакция Windows'
        'Inject current system drivers' = 'Добавить драйверы текущей системы'
        'Run Windows ISO Modification and Creator' = 'Запустить изменение и создание ISO Windows'
        'What this does to the image' = 'Что будет изменено в образе'
        'Removes the preinstalled apps and the OneDrive setup' = 'Удаляет предустановленные приложения и установщик OneDrive'
        'Bypasses the TPM, Secure Boot, CPU, RAM and storage checks' = 'Обходит проверки TPM, Secure Boot, процессора, ОЗУ и накопителя'
        'Skips the Microsoft account screen so you can use a local account' = 'Пропускает экран учётной записи Microsoft, позволяя использовать локальную учётную запись'
        'Turns off telemetry, Copilot, the chat icon and search box suggestions' = 'Отключает телеметрию, Copilot, значок чата и подсказки в поиске'
    }

    $phraseTranslations = [ordered]@{
        ' - Set to Manual' = ' — перевести в ручной режим'
        ' - Enable' = ' — включить'
        ' - Disable' = ' — отключить'
        ' - Remove' = ' — удалить'
        ' - Debloat' = ' — очистить от лишнего'
        ' - Reset' = ' — сбросить'
        ' - Reinstall' = ' — переустановить'
        ' - Install' = ' — установить'
        ' - Run' = ' — запустить'
        'Install or Upgrade' = 'Установить или обновить'
        'Uninstall' = 'Удалить'
        'Upgrade' = 'Обновить'
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

        $trimmed = $text.Trim()
        if ($script:WinUtilRussianExactTranslations.ContainsKey($trimmed)) {
            $translated = $script:WinUtilRussianExactTranslations[$trimmed]
            $prefixLength = $text.Length - $text.TrimStart().Length
            $suffixLength = $text.Length - $text.TrimEnd().Length
            return (' ' * $prefixLength) + $translated + (' ' * $suffixLength)
        }

        # Never translate substrings inside functional/display values. Partial replacement
        # produced mixed strings and could change values that the UI logic relies on.
        return $text
    }

    # Localize presentation-only XAML. Internal TabItem headers and generic ToggleButton
    # Content stay in English because WinUtil uses some of those values as logic keys.
    try {
        [xml]$localizedXaml = $script:inputXML

        foreach ($node in $localizedXaml.SelectNodes('//*')) {
            $elementName = $node.LocalName

            # Tooltips are presentation-only.
            $toolTipAttribute = $node.Attributes.GetNamedItem('ToolTip')
            if ($null -ne $toolTipAttribute) {
                $toolTipAttribute.Value = Convert-WinUtilRussianText $toolTipAttribute.Value
            }

            # Safe static controls. Do not translate TabItem.Header here.
            if ($elementName -in @('Label', 'Button', 'TextBlock', 'Run', 'MenuItem')) {
                foreach ($attributeName in @('Content', 'Text', 'Header')) {
                    $attribute = $node.Attributes.GetNamedItem($attributeName)
                    if ($null -ne $attribute) {
                        $attribute.Value = Convert-WinUtilRussianText $attribute.Value
                    }
                }
            }

            # Install category chips carry their real category in Tag at runtime, so only
            # their visible Content may be translated.
            if ($elementName -eq 'ToggleButton') {
                $nameAttribute = $node.Attributes.GetNamedItem('Name')
                $contentAttribute = $node.Attributes.GetNamedItem('Content')
                if ($null -ne $nameAttribute -and $nameAttribute.Value -like 'WPFSearchChip*' -and $null -ne $contentAttribute) {
                    $contentAttribute.Value = Convert-WinUtilRussianText $contentAttribute.Value
                }
            }

            # Text inside TextBlock/Run nodes is presentation-only. This also translates
            # the visible top navigation while leaving hidden TabItem headers untouched.
            if ($elementName -in @('TextBlock', 'Run')) {
                foreach ($child in @($node.ChildNodes)) {
                    if ($child.NodeType -eq [System.Xml.XmlNodeType]::Text -and -not [string]::IsNullOrWhiteSpace($child.Value)) {
                        $child.Value = Convert-WinUtilRussianText $child.Value
                    }
                }
            }
        }

        $script:inputXML = $localizedXaml.OuterXml
    } catch {
        Write-Warning "Russian localization could not process the XAML: $($_.Exception.Message)"
    }

    # Do not mutate config Content/Description/Category values. Those objects are also
    # used by WinUtil logic. Dynamic controls translate only when their text is rendered.

    # Use Russian formatting for dates/numbers shown by .NET without changing command behavior.
    try {
        $culture = [System.Globalization.CultureInfo]::GetCultureInfo('ru-RU')
        [System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture
    } catch {
        # Localization text still works even if culture setup is unavailable.
    }
}
