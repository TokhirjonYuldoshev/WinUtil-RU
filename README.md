# WinUtil RU

Русская редакция [WinUtil от Chris Titus Tech](https://github.com/ChrisTitusTech/winutil), основанная на выпуске **26.08.19**. Это независимый форк: интерфейс переведён на русский с возможностью переключиться на английский; добавлены заставка YTY и сведения о переводе в окне «О программе». Основные действия WinUtil — установка программ, твики, AppX и работа с ISO — сохранены на основе оригинала.

## Запуск в Windows

Откройте PowerShell **от имени администратора** и выполните:

```powershell
irm https://raw.githubusercontent.com/TokhirjonYuldoshev/WinUtil-RU/russian/bootstrap.ps1 | iex
```

Перед запуском удалённого скрипта проверьте адрес и его содержимое. Альтернатива: скачайте `winutil-RU.ps1` из [последнего стабильного выпуска](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/latest) и запустите файл с правами администратора.

Инструкция по запуску, обновлениям, отличиям от оригинала и проверке будущих выпусков: **[документация WinUtil RU](docs/README-RU.md)**. Исходники проекта: [`russian`](https://github.com/TokhirjonYuldoshev/WinUtil-RU/tree/russian); оригинал: [ChrisTitusTech/winutil](https://github.com/ChrisTitusTech/winutil).

## Авторство и лицензия

Оригинальный WinUtil создан Chris Titus Tech и участниками проекта; авторское уведомление оригинала — **Copyright (c) 2022 CT Tech Group LLC**. Русская локализация и оформление YTY подготовлены [Tokhirjon Yuldoshev](https://github.com/TokhirjonYuldoshev/WinUtil-RU). Форк распространяется на условиях [лицензии MIT оригинального проекта](LICENSE); уведомление об авторских правах и текст лицензии сохраняются при распространении копий или существенных частей программы.
