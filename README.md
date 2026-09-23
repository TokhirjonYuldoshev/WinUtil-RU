# WinUtil RU

[![WinUtil RU](https://img.shields.io/badge/WinUtil%20RU-26.09.23--RU-2ea44f?style=for-the-badge)](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

**WinUtil RU** — независимая русская сборка и локализация [Chris Titus Tech's Windows Utility (WinUtil)](https://github.com/ChrisTitusTech/winutil).

Проект предназначен для пользователей Windows, которым нужен привычный WinUtil с русским интерфейсом, русскими описаниями и отдельным стабильным каналом обновлений.

> **Важно:** WinUtil RU не является официальным русским релизом Chris Titus Tech.  
> Оригинальный проект: **ChrisTitusTech/winutil**.  
> Copyright исходного WinUtil: **CT Tech Group LLC**.

---

## Для чего нужен WinUtil RU

WinUtil RU объединяет в одном интерфейсе типовые задачи по настройке и обслуживанию Windows.

С его помощью можно:

- устанавливать и обновлять приложения через поддерживаемые пакетные менеджеры;
- удалять выбранные приложения;
- применять системные настройки и твики;
- управлять рядом параметров Windows Update;
- быстро открывать системные инструменты Windows;
- работать с дополнительными функциями WinUtil, включая инструменты для Windows 11;
- экспортировать диагностическую информацию о системе;
- пользоваться интерфейсом на русском или английском языке.

Проект старается сохранять внутреннюю совместимость с оригинальным WinUtil: внутренние ключи, команды и package ID не переводятся, а локализация применяется к пользовательскому интерфейсу и описаниям.

---

## Что добавлено именно в WinUtil RU

По сравнению с обычным upstream WinUtil в этой ветке добавлены:

- полноценный русский интерфейс с переключением **Русский / English**;
- русские названия и описания приложений;
- отдельный файл локализации `config/localization_ru.json`;
- отдельный файл русских описаний приложений;
- режимы загрузки иконок **Авто / Только кэш / Отключить**;
- локальный кэш иконок;
- стабильный локальный кэш собранного `winutil-RU.ps1`;
- проверка целостности кэша по SHA-256;
- проверка актуальности stable-кэша не только по версии, но и по commit;
- fallback на последний проверенный локальный кэш, если GitHub временно недоступен;
- дополнительные проверки PowerShell, XAML, JSON, локализации и кодировок;
- CI для Windows PowerShell 5.1 и PowerShell 7;
- отдельные Stable и Beta GitHub Releases;
- обработка части временных сетевых ошибок WinGet и безопасный retry для некоторых операций.

---

## Какую версию выбрать

| Ветка | Название | Для кого |
|---|---|---|
| `russian` | **WinUtil RU 26.09.23-RU** | обычное использование |
| `russian-dev` | **WinUtil RU 26.09.23-RU-Beta** | тестирование новых изменений |
| `main` | upstream-база | внутренняя синхронизация с оригинальным WinUtil |

Для повседневного использования рекомендуется **`russian`**.

`russian-dev` предназначена для проверки свежих изменений перед переносом в stable.

---

## Быстрый запуск

> Запускайте **PowerShell** или **Windows Terminal** от имени администратора.

### Stable — WinUtil RU 26.09.23-RU

```powershell
$s = & curl.exe -fsSL --retry 3 --retry-delay 2 "https://raw.githubusercontent.com/TokhirjonYuldoshev/WinUtil-RU/russian/bootstrap.ps1"; if ($LASTEXITCODE -ne 0 -or -not $s) { throw "Не удалось скачать bootstrap.ps1" }; ($s -join "`n") | iex
```

Это основной пользовательский канал.

### Beta — WinUtil RU 26.09.23-RU-Beta

```powershell
$env:WINUTIL_RU_BRANCH='russian-dev'; $s = & curl.exe -fsSL --retry 3 --retry-delay 2 "https://raw.githubusercontent.com/TokhirjonYuldoshev/WinUtil-RU/russian-dev/bootstrap.ps1"; if ($LASTEXITCODE -ne 0 -or -not $s) { throw "Не удалось скачать bootstrap.ps1" }; ($s -join "`n") | iex
```

Beta каждый раз получает актуальный код из `russian-dev`, запускает preflight-проверку, собирает WinUtil RU и затем открывает интерфейс.

Старая переменная `WINDOWMANAGER_BRANCH` пока поддерживается для обратной совместимости.

---

## Как работает автоматическое обновление Stable

При запуске `russian` bootstrap проверяет:

1. версию WinUtil RU в репозитории;
2. текущий commit ветки `russian`;
3. локальный `release.json`;
4. SHA-256 локального `winutil-RU.ps1`.

Если локальный кэш актуален и его SHA-256 совпадает с manifest, запускается локальный файл без повторной сборки.

Если версия или commit изменились, WinUtil RU:

```text
GitHub / russian
      ↓
скачивание исходников
      ↓
preflight
      ↓
Compile.ps1
      ↓
winutil-RU.ps1
      ↓
SHA-256
      ↓
новый локальный кэш
      ↓
запуск интерфейса
```

Если GitHub временно недоступен, но локальный кэш существует и проходит SHA-256-проверку, может быть запущена последняя проверенная локальная сборка.

---

## Где хранится локальный кэш

Для совместимости с предыдущими версиями технический путь пока сохранён прежним:

```text
%LOCALAPPDATA%\YTY\WindowManager\Stable\
├─ winutil-RU.ps1
└─ release.json
```

Также сохраняются прежние registry/env-названия, необходимые для обратной совместимости.

Это внутренние технические имена. Пользовательский бренд проекта — **WinUtil RU**.

---

## Как обновляется сам проект

Исходная схема обновления:

```text
ChrisTitusTech/winutil:main
          ↓
         main
          ↓
     russian-dev
          ↓
   CI + smoke-test
          ↓
       russian
          ↓
    Stable Release
```

- `main` синхронизируется с оригинальным `ChrisTitusTech/winutil:main`;
- новые upstream-изменения сначала попадают в `russian-dev`;
- `russian-dev` проходит CI и ручную проверку;
- только после проверки изменения продвигаются в `russian`;
- `russian` используется как стабильный пользовательский канал;
- upstream **ChrisTitusTech/winutil** этим проектом не изменяется.

---

## GitHub Releases

Используются два актуальных канала публикации.

### Stable

- **Название:** WinUtil RU 26.09.23-RU
- **Tag:** `26.09.23-RU`
- **Ветка:** `russian`
- **Статус:** обычный GitHub Release / Latest

### Beta

- **Название:** WinUtil RU 26.09.23-RU-Beta
- **Tag:** `26.09.23-RU-beta`
- **Ветка:** `russian-dev`
- **Статус:** Pre-release

Каждый актуальный release содержит:

```text
winutil-RU.ps1
release.json
LICENSE
```

GitHub дополнительно автоматически показывает архивы **Source code (zip)** и **Source code (tar.gz)** — это нормально и не является отдельными файлами сборки WinUtil RU.

Standalone `winutil-RU.ps1` содержит исходное MIT-уведомление, чтобы информация о лицензии сохранялась даже при отдельном скачивании скрипта.

---

## Безопасность и проверки

Перед переносом изменений в stable используются:

- preflight-проверки PowerShell/XAML/JSON/локализации;
- Compile & Check;
- Pester Unit Tests;
- PSScriptAnalyzer;
- проверка release manifest;
- проверка `SourceCommit`;
- проверка SHA-256 собранного `winutil-RU.ps1`;
- проверка состава release assets;
- Windows smoke-test перед продвижением значимых runtime-изменений.

Несмотря на эти проверки, WinUtil содержит функции, которые меняют системные настройки Windows. Перед применением незнакомых твиков рекомендуется понимать их назначение и иметь актуальную резервную копию важных данных.

---

## Оригинальный WinUtil

WinUtil RU основан на:

**Chris Titus Tech's Windows Utility (WinUtil)**  
https://github.com/ChrisTitusTech/winutil

Официальная документация оригинального проекта:  
https://winutil.christitus.com/

Если проблема относится к оригинальному WinUtil и воспроизводится без изменений WinUtil RU, используйте issue tracker оригинального проекта.

Если проблема относится к русской локализации, launcher, кэшу, Beta/Stable release или другим изменениям WinUtil RU — создавайте issue в этом репозитории.

---

## Лицензия

WinUtil RU распространяется по **MIT License**, как и оригинальный WinUtil.

Сохранены исходный copyright и полный текст лицензии:

```text
Copyright (c) 2022 CT Tech Group LLC
```

Полный текст находится в [LICENSE](LICENSE).

MIT разрешает использование, копирование, изменение и распространение программного обеспечения при сохранении copyright notice и текста лицензии.

---

## Благодарность

Спасибо **Chris Titus Tech**, **CT Tech Group LLC** и всем участникам [оригинального WinUtil](https://github.com/ChrisTitusTech/winutil/graphs/contributors) за исходный проект.

WinUtil RU — независимая русская локализация и не является официальным продуктом Chris Titus Tech.
