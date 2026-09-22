function Initialize-WinUtilRussianLocalization {
    <#
    .SYNOPSIS
        Applies Russian localization to user-facing WinUtil text.

    .DESCRIPTION
        Keeps control names, config keys, commands, registry paths and other execution data
        unchanged. Only text presented to the user is localized so upstream behavior remains
        intact and future upstream changes are easier to merge into the russian branch.
    #>

    # Persisted UI language. The russian branch defaults to Russian, but users can
    # switch to the original English UI from Settings.
    $language = 'ru-RU'
    try {
        $savedLanguage = (Get-ItemProperty -Path 'HKCU:\Software\YTY\WindowManager' -Name 'Language' -ErrorAction Stop).Language
        if ($savedLanguage -in @('ru-RU', 'en-US')) {
            $language = $savedLanguage
        }
    } catch {
        # No saved preference yet.
    }
    $sync.preferences.language = $language

    $sync.WinUtilRussianExactTranslations = @{
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
        'Delivery Optimization' = 'Оптимизация доставки'
        'ConsumerFeatures' = 'Потребительские функции'
        'Date & Time' = 'Дата и время'
        'File Explorer Home and Gallery' = 'Главная и Галерея Проводника'
        'Visual Effects' = 'Визуальные эффекты'
        'Disable Reserved Storage' = 'Отключить зарезервированное хранилище'
        'Restore Point' = 'Точка восстановления'
        'End Task With Right Click' = 'Завершение задачи правой кнопкой мыши'
        'Storage Sense' = 'Контроль памяти'
        'Windows AI' = 'ИИ Windows'
        'Windows Platform Binary Table (WPBT)' = 'Windows Platform Binary Table (WPBT)'
        'Prevent Device Companion Apps' = 'Запретить сопутствующие приложения устройств'
        'Razer Software Auto-Install' = 'Автоустановка ПО Razer'
        'Logitech Download Assistant Auto-Install' = 'Автоустановка Logitech Download Assistant'
        'System Tray Notifications & Calendar' = 'Уведомления и календарь в системном трее'
        'Adobe URL Block List' = 'Блокировка URL Adobe'
        'Right-Click Menu Previous Layout' = 'Классическое контекстное меню'
        'Disk Cleanup' = 'Очистка диска'
        'Temporary Files' = 'Временные файлы'
        'IPv6' = 'IPv6'
        'File Explorer Automatic Folder Discovery' = 'Автоопределение типа папок Проводником'
        'BSoD Verbose Mode' = 'Подробный режим BSoD'
        'System Tray Battery Percentage' = 'Процент заряда в системном трее'
        'Dark Theme for Windows' = 'Тёмная тема Windows'
        'File Explorer File Extensions' = 'Расширения файлов в Проводнике'
        'File Explorer Hidden Files' = 'Скрытые файлы в Проводнике'
        'Logon Verbose Mode' = 'Подробные сообщения при входе'
        'Microsoft Outlook New Version' = 'Новая версия Microsoft Outlook'
        'Scrollbars Always Visible' = 'Всегда показывать полосы прокрутки'
        'Multiplane Overlay' = 'Многоплоскостное наложение (MPO)'
        'Num Lock on Startup' = 'Num Lock при запуске'
        'Window Snapping' = 'Привязка окон'
        'S0 Sleep Network Connectivity' = 'Сеть в режиме сна S0'
        'S3 Sleep' = 'Сон S3'
        'Settings Home Page' = 'Главная страница «Параметров»'
        'Start Menu Bing Search' = 'Поиск Bing в меню «Пуск»'
        'Logon Screen Acrylic Blur' = 'Размытие экрана входа'
        'Start Menu Recommendations' = 'Рекомендации в меню «Пуск»'
        'Taskbar Centered Icons' = 'Значки панели задач по центру'
        'Taskbar Search Icon' = 'Значок поиска на панели задач'
        'Taskbar Task View Icon' = 'Значок представления задач'
        'Game Mode' = 'Игровой режим'
        'Enable Long Paths' = 'Поддержка длинных путей'
        'DNS - Set to:' = 'DNS — выбрать:'
        'Ultimate Performance Profile' = 'Профиль «Максимальная производительность»'
        'Customize Preferences' = 'Настройка предпочтений'
        'Performance Plans - NOT FOR LAPTOPS' = 'Планы производительности — НЕ ДЛЯ НОУТБУКОВ'
        'Hyper-V' = 'Hyper-V'
        'AutoLogon' = 'AutoLogon'
        'Default' = 'По умолчанию'
        'Enabled' = 'Включено'
        'Disabled' = 'Отключено'
        'Fastest' = 'Самый быстрый'
        'Manual' = 'Вручную'
        'Custom / Unknown - select a state' = 'Пользовательское / неизвестное — выберите состояние'
        'Win11 Creator' = 'Создание Windows 11'
        'Stops Windows from publishing or uploading user activities while preserving clipboard history.' = 'Запрещает Windows публиковать или отправлять действия пользователя, сохраняя историю буфера обмена.'
        'Hibernation is really meant for laptops as it saves what''s in memory before turning the PC off. It really should never be used.' = 'Гибернация в основном предназначена для ноутбуков: перед выключением содержимое памяти сохраняется на диск. На настольных ПК обычно не требуется.'
        'Removes the annoying widgets in the bottom left of the Taskbar.' = 'Удаляет виджеты в левом нижнем углу панели задач.'
        'Bring back the old Start Menu layout from before the gradual rollout of the new one in 25H2. On newer versions of Windows !!THIS TWEAK WILL NOT WORK!!' = 'Возвращает прежний вид меню «Пуск» до внедрения нового варианта в 25H2. В более новых версиях Windows ЭТА НАСТРОЙКА МОЖЕТ НЕ РАБОТАТЬ.'
        'Will not display recommended Microsoft Store apps when searching for apps in the Start menu.' = 'Не показывает рекомендуемые приложения Microsoft Store при поиске в меню «Пуск».'
        'Disables Location Tracking.' = 'Отключает отслеживание местоположения.'
        'Sets some services to Manual startup and adjusts the SvcHostSplitThresholdInKB registry value to better match system memory, which can significantly reduce the number of svchost.exe processes.' = 'Переводит некоторые службы в ручной запуск и корректирует SvcHostSplitThresholdInKB с учётом объёма памяти, что может заметно уменьшить число процессов svchost.exe.'
        'Disables various annoyances like Brave Rewards, Leo AI, Crypto Wallet and VPN.' = 'Отключает навязчивые функции Brave: Rewards, Leo AI, Crypto Wallet, VPN и другие.'
        'Disables warnings shown when launching unsigned RDP files introduced with the latest Windows 10 and 11 updates.' = 'Отключает предупреждения при запуске неподписанных RDP-файлов, появившиеся в последних обновлениях Windows 10 и 11.'
        'Disables various telemetry options, popups, and other annoyances in Edge.' = 'Отключает телеметрию, всплывающие окна и другие навязчивые функции Edge.'
        'Stops promoted app installs and reduces app suggestions from Microsoft Store content.' = 'Запрещает установку продвигаемых приложений и уменьшает количество предложений из Microsoft Store.'
        'Disables Microsoft Telemetry.' = 'Отключает телеметрию Microsoft.'
        'Stops Windows from using your bandwidth to upload updates to other PCs on the internet or local network.' = 'Запрещает Windows использовать ваш интернет-канал для раздачи обновлений другим компьютерам в интернете или локальной сети.'
        'Uninstalls Microsoft Edge by creating dummy MicrosoftEdge.exe file in the legacy Edge folder. This tricks Windows into unlocking the official Edge uninstaller allowing for a system-level removal.' = 'Удаляет Microsoft Edge системным способом, разблокируя штатный деинсталлятор Windows с помощью файла-заглушки MicrosoftEdge.exe.'
        'Disables BitLocker.' = 'Отключает BitLocker.'
        'Essential for computers that are dual booting. Fixes the time sync with Linux systems.' = 'Полезно при двойной загрузке Windows и Linux: исправляет синхронизацию системного времени.'
        'Denies permission to remove OneDrive user files, then uses its own uninstaller to remove it and restores the original permission afterward.' = 'Защищает пользовательские файлы OneDrive от удаления, запускает штатный деинсталлятор и затем восстанавливает исходные разрешения.'
        'Removes the Home and Gallery from Explorer and sets This PC as default.' = 'Убирает «Главную» и «Галерею» из Проводника и делает «Этот компьютер» страницей по умолчанию.'
        'Sets the system preferences to performance. You can do this manually with sysdm.cpl as well.' = 'Настраивает визуальные параметры системы на максимальную производительность. То же можно сделать вручную через sysdm.cpl.'
        'Disables Windows Reserved Storage (7-10 GB held for updates/temp files). Recommended only on small drives. Re-enable before major Windows feature updates to avoid installation failures.' = 'Отключает зарезервированное хранилище Windows (7–10 ГБ для обновлений и временных файлов). Рекомендуется только для небольших дисков. Перед крупными обновлениями Windows включите его обратно.'
        'Creates a restore point at runtime in case a revert is needed from WinUtil modifications.' = 'Создаёт точку восстановления на случай необходимости отменить изменения WinUtil.'
        'Enables option to end task when right-clicking a program in the taskbar.' = 'Добавляет пункт завершения задачи в контекстное меню программы на панели задач.'
        'Storage Sense deletes temp files automatically.' = 'Контроль памяти автоматически удаляет временные файлы.'
        'Removes and disables all AI features/packages' = 'Удаляет и отключает все компоненты и пакеты ИИ.'
        'If enabled, WPBT allows your computer vendor to execute programs at boot time, such as anti-theft software, software drivers, as well as force install software without user consent. Poses potential security risk.' = 'WPBT позволяет производителю компьютера запускать программы при загрузке, включая драйверы и принудительно устанавливаемое ПО. Это может создавать риск безопасности.'
        'Prevents additional software from being installed when plugging in devices (e.g. Ads when plugging in a monitor). Poses potential security risk.' = 'Запрещает установку дополнительного ПО при подключении устройств, например рекламных приложений для мониторов.'
        'Blocks ALL Razer Software installations. The hardware works fine without any software.' = 'Блокирует установку всего ПО Razer. Оборудование продолжает работать без него.'
        'Blocks the Logi Download Assistant that Windows Update keeps reinstalling with Logitech device drivers. Logitech hardware keeps working without it.' = 'Блокирует Logi Download Assistant, который Windows Update повторно устанавливает вместе с драйверами Logitech. Устройства Logitech продолжат работать.'
        'Disables all Notifications INCLUDING Calendar.' = 'Отключает все уведомления, включая календарь.'
        'Reduces user interruptions by selectively blocking connections to Adobe''s activation and telemetry servers. Credit: Ruddernation-Designs' = 'Уменьшает количество отвлекающих сообщений, выборочно блокируя соединения с серверами активации и телеметрии Adobe. Автор: Ruddernation-Designs.'
        'Restores the classic context menu when right-clicking in File Explorer, replacing the simplified Windows 11 version.' = 'Возвращает классическое контекстное меню Проводника вместо упрощённого варианта Windows 11.'
        'Runs Disk Cleanup on Drive C: and removes old Windows Updates.' = 'Запускает очистку диска C: и удаляет старые файлы обновлений Windows.'
        'Erases TEMP Folders.' = 'Очищает папки TEMP.'
        'Setting the IPv4 preference can have latency and security benefits on private networks where IPv6 is not configured.' = 'Предпочтение IPv4 может снизить задержки и улучшить совместимость в частных сетях, где IPv6 не настроен.'
        'Teredo network tunneling is an IPv6 feature that can cause additional latency, but may cause problems with some games.' = 'Teredo — механизм туннелирования IPv6, который может увеличивать задержку; его отключение иногда вызывает проблемы в некоторых играх.'
        'Disables IPv6.' = 'Отключает IPv6.'
        'Disables all Microsoft Store apps from running in the background, which has to be done individually since Windows 11.' = 'Запрещает приложениям Microsoft Store работать в фоне. В Windows 11 это обычно приходится настраивать для каждого приложения отдельно.'
        'Windows Explorer automatically tries to guess the type of the folder based on its contents, slowing down the browsing experience. WARNING! Will disable File Explorer grouping.' = 'Проводник пытается автоматически определить тип папки по её содержимому, что может замедлять просмотр. ВНИМАНИЕ: группировка файлов в Проводнике будет отключена.'
        'Gives more information when you blue screen.' = 'Показывает больше технической информации при синем экране.'
        'Shows numeric battery percentage next to the battery icon in the system tray.' = 'Показывает процент заряда рядом со значком батареи в системном трее.'
        'Dark Mode for the system and applications.' = 'Включает тёмный режим для системы и приложений.'
        'Shows .file extensions in Explorer (.exe, .png, etc.)' = 'Показывает расширения файлов в Проводнике (.exe, .png и т. д.).'
        'Reveals hidden files in Explorer.' = 'Показывает скрытые файлы в Проводнике.'
        'Show detailed messages during startup/shutdown.' = 'Показывает подробные сообщения во время запуска и завершения работы Windows.'
        'This will ensure the new Outlook application is used.' = 'Включает использование новой версии приложения Outlook.'
        'If enabled, scrollbars will always be visible. If disabled, Windows will automatically hide scrollbars when not in use.' = 'Если включено, полосы прокрутки всегда видимы. Если отключено, Windows автоматически скрывает их, когда они не используются.'
        'Multiplane Overlay composes multiple image layers, which can sometimes cause issues with graphics cards. Changes to this preference are applied immediately.' = 'MPO объединяет несколько слоёв изображения и иногда вызывает проблемы с видеокартами. Изменение применяется сразу.'
        'Makes it so Cursor movement is affected by the speed of your physical mouse movements.' = 'Делает движение курсора зависимым от скорости физического перемещения мыши.'
        'Toggle the Num Lock key state when your computer starts.' = 'Переключает состояние Num Lock при запуске компьютера.'
        'Toggles the window snapping feature when dragging windows.' = 'Включает или отключает привязку окон при перетаскивании.'
        'Toggles network connectivity during S0 Sleep which is low power idle in modern laptops.' = 'Включает или отключает сетевое подключение в режиме сна S0 современных ноутбуков.'
        'Toggles between Modern Standby and S3 Sleep, which cuts off power to the CPU while continuing to refresh the memory.' = 'Переключает Modern Standby и сон S3, при котором питание процессора отключается, а память продолжает обновляться.'
        'Toggles the Home Page in the Windows Settings app.' = 'Включает или отключает главную страницу приложения «Параметры» Windows.'
        'Toggles Bing web search results in Windows Search.' = 'Включает или отключает результаты веб-поиска Bing в поиске Windows.'
        'Toggles the acrylic blur effect on login screen background.' = 'Включает или отключает акриловое размытие фона экрана входа.'
        'Skips the lock screen entirely and goes directly to the sign-in screen on boot and wake.' = 'Полностью пропускает экран блокировки и сразу показывает экран входа после загрузки или пробуждения.'
        'Toggles the recommendations section in the Start Menu. WARNING: This will also disable Windows Spotlight on your Lock Screen as a side effect.' = 'Включает или отключает рекомендации в меню «Пуск». ВНИМАНИЕ: при отключении также перестанет работать Windows Spotlight на экране блокировки.'
        'Toggles the Sticky Keys, which activate when clicking shift rapidly.' = 'Включает или отключает залипание клавиш, которое активируется быстрыми нажатиями Shift.'
        'Toggles the Taskbar alignment either to the left or center.' = 'Переключает выравнивание значков панели задач: слева или по центру.'
        'Toggles the Search Button on the Taskbar.' = 'Включает или отключает кнопку поиска на панели задач.'
        'Toggles the Task View Button in the Taskbar.' = 'Включает или отключает кнопку представления задач на панели задач.'
        'Toggles Windows prioritizes gaming performance by allocating system resources to games.' = 'Включает или отключает игровой режим Windows, отдающий системные ресурсы играм.'
        'Toggles support for file paths longer than 260 characters in Explorer.' = 'Включает или отключает поддержку путей длиннее 260 символов в Проводнике.'
        '.NET and .NET Framework is a developer platform made up of tools, programming languages, and libraries for building many different types of applications.' = '.NET и .NET Framework — платформа разработки, включающая инструменты, языки программирования и библиотеки для создания различных приложений.'
        'Replaces the default Windows NTP server (time.windows.com) with pool.ntp.org for improved time synchronization accuracy and reliability.' = 'Заменяет стандартный NTP-сервер Windows (time.windows.com) на pool.ntp.org для более точной и надёжной синхронизации времени.'
        'Hyper-V is a hardware virtualization product developed by Microsoft that allows users to create and manage virtual machines.' = 'Hyper-V — технология аппаратной виртуализации Microsoft для создания и управления виртуальными машинами.'
        'Enables legacy programs from previous versions of Windows.' = 'Включает устаревшие компоненты программ из предыдущих версий Windows.'
        'Windows Subsystem for Linux is an optional feature of Windows that allows Linux programs to run natively on Windows without the need for a separate virtual machine or dual booting.' = 'Подсистема Windows для Linux позволяет запускать Linux-программы в Windows без отдельной виртуальной машины или двойной загрузки.'
        'Network File System (NFS) is a mechanism for storing files on a network.' = 'Network File System (NFS) — механизм доступа и хранения файлов по сети.'
        'Enables daily registry backup, previously disabled by Microsoft in Windows 10 1803.' = 'Включает ежедневное резервное копирование реестра, которое Microsoft отключила по умолчанию начиная с Windows 10 1803.'
        'Enables Advanced Boot Options screen that lets you start Windows in advanced troubleshooting modes.' = 'Включает экран дополнительных вариантов загрузки Windows для расширенной диагностики и восстановления.'
        'Disables Advanced Boot Options screen that lets you start Windows in advanced troubleshooting modes.' = 'Отключает экран дополнительных вариантов загрузки Windows.'
        'Windows Sandbox is a lightweight virtual machine that provides a temporary desktop environment to safely run applications and programs in isolation.' = 'Песочница Windows — лёгкая виртуальная среда для безопасного запуска приложений в изоляции.'
    }

    $sync.WinUtilRussianPhraseTranslations = [ordered]@{
        ' - Set Time to UTC' = ' — установить время UTC'
        ' - Set to Best Performance' = ' — максимальная производительность'
        ' - Create' = ' — создать'
        ' - Disable And Remove' = ' — отключить и удалить'
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

        # Dynamic selected-app count.
        if ($trimmed -match '^Selected Apps:\s*(\d+)
    }

    # Localize presentation-only XAML. Internal TabItem headers and generic ToggleButton
    # Content stay in English because WinUtil uses some of those values as logic keys.
    if ($sync.preferences.language -eq 'ru-RU') {
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

        # Navigation captions are split into Underline + text in XAML, so translate
        # them explicitly without touching the hidden TabItem.Header logic keys.
        $navCaptions = @{
            'WPFTab1BT' = 'Установка'
            'WPFTab2BT' = 'Настройки'
            'WPFTab3BT' = 'Инструменты'
            'WPFTab4BT' = 'Обновления'
            'WPFTab5BT' = 'Создание Windows 11'
        }
        foreach ($navName in $navCaptions.Keys) {
            $navNode = $localizedXaml.SelectSingleNode("//*[@Name='$navName']")
            if ($null -ne $navNode) {
                $textBlock = $navNode.SelectSingleNode(".//*[local-name()='TextBlock']")
                if ($null -ne $textBlock) {
                    while ($textBlock.HasChildNodes) {
                        $textBlock.RemoveChild($textBlock.FirstChild) | Out-Null
                    }
                    $textBlock.AppendChild($localizedXaml.CreateTextNode($navCaptions[$navName])) | Out-Null
                }
            }
        }

        $script:inputXML = $localizedXaml.OuterXml
    } catch {
        Write-Warning "Russian localization could not process the XAML: $($_.Exception.Message)"
    }
    }

    # Do not mutate config Content/Description/Category values. Those objects are also
    # used by WinUtil logic. Dynamic controls translate only when their text is rendered.

    # Use Russian formatting for dates/numbers shown by .NET without changing command behavior.
    try {
        $culture = [System.Globalization.CultureInfo]::GetCultureInfo($sync.preferences.language)
        [System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture
    } catch {
        # Localization text still works even if culture setup is unavailable.
    }
}
) {
            return "Выбрано приложений: $($Matches[1])"
        }

        # App names are intentionally kept as product names; only the action is localized.
        if ($trimmed -match '^Install or Upgrade\s+(.+)
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
) {
            return "Установить или обновить $($Matches[1])"
        }
        if ($trimmed -match '^Uninstall\s+(.+)
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
) {
            return "Удалить $($Matches[1])"
        }
        if ($trimmed -match "^Open the application's website in your default browser(?:\\r?\\n|\r?\n)(.+)$") {
            return "Открыть сайт приложения в браузере`n$($Matches[1])"
        }

        # Translate only a recognized trailing action. The base text is translated as a
        # whole key when known; otherwise it stays as a product/technology name.
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
