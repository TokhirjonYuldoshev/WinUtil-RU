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

Опубликованный стабильный выпуск: **[26.09.29-RU.1](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/tag/26.09.29-RU.1)**. Основа — официальный **WinUtil 26.09.29**. Версия локализации — **1.2.1**.

**Важно различать релиз и исходники:** скачиваемый `winutil-RU.ps1` версии `26.09.29-RU.1` собран из commit `0f2739e7d7bc74939a8b196a4cbacd9f045dd7ef`. Загрузчик ниже использует ветку `russian` (на 09.10.2026 — `9f85c63d8c23ba707a120f060dfba5b957176981`), куда уже вошёл [PR #11](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/11) с исправлением запуска. **Это исправление пока не опубликовано как новый release asset**.

## Быстрый запуск

Откройте **PowerShell от имени администратора** и выполните:

```powershell
irm https://raw.githubusercontent.com/TokhirjonYuldoshev/WinUtil-RU/russian/bootstrap.ps1 | iex
```

Загрузчик проверяет локальную сборку и обновляет её из ветки `russian`, когда это требуется. Его исходный код доступен в [bootstrap.ps1](bootstrap.ps1).

Для запуска конкретного стабильного выпуска скачайте [winutil-RU.ps1](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/download/26.09.29-RU.1/winutil-RU.ps1), откройте PowerShell в папке с файлом от имени администратора и выполните:

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

Для `26.09.29-RU.1` прошли **1021 тест PowerShell 7 и 153 теста Windows PowerShell 5.1**, строгая проверка backend parity и загрузка WPF-интерфейса **RU → EN → RU**. Подробности и границы проверки: [технический аудит](docs/AUDIT-RU.md).

Для более нового merge commit ветки `russian` (`9f85c63d`) после PR #11 отдельно подтверждены [1031 тест PowerShell 7 и 163 теста Windows PowerShell 5.1](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/37943543891), 0 ошибок/пропусков, а также [Compile & Check](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/37943543781) и [строгая проверка parity](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/37943543870). Это **проверки ветки, а не опубликованного файла релиза**.

## Документация и участие

- [Руководство WinUtil RU](docs/README-RU.md) — запуск, язык, журналы и обновления.
- [Технический аудит](docs/AUDIT-RU.md) — основа выпуска, проверки и защита ветки.
- [Как участвовать](.github/CONTRIBUTING.md) — правила изменений и pull request.
- [Документация оригинального WinUtil](https://winutil.christitus.com/) — возможности исходной утилиты.

## Авторы и лицензия

Оригинальный WinUtil: **Chris Titus Tech и участники проекта**. Русская локализация: **[Tokhirjon Yuldoshev](https://github.com/TokhirjonYuldoshev)**.

Проект распространяется по исходной [MIT License](LICENSE). Уведомление **Copyright (c) 2022 CT Tech Group LLC** сохранено. WinUtil RU — самостоятельный форк с сохранением авторства оригинала.
