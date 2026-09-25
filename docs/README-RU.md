# WinUtil RU — руководство по русской редакции

Этот документ относится к [TokhirjonYuldoshev/WinUtil-RU](https://github.com/TokhirjonYuldoshev/WinUtil-RU). Унаследованный сайт в `docs/src/content/docs/` остаётся документацией **оригинального WinUtil**; его команды запуска относятся к оригинальному проекту.

## Что это за проект

[WinUtil](https://github.com/ChrisTitusTech/winutil) — PowerShell/WPF-утилита для Windows. Она объединяет установку программ, системные tweaks, DNS, AppX, Windows Update, системные инструменты и работу с ISO Windows 11.

**WinUtil RU** — независимый форк-локализация. Текущий опубликованный stable основан на официальном выпуске **26.08.19**, exact tag commit:

`086aecf4b7d165f9fd1822049435c418a48e7cba`

Цель проекта — не переписывать WinUtil, а предоставить русский пользовательский интерфейс поверх функциональности конкретного официального выпуска.

### Что разрешено менять

- видимый RU/EN текст интерфейса;
- переключатель **Русский / English**;
- YTY-заставку;
- окно **«О программе»** и сведения о форке при сохранении исходных авторов;
- локализационные таблицы;
- необходимый launcher/build/release glue;
- тесты и CI, которые проверяют локализацию и безопасность выпуска.

### Что не переводится и не переписывается

Внутренние имена WPF-элементов, config keys, package IDs, пути и значения реестра, аргументы команд, машинные состояния и sentinel values должны оставаться исходными. Названия продуктов вроде WinGet, Chrome, BitLocker и Windows 11 сохраняются как собственные названия.

Операционные механизмы установки, tweaks, DNS, AppX, Windows Update и ISO берутся из exact official release. Новые «улучшения backend» не должны попадать в stable под видом локализации.

## Что мы сделали

Текущая линия проекта приведена к модели **«оригинал + локализация»**.

| Область | Что сделано |
| --- | --- |
| База | Stable возвращён на exact official release `26.08.19`, а не на более новый upstream `main`. |
| Интерфейс | Переведены пользовательские вкладки, подписи, описания, основные статусы и диалоги. |
| Язык | Добавлены `Русский` и `English`; выбор меняет отображение, а не внутренние значения операций. |
| YTY | При старте показывается рамка YTY, имя Tokhirjon Yuldoshev и WINUTIL RU. |
| About | Сохранены Chris Titus Tech и исходные участники UI/runspace; форк/переводчик указан отдельно. |
| Backend | Повторный Git blob-аудит: 97 upstream-путей проверено, 0 отсутствует, 86 полностью совпадают, 11 имеют только разрешённые UI/launcher-отличия. |
| Конфиги | `applications.json`, `tweaks.json`, `appx.json`, `dns.json` побайтово равны official tag. |
| Ветки | Оставлены только две постоянные ветки: `main` и `russian`. |
| CI | Compile & Check, Pester и PSScriptAnalyzer запускаются для `main`/`russian` и соответствующих PR. |
| Release | Stable-публикация manual-only; обычный push не выпускает релиз. Существующий stable автоматически не удаляется и не заменяется. |
| Лицензия | Исходный MIT LICENSE и Copyright CT Tech Group LLC сохранены. |

Полный контрольный отчёт с SHA и известными рисками: [AUDIT-RU.md](AUDIT-RU.md).

## Текущий stable

Опубликованный stable: **26.08.19-RU**.

Он остаётся привязан к commit:

`f23c8b896885ba2fc46f05a64151a6a89d9aa024`

Последующие изменения документации и CI в ветке `russian` сами по себе **не переиздают** этот release.

## Запуск и смена языка

1. Откройте PowerShell или Windows Terminal **от имени администратора**.
2. Запустите загрузчик:

   ```powershell
   irm https://raw.githubusercontent.com/TokhirjonYuldoshev/WinUtil-RU/russian/bootstrap.ps1 | iex
   ```

3. Либо скачайте `winutil-RU.ps1` из [Releases](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/latest) и запустите локально:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\winutil-RU.ps1
   ```

Русский выбран по умолчанию. В меню с шестерёнкой можно выбрать **English** или **Русский**, после чего перезапустить приложение. Пункт **«О программе»** находится там же.

Выбор языка хранится для текущего пользователя Windows и должен менять только отображение.

## Журналы и проверка результата

Логи WinUtil находятся в:

`%LOCALAPPDATA%\winutil\logs\winutil_*.log`

Выбранный checkbox означает только выбранное действие. Для подтверждения результата операции нужно смотреть итоговое сообщение, фактическое состояние Windows и журнал.

## Ветки

Постоянных веток две:

- `main` — оригинальная линия upstream;
- `russian` — русская редакция.

Временную candidate-ветку допустимо создавать только для нового официального release и только **от exact official tag commit**. После завершения обновления её следует удалить. Старые dev-ветки в новую версию не сливаются.

Важно: upstream `main` может быть новее последнего официального release. Поэтому `main` не используется как автоматическая база stable.

## Как обновлять WinUtil RU после нового официального release

1. Проверить, что release у ChrisTitusTech/winutil не draft и не prerelease.
2. Получить tag ref и exact commit SHA; для annotated tag сначала разыменовать его до commit.
3. Создать временную candidate-ветку непосредственно от этого commit.
4. Перенести только локализацию, язык, YTY, About и необходимую build/launcher-инфраструктуру.
5. Не вливать старые dev-ветки целиком.
6. Сравнить операционные файлы кандидата с exact official tag по Git blob SHA/байтам. Любой необъяснённый backend mismatch — blocker.
7. Запустить Compile & Check, Pester и PSScriptAnalyzer.
8. Провести Windows QA: запуск, YTY, RU→EN→RU, About, вкладки, безопасная установка, согласованный tweak, AppX, Windows 11/ISO и повторный запуск/кэш.
9. Только после Windows QA и отдельного решения владельца обновлять stable.
10. Публикацию запускать вручную; автоматического выпуска от push нет.

## Важное ограничение текущей автоматизации

GitHub Actions проверяет сборку, Pester и PSScriptAnalyzer, но это не равно ручному Windows QA.

В текущем дереве `tools/Build-WinUtilRussianRelease.ps1` содержит поддержку preflight, однако исторический `tools/Test-WinUtilRussianEdition.ps1` отсутствует, а manual release workflow сейчас вызывает builder с `-SkipPreflight`. Поэтому перед следующим release нужен новый реально существующий candidate parity/preflight gate; старый файл не следует восстанавливать вслепую.

## Документация оригинала

Каталог `docs/src/content/docs/` унаследован от upstream и описывает оригинальный WinUtil. Он не является переведённым сайтом WinUtil RU.

## Авторы и лицензия

- Оригинальный проект: [ChrisTitusTech/winutil](https://github.com/ChrisTitusTech/winutil).
- Исходное уведомление: **Copyright (c) 2022 CT Tech Group LLC**.
- Русская локализация и оформление форка: [Tokhirjon Yuldoshev](https://github.com/TokhirjonYuldoshev/WinUtil-RU).
- Лицензия: [MIT](../LICENSE).

WinUtil RU не заявляет, что является официальным русским выпуском Chris Titus Tech, и не присваивает авторство исходного продукта.
