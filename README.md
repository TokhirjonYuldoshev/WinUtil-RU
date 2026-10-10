<div align="center">

# WinUtil RU

**Возможности оригинального WinUtil — с русским интерфейсом.**

[![Stable release](https://img.shields.io/github/v/release/TokhirjonYuldoshev/WinUtil-RU?label=stable&color=2563eb)](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/latest)
[![Backend parity](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/workflows/russian-parity-check.yaml/badge.svg?branch=russian)](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/workflows/russian-parity-check.yaml)
[![License: MIT](https://img.shields.io/badge/license-MIT-22c55e.svg)](LICENSE)
![Languages](https://img.shields.io/badge/interface-RU%20%2F%20EN-7c3aed.svg)

[**Скачать**](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/latest) · [**Руководство**](docs/README-RU.md) · [**English**](README.en.md)

</div>

---

**WinUtil RU** — независимая русская локализация [Chris Titus Tech's Windows Utility](https://github.com/ChrisTitusTech/winutil). Установка программ, настройки Windows и системные инструменты сохраняют логику официального выпуска; перевод и выбор языка относятся к интерфейсу.

Опубликованный стабильный выпуск: **[26.10.07-RU.1](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/tag/26.10.07-RU.1)**. Основа — официальный **WinUtil 26.10.07**. Версия локализации — **1.2.1**.

**Релиз и исходники:** стабильный тег `26.10.07-RU.1` соответствует merge commit `1be881f8690aed8e9e4c230d4a0818fd8f311a95`. Протестированный RC построен из `f1f684ab43f75f075a9947fec2552cd0c615af45`; SHA256 `winutil-RU.ps1` в RC и stable побитно совпадает (`7399dd337f1194374ee5fb79e89ad32178626bfc939d8df7bdc551fa09cd48f8`). Загрузчик ниже следует текущей ветке `russian`, которая может продвигаться после публикации; для воспроизводимой версии используйте файл из релиза.

<!-- WINUTIL-RU-DOCSYNC:START -->
Автоматически проверенные данные опубликованных релизов GitHub (не заменяют Windows QA):

- WinUtil-RU stable: [26.10.07-RU.1](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/tag/26.10.07-RU.1); commit 1be881f8690aed8e9e4c230d4a0818fd8f311a95.
- SHA256 опубликованного winutil-RU.ps1: 7399dd337f1194374ee5fb79e89ad32178626bfc939d8df7bdc551fa09cd48f8.
- Официальный stable WinUtil: [26.10.07](https://github.com/ChrisTitusTech/winutil/releases/tag/26.10.07); commit 07ccd8e2e755a706f31569808b31f5b77acad6a9.
- Основа RU: 26.10.07. Новый upstream stable требует отдельного RC и Windows QA.
<!-- WINUTIL-RU-DOCSYNC:END -->

## Быстрый запуск

Откройте **PowerShell от имени администратора** и выполните:

```powershell
irm https://raw.githubusercontent.com/TokhirjonYuldoshev/WinUtil-RU/russian/bootstrap.ps1 | iex
```

Загрузчик проверяет локальную сборку и обновляет её из ветки `russian`, когда это требуется. Его исходный код доступен в [bootstrap.ps1](bootstrap.ps1).

Для запуска конкретного стабильного выпуска скачайте [winutil-RU.ps1](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/download/26.10.07-RU.1/winutil-RU.ps1), откройте PowerShell в папке с файлом от имени администратора и выполните:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\winutil-RU.ps1
```

## Возможности

| Раздел | Что доступно |
| --- | --- |
| Программы | Поиск, установка, обновление и удаление через инструменты оригинального WinUtil |
| Настройки | Системные настройки Windows и предусмотренный оригиналом откат |
| DNS и AppX | Выбор DNS и управление приложениями Windows |
| Windows Update | Режимы обновления из официального выпуска |
| Windows 11 | Работа с ISO и инструментами создания установочного образа |
| Интерфейс | Русский и English, переведённые описания, статусы и окно «О программе» |

Язык выбирается в меню с шестерёнкой: **Русский / English**. После смены языка перезапустите приложение.

## Проверенная основа

Операционные файлы сравниваются с **точным официальным тегом**. Все отличия интерфейса и загрузчика проходят отдельную проверку. Перед стабильным выпуском обязательны CI, проверка на Windows и подтверждение владельца.

Для `26.10.07-RU.1` успешно завершились [автоматическая RC-сборка и Windows-валидация](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/38020610471), [проверка владельцем](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/14#issuecomment-6093518281) и [защищённое продвижение в stable](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/38022376836). Тесты PowerShell 7 в RC: **1040 passed, 0 failed**; проверки PowerShell 5.1, WPF RU → EN → RU, compile и backend parity также пройдены. GitHub подтверждает идентичный SHA256 программы RC и stable. Подробности: [технический аудит](docs/AUDIT-RU.md).

Автоматическая подготовка следующих RC описана в [руководстве конвейера](docs/AUTOMATION-RU.md). **Стабильные релизы не публикуются автоматически**: требуется Windows QA владельца и ручной защищённый workflow.

Для обновления метаданных текущего опубликованного выпуска предусмотрена [безопасная Docs Sync автоматизация](docs/AUTOMATION-RU.md): ежедневно и вручную она сверяет официальный и русский stable, SHA256 и закреплённую основу, после чего создаёт отдельный документационный PR при изменениях. Исторический аудит, backend и release она не переписывает; merge требует обычных проверок.

## Документация и участие

- [Руководство WinUtil RU](docs/README-RU.md) — запуск, язык, журналы и обновления.
- [Технический аудит](docs/AUDIT-RU.md) — основа выпуска, проверки и защита ветки.
- [Как участвовать](.github/CONTRIBUTING.md) — правила изменений и pull request.
- [Документация оригинального WinUtil](https://winutil.christitus.com/) — возможности исходной утилиты.

## Авторы и лицензия

Оригинальный WinUtil: **Chris Titus Tech и участники проекта**. Русская локализация: **[Tokhirjon Yuldoshev](https://github.com/TokhirjonYuldoshev)**.

Проект распространяется по исходной [MIT License](LICENSE). Уведомление **Copyright (c) 2022 CT Tech Group LLC** сохранено. WinUtil RU — самостоятельный форк с сохранением авторства оригинала.
