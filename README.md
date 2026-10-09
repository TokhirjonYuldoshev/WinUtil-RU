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

Текущий стабильный выпуск: **[26.09.29-RU.1](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/tag/26.09.29-RU.1)**. Основа — официальный **WinUtil 26.09.29**. Версия локализации — **1.2.1**.

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

## Документация и участие

- [Руководство WinUtil RU](docs/README-RU.md) — запуск, язык, журналы и обновления.
- [Технический аудит](docs/AUDIT-RU.md) — основа выпуска, проверки и защита ветки.
- [Как участвовать](.github/CONTRIBUTING.md) — правила изменений и pull request.
- [Документация оригинального WinUtil](https://winutil.christitus.com/) — возможности исходной утилиты.

## Авторы и лицензия

Оригинальный WinUtil: **Chris Titus Tech и участники проекта**. Русская локализация: **[Tokhirjon Yuldoshev](https://github.com/TokhirjonYuldoshev)**.

Проект распространяется по исходной [MIT License](LICENSE). Уведомление **Copyright (c) 2022 CT Tech Group LLC** сохранено. WinUtil RU — самостоятельный форк с сохранением авторства оригинала.
