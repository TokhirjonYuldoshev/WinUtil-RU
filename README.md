# WinUtil RU

[![Latest Release](https://img.shields.io/github/v/release/TokhirjonYuldoshev/WindowManager?display_name=tag&style=for-the-badge)](https://github.com/TokhirjonYuldoshev/WindowManager/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

**WinUtil RU** — независимая русская сборка и локализация проекта [Chris Titus Tech's Windows Utility (WinUtil)](https://github.com/ChrisTitusTech/winutil).

> Оригинальный проект: **ChrisTitusTech/winutil**  
> Copyright исходного WinUtil: **CT Tech Group LLC**  
> WinUtil RU не является официальным русским релизом Chris Titus Tech.

---

## Версия и название

WinUtil RU использует тот же формат номера версии, что и оригинальный WinUtil:

```text
yy.MM.dd
```

Для русской сборки добавляется суффикс `RU`, а GitHub Release пока публикуется как **Beta / Pre-release**.

Текущая схема:

```text
Программа: WinUtil RU
Версия сборки: 26.09.23-RU
Файл: winutil-RU.ps1
Tag: 26.09.23-RU-beta
Release: Release 26.09.23 RU Beta
Статус: Beta / Pre-release
```

Последний официальный релиз оригинального WinUtil может иметь более ранний номер, потому что WinUtil RU также синхронизируется с более свежими изменениями из `ChrisTitusTech/winutil:main`. Поэтому русская сборка использует оригинальный **формат** версии, но не выдаёт более новый код `main` за старый официальный релиз.

---

## Быстрый запуск

> Запускайте PowerShell или Windows Terminal **от имени администратора**.

### WinUtil RU Beta

```powershell
$s = & curl.exe -fsSL --retry 3 --retry-delay 2 "https://raw.githubusercontent.com/TokhirjonYuldoshev/WindowManager/russian/bootstrap.ps1"; if ($LASTEXITCODE -ne 0 -or -not $s) { throw "Не удалось скачать bootstrap.ps1" }; ($s -join "`n") | iex
```

Ветка `russian` — проверенная пользовательская ветка WinUtil RU. Пока проект находится в стадии Beta, соответствующие GitHub Releases помечаются как **Pre-release**.

### Версия для разработки

```powershell
$env:WINUTIL_RU_BRANCH='russian-dev'; $s = & curl.exe -fsSL --retry 3 --retry-delay 2 "https://raw.githubusercontent.com/TokhirjonYuldoshev/WindowManager/russian-dev/bootstrap.ps1"; if ($LASTEXITCODE -ne 0 -or -not $s) { throw "Не удалось скачать bootstrap.ps1" }; ($s -join "`n") | iex
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
- автоматическую сборку Beta-релизов.

---

## Ветки

| Ветка | Назначение |
|---|---|
| `main` | Чистая база, синхронизируемая с `ChrisTitusTech/winutil:main` |
| `russian-dev` | Новые изменения WinUtil RU и тестирование |
| `russian` | Проверенная пользовательская ветка WinUtil RU Beta |

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
 Release yy.MM.dd RU Beta
```

`russian` не обновляется автоматически без проверки.

---

## Beta-релизы

GitHub Release публикуется как **Pre-release** и содержит:

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
