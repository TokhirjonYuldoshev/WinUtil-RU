# WinUtil RU — руководство

[Главная](../README.md) · [English](../README.en.md) · [Технический аудит](AUDIT-RU.md)

## Текущий выпуск

**[26.10.07-RU.1](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/tag/26.10.07-RU.1)** — текущий стабильный выпуск на официальном WinUtil **26.10.07**, локализация **1.2.1**.

**Происхождение сборки:** [PR #14](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/14) слит в `russian`, stable тег указывает на merge commit `1be881f8690aed8e9e4c230d4a0818fd8f311a95`. Исходный кандидат RC `f1f684ab43f75f075a9947fec2552cd0c615af45` прошёл Windows QA. SHA256 `winutil-RU.ps1` у stable и протестированной RC **совпадает**: `7399dd337f1194374ee5fb79e89ad32178626bfc939d8df7bdc551fa09cd48f8`. Загрузчик следует *текущей* ветке `russian`; для фиксированного выпуска скачайте стабильный asset.

[WinUtil RU](https://github.com/TokhirjonYuldoshev/WinUtil-RU) сохраняет операционные функции оригинала и добавляет русский интерфейс, выбор языка и окно «О программе» с исходными авторами.

| Состав выпуска | Назначение |
| --- | --- |
| `winutil-RU.ps1` | Готовая утилита |
| `release.json` | Версия, исходный commit и SHA256 |
| `LICENSE` | Исходная лицензия MIT |

## Запуск через загрузчик

Откройте PowerShell или Windows Terminal **от имени администратора**:

```powershell
irm https://raw.githubusercontent.com/TokhirjonYuldoshev/WinUtil-RU/russian/bootstrap.ps1 | iex
```

Загрузчик получает SHA ветки `russian`, затем скачивает launcher и архив **по этому точному commit**. При недоступном API запускается только имеющийся кэш с проверенным SHA256; без него запуск завершается ошибкой. Скачанная сборка проходит проверку синтаксиса и настоящую WPF-загрузку RU → EN → RU. Строгая Git parity выполняется в CI и release build, а не в ZIP-запуске.

Кэш обновляется после успешного завершения запуска. Каждая сборка хранится в отдельном каталоге `versions/<commit>-<hash>/`; атомарно меняется только `release.json`. Предыдущий manifest сохраняется как `release.previous.json`, а прежние скрипты остаются доступны. При сбое обновления bootstrap использует ранее проверенный путь. Старый плоский кэш поддерживается для перехода на новый формат.

Отмена запроса UAC завершает запуск; загрузчик не запрашивает повышение повторно для старого кэша. При техническом сбое обновления прежний проверенный кэш по-прежнему доступен.

Исходники загрузчика: [bootstrap.ps1](../bootstrap.ps1) и [run-russian.ps1](../run-russian.ps1).

## Запуск скачанного файла

Скачайте `winutil-RU.ps1` из [стабильного выпуска](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/latest). Откройте PowerShell в папке с файлом от имени администратора:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\winutil-RU.ps1
```

Так запускается конкретный скачанный выпуск. Загрузчик из предыдущего раздела следует текущим исходникам `russian`. Если раньше использовались временные `WINUTIL_RU_COMMIT`, `WINUTIL_RU_BRANCH` или `WINDOWMANAGER_BRANCH` для QA, очистите их в текущем PowerShell либо откройте новое окно, чтобы не запустить старую тестовую версию.

## Язык и «О программе»

Русский выбран по умолчанию. В меню с шестерёнкой выберите **Русский** или **English** и перезапустите приложение. Выбор сохраняется для текущего пользователя Windows.

Пункт **«О программе»** находится в том же меню. Он показывает версию, сведения о русском форке и авторство оригинального WinUtil.

Перевод меняет видимые подписи и описания. Внутренние имена WPF-элементов, ключи конфигов, package IDs и машинные значения сохраняются.

## Журналы

Журналы текущего сеанса:

```text
%LOCALAPPDATA%\winutil\logs\winutil_*.log
```

Консоль использует UTF-8 для читаемого русского вывода winget и записи в журнал текущего сеанса.

Строки `INFO` и `DEBUG` показывают ход работы. Для подтверждения операции проверяйте итоговое сообщение, журнал и фактический результат в Windows.

## Проверки актуального stable `26.10.07-RU.1`

- [RC release `26.10.07-RU.1-rc.1`](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/tag/26.10.07-RU.1-rc.1) создан автоматически после [полного CI](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/38020610471): `validate-automation`, `prepare`, `validate-candidate`, `publish-rc` — success.
- Pester в PowerShell 7: **1040 passed, 0 failed** в RC; обязательный этап Windows PowerShell 5.1, Script Analyzer, WPF **RU → EN → RU**, compile и строгая backend parity успешно пройдены.
- Владелец подтвердил работу опубликованной RC на Windows — [QA checkpoint](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/14#issuecomment-6093518281). Автоматический тест WPF не заменяет ручную проверку системных операций.
- [Защищённый stable promotion](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/38022376836) — success: повторная сборка, сравнение SHA256, точный merge PR #14, равенство Git-дерева кандидата/merge и публикация immutable release.
- Stable tag `26.10.07-RU.1` → `1be881f8690aed8e9e4c230d4a0818fd8f311a95`; SHA256 `winutil-RU.ps1` → `7399dd337f1194374ee5fb79e89ad32178626bfc939d8df7bdc551fa09cd48f8`.
- Старые версии и документы об их тестировании сохранены в [историческом разделе аудита](AUDIT-RU.md); их доказательства нельзя приписывать новому выпуску.

## Ветки и обновления

Основные линии:

| Ветка | Назначение |
| --- | --- |
| `main` | Исходная линия WinUtil |
| `russian` | Русская редакция |

Отдельные рабочие ветки используются для проверяемых изменений. `fix/battlenet-install-location` содержит самостоятельную работу по Battle.net и не включается в русскую редакцию. Завершённые ветки можно удалять после проверки, что работа сохранена.

Новый выпуск начинается от **точного официального тега**, с переносом локализации и необходимых изменений загрузчика. Затем проверяются backend parity, CI и работа на Windows. Публикация выполняется вручную после явного подтверждения владельца. Обычный push не публикует стабильный выпуск.

## Автоматическое наблюдение за оригинальным WinUtil

Read-only workflow [Upstream Release Watch](../.github/workflows/upstream-release-watch.yaml) имеет расписание **каждые шесть часов** по cron `13 */6 * * *` (UTC), также доступен `workflow_dispatch`. PR #13 со всей release-автоматизацией **слит 10.10.2026**. GitHub Actions может задержать или пропустить плановый запуск; наличие cron не гарантирует фактическое выполнение.

Сценарий читает [последний опубликованный стабильный релиз](https://github.com/ChrisTitusTech/winutil/releases/latest) (без draft/prerelease), SHA его тега, SHA официальной `main` и SHA нашей `main`. Сравнение отображается в [GitHub Actions](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions) как **Job Summary**, аннотация `warning`, если найдено расхождение со стабильным релизом, и JSON-отчёт с хранением 30 дней. **Это не автоматическая отправка сообщения по email или Telegram**.

Read-only монитор работает с `contents: read`, не делает push/merge и не запускает чужой код. **Отдельный** конвейер `Upstream RU Release Pipeline` автоматически обновляет `main` fast-forward на официальный stable, подготавливает RC и публикует только prerelease. Изменение `russian` и выпуск stable по-прежнему требуют отдельного Windows QA и запуска owner-only promotion.
### Полный конвейер: официальная версия → RC → stable по разрешению

[Описание автоматизации, ограничений, проверок и безопасного восстановления](AUTOMATION-RU.md). [Upstream RU Release Pipeline](../.github/workflows/upstream-ru-release-pipeline.yaml) запланирован каждые **15 минут** для проверки нового официального stable; при изменении официального тега выполняет только fast-forward нашей `main`, создаёт отдельную кандидатную ветку и Draft PR, запускает Windows QA/CI и после успешной проверки публикует **тестовый** GitHub prerelease. При конфликте файлов, расхождении истории или провале проверок **останавливается**, не меняя `russian` и не публикуя stable.

Продвижение проверенного RC в `russian` и стабильный выпуск выполняются **только** по отдельному ручному запуску [Promote Tested RU RC to Stable](../.github/workflows/ru-stable-promotion.yaml) с проверенным SHA256 и явным подтверждением владельца. Рекомендована дополнительная защита GitHub Environment required reviewers. Двухконтурная схема (read-only монитор каждые 6 часов + RC pipeline каждые 15 минут) находится в default `russian`; последний подтверждённый успешный полный RC workflow — [№ 38020610471](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/38020610471). Плановые запуски могут задерживаться либо пропускаться.

## Документация оригинала

[Сайт WinUtil](https://winutil.christitus.com/) и унаследованный каталог `docs/src/content/docs/` описывают оригинальную утилиту. Их команды запуска относятся к upstream.

## Авторы и лицензия

Оригинальный проект: [ChrisTitusTech/winutil](https://github.com/ChrisTitusTech/winutil). Русская локализация: [Tokhirjon Yuldoshev](https://github.com/TokhirjonYuldoshev).

Исходная [MIT License](../LICENSE) и **Copyright (c) 2022 CT Tech Group LLC** сохранены.

### Проверка отдельного исходного коммита

Для QA выставьте `WINUTIL_RU_COMMIT` в полный SHA и запустите ASCII-загрузчик `bootstrap.ps1` из того же коммита. Он не подменяет проверяемую сборку старым кэшем при ошибке. После проверки восстановите прежнее значение переменной. Не передавайте `run-russian.ps1` напрямую в `irm | iex`: его UTF-8 BOM предназначен для запуска файла в Windows PowerShell 5.1.

При нечитаемом выводе приложите screenshot и текущий `%LocalAppData%\winutil\logs\winutil_*.log`: правильный текст в transcript не гарантирует правильное декодирование вывода родительским процессом. Для незагрузившихся иконок используйте `tools/Test-WinUtilRussianIcons.ps1`; он читает режим и количество файлов кэша и проверяет три favicon URL без установки программ или изменения настроек. Его результат не подтверждает успешную загрузку картинки самой WPF.

### Изменения интерфейса в 26.09.29-RU.1

В опубликованной версии верхние вкладки подбирают ширину по тексту; компактный поиск и служебные кнопки находятся рядом с ними. При узком окне или большом масштабе панель переносится, сохраняя полные подписи. Это устраняет обрезание «Инструменты» при масштабе 75–200%. Добавлены встроенные изображения для Windows Terminal, EarTrumpet, GIMP, K-Lite, Total Commander, VLC и BlurAutoClicker. Для K-Lite используется логотип входящего в него MPC-HC с сайта Codec Guide. В режиме Disabled сохраняются буквенные заглушки; Auto и CacheOnly используют встроенный набор. В выпуске 20 встроенных иконок. Остальные favicon зависят от сети и кэша. Нижняя строка показывает русские завершения действий; она сохраняет последний результат при переключении вкладок.
