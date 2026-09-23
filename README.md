# WinUtil RU

[![Latest Release](https://img.shields.io/github/v/release/TokhirjonYuldoshev/WinUtil-RU?display_name=tag&style=for-the-badge)](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

**WinUtil RU** — независимая русская сборка и локализация проекта [Chris Titus Tech's Windows Utility (WinUtil)](https://github.com/ChrisTitusTech/winutil).

> Оригинальный проект: **ChrisTitusTech/winutil**  
> Copyright исходного WinUtil: **CT Tech Group LLC**  
> WinUtil RU не является официальным русским релизом Chris Titus Tech.

---

## Версии

- **`russian` — WinUtil RU 26.09.23-RU** — проверенная пользовательская сборка.
- **`russian-dev` — WinUtil RU 26.09.23-RU-Beta** — сборка для разработки и тестирования.

Файл сборки в обоих каналах: `winutil-RU.ps1`.

---

## Быстрый запуск

> Запускайте PowerShell или Windows Terminal **от имени администратора**.

### WinUtil RU 26.09.23-RU (`russian`)

```powershell
$s = & curl.exe -fsSL --retry 3 --retry-delay 2 "https://raw.githubusercontent.com/TokhirjonYuldoshev/WinUtil-RU/russian/bootstrap.ps1"; if ($LASTEXITCODE -ne 0 -or -not $s) { throw "Не удалось скачать bootstrap.ps1" }; ($s -join "`n") | iex
```

Ветка `russian` — проверенная пользовательская версия **WinUtil RU 26.09.23-RU**.

### WinUtil RU 26.09.23-RU-Beta (`russian-dev`)

```powershell
$env:WINUTIL_RU_BRANCH='russian-dev'; $s = & curl.exe -fsSL --retry 3 --retry-delay 2 "https://raw.githubusercontent.com/TokhirjonYuldoshev/WinUtil-RU/russian-dev/bootstrap.ps1"; if ($LASTEXITCODE -ne 0 -or -not $s) { throw "Не удалось скачать bootstrap.ps1" }; ($s -join "`n") | iex
```

Старая переменная `WINDOWMANAGER_BRANCH` пока поддерживается для обратной совместимости.

---

## Как работает кэш

При первом запуске новой версии WinUtil RU:

```text
GitHub
  ↓
загрузка исходников
  ↓
preflight
  ↓
Compile.ps1
  ↓
winutil-RU.ps1
  ↓
SHA-256
  ↓
локальный кэш
```

Дальше, пока версия не изменилась, запускается проверенный локальный файл.

Технический путь кэша пока сохранён прежним для совместимости с уже созданными настройками:

```text
%LOCALAPPDATA%\YTY\WindowManager\Stable\
├─ winutil-RU.ps1
└─ release.json
```

При успешном обновлении старый `WindowManager-RU.ps1` заменяется новым `winutil-RU.ps1`.

Если GitHub временно недоступен, последняя проверенная локальная сборка может быть запущена после проверки SHA-256.

---

## Что добавляет WinUtil RU

- русский интерфейс с переключением **Русский / English**;
- отдельную локализацию в `config/localization_ru.json`;
- русские описания приложений;
- сохранение оригинальных внутренних ключей и команд WinUtil;
- режимы иконок **Авто / Только кэш / Отключить**;
- локальный кэш иконок;
- проверяемый SHA-256 кэш собранного `winutil-RU.ps1`;
- обработку временных ошибок источников WinGet;
- безопасный однократный retry для `Upgrade all`;
- preflight-проверки PowerShell, XAML, JSON, локализации и кодировок;
- CI для Windows PowerShell 5.1 и PowerShell 7;
- автоматическую сборку GitHub Releases.

---

## Ветки

| Ветка | Назначение |
|---|---|
| `main` | Чистая база, синхронизируемая с `ChrisTitusTech/winutil:main` |
| `russian-dev` | WinUtil RU 26.09.23-RU-Beta — разработка и тестирование |
| `russian` | WinUtil RU 26.09.23-RU — проверенная пользовательская версия |

Схема обновления:

```text
ChrisTitusTech/winutil:main
          ↓
         main
          ↓
     russian-dev
          ↓
      CI + тест
          ↓
       russian
          ↓
      GitHub Release
```

`russian` не обновляется автоматически без проверки.

---

## GitHub Release

Текущий опубликованный релиз пока имеет статус **Pre-release** и содержит:

```text
winutil-RU.ps1
release.json
LICENSE
```

Standalone `winutil-RU.ps1` также содержит исходное MIT-уведомление внутри файла, чтобы информация о лицензии сохранялась даже при отдельном скачивании PowerShell-скрипта.

---

## Оригинальный WinUtil

Основа проекта:

**Chris Titus Tech's Windows Utility (WinUtil)**  
https://github.com/ChrisTitusTech/winutil

Официальная документация:  
https://winutil.christitus.com/

Если ошибка относится к оригинальному WinUtil без изменений этого форка, используйте issue tracker оригинального проекта. Если проблема относится к русской локализации, WinUtil RU launcher, RU cache или RU release — создавайте issue здесь.

---

## Лицензия

WinUtil RU распространяется по **MIT License**, как и оригинальный WinUtil.

Исходный copyright и полный текст лицензии сохранены:

```text
Copyright (c) 2022 CT Tech Group LLC
```

Полный текст: [LICENSE](LICENSE).

MIT разрешает использование, копирование, изменение и распространение программного обеспечения при сохранении copyright notice и текста лицензии.

---

## Благодарность

Спасибо **Chris Titus Tech**, **CT Tech Group LLC** и всем участникам [оригинального WinUtil](https://github.com/ChrisTitusTech/winutil/graphs/contributors) за исходный проект.
