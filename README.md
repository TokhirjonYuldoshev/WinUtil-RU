# WindowManager RU

[![Latest Release](https://img.shields.io/github/v/release/TokhirjonYuldoshev/WindowManager?display_name=tag&style=for-the-badge)](https://github.com/TokhirjonYuldoshev/WindowManager/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

**WindowManager RU** — русскоязычная версия и независимый форк проекта [Chris Titus Tech's Windows Utility (WinUtil)](https://github.com/ChrisTitusTech/winutil).

Проект сохраняет функциональность оригинального WinUtil и добавляет русскую локализацию интерфейса, переключение языка, улучшенный запуск stable/dev, локальный кэш стабильной сборки и дополнительные проверки совместимости.

> Оригинальный проект: **ChrisTitusTech/winutil**  
> Авторские права на исходный WinUtil принадлежат **CT Tech Group LLC**.  
> Этот форк развивается независимо и не является официальным русским релизом Chris Titus Tech.

---

## Быстрый запуск

> WindowManager изменяет системные параметры Windows, поэтому PowerShell или Terminal нужно запускать **от имени администратора**.

### Стабильная русская версия

Открой PowerShell от имени администратора и выполни:

```powershell
$env:WINDOWMANAGER_BRANCH='russian'; $s = & curl.exe -fsSL --retry 3 --retry-delay 2 "https://raw.githubusercontent.com/TokhirjonYuldoshev/WindowManager/russian/bootstrap.ps1"; if ($LASTEXITCODE -ne 0 -or -not $s) { throw "Не удалось скачать bootstrap.ps1" }; ($s -join "`n") | iex
```

Стабильная ветка: `russian`.

При первом запуске WindowManager загружает и проверяет исходники, собирает готовый `WindowManager-RU.ps1` и сохраняет его локально.

Следующие запуски используют проверенный локальный кэш, если версия на GitHub не изменилась.

Локальный stable-кэш:

```text
%LOCALAPPDATA%\YTY\WindowManager\Stable\
├─ WindowManager-RU.ps1
└─ release.json
```

Если появилась новая стабильная версия, кэш автоматически обновляется. Если GitHub временно недоступен, последняя локальная версия может быть запущена после проверки SHA-256.

### Версия для разработки

```powershell
$env:WINDOWMANAGER_BRANCH='russian-dev'; $s = & curl.exe -fsSL --retry 3 --retry-delay 2 "https://raw.githubusercontent.com/TokhirjonYuldoshev/WindowManager/russian-dev/bootstrap.ps1"; if ($LASTEXITCODE -ne 0 -or -not $s) { throw "Не удалось скачать bootstrap.ps1" }; ($s -join "`n") | iex
```

`russian-dev` предназначена для проверки новых изменений. Она загружает свежие исходники, выполняет preflight и компиляцию перед запуском.

---

## Что добавлено в русской версии

- русский интерфейс с возможностью переключиться обратно на English;
- отдельный файл локализации `config/localization_ru.json`;
- русские описания каталога приложений;
- сохранение внутренних ключей WinUtil на английском для совместимости с оригинальной логикой;
- режимы иконок: **Авто**, **Только кэш**, **Отключить**;
- локальный кэш иконок;
- стабильный локальный кэш собранного WindowManager;
- SHA-256-проверка стабильного кэша;
- обработка временных ошибок источников WinGet и один безопасный повтор для `Upgrade all`;
- preflight-проверки PowerShell, JSON, XAML, локализации и кодировок;
- CI-проверки Windows PowerShell 5.1 и PowerShell 7;
- автоматическая сборка русских GitHub Releases.

---

## Ветки проекта

| Ветка | Назначение |
|---|---|
| `main` | Чистая база, синхронизируемая с `ChrisTitusTech/winutil:main` |
| `russian-dev` | Разработка и тестирование русской версии |
| `russian` | Стабильная русская версия |

Схема обновления:

```text
ChrisTitusTech/winutil:main
          ↓
         main
          ↓
     russian-dev
          ↓
   тестирование / CI
          ↓
       russian
          ↓
   ru-vX.Y.Z Release
```

Новые изменения оригинального WinUtil сначала попадают в `main`, затем проходят через `russian-dev`. Стабильная `russian` не обновляется автоматически без проверки.

---

## Релизы

Последняя стабильная версия публикуется в разделе [Releases](https://github.com/TokhirjonYuldoshev/WindowManager/releases/latest).

Релиз содержит:

```text
WindowManager-RU.ps1
release.json
```

`release.json` содержит версию, SHA-256 и данные сборки.

---

## Оригинальный проект

WindowManager RU основан на:

**Chris Titus Tech's Windows Utility (WinUtil)**  
https://github.com/ChrisTitusTech/winutil

Официальная документация оригинального проекта:  
https://winutil.christitus.com/

Если вопрос относится к оригинальному WinUtil без изменений этого форка, используйте документацию и issue tracker оригинального проекта.

Если проблема относится именно к русской локализации или функциям WindowManager RU, создавайте issue в этом репозитории.

---

## Лицензия

Проект распространяется по лицензии **MIT**, как и оригинальный WinUtil.

Исходное уведомление об авторском праве и полный текст лицензии сохранены в файле [LICENSE](LICENSE):

```text
Copyright (c) 2022 CT Tech Group LLC
```

MIT License разрешает использование, копирование, изменение, публикацию и распространение программного обеспечения при сохранении уведомления об авторском праве и текста лицензии.

Изменения и русская локализация этого форка не означают одобрение или официальную поддержку со стороны Chris Titus Tech или CT Tech Group LLC.

---

## Благодарность

Спасибо **Chris Titus Tech**, **CT Tech Group LLC** и всем участникам [оригинального WinUtil](https://github.com/ChrisTitusTech/winutil/graphs/contributors) за разработку и поддержку проекта, на котором основан WindowManager RU.
