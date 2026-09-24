# WinUtil RU

Русская локализация [WinUtil от Chris Titus Tech](https://github.com/ChrisTitusTech/winutil). Основа этой версии — исходный выпуск **26.08.19**. Установка программ, твики, AppX и работа с ISO используют исходный код WinUtil; дополнены отображение на русском и английском языках, выбор языка, заставка YTY и сведения «О программе».

Проект является независимым форком, а не официальным выпуском Chris Titus Tech. Автор оригинального WinUtil и его участники указаны в окне «О программе» и в файле [LICENSE](LICENSE).

## Запуск

Откройте PowerShell или Windows Terminal **от имени администратора** и выполните:

```powershell
irm https://raw.githubusercontent.com/TokhirjonYuldoshev/WinUtil-RU/russian/bootstrap.ps1 | iex
```

Также можно скачать [последний стабильный выпуск](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/latest), извлечь `winutil-RU.ps1` и запустить его в PowerShell с правами администратора:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\winutil-RU.ps1
```

Выбор языка находится в меню настроек. После изменения языка перезапустите программу. Русский выбран по умолчанию; английский можно вернуть в том же меню.

## Исходники и сборка

Рабочие исходники находятся в `functions/`, `config/`, `scripts/` и `xaml/`. Скрипт `winutil.ps1` создаёт `Compile.ps1`; вручную менять сгенерированный скрипт не нужно. Кандидат на выпуск проходит компиляцию, Pester и PSScriptAnalyzer в GitHub Actions. Ветка `main` хранит исходное состояние оригинального проекта, `russian` — стабильную русскую редакцию, а `russian-parity-26.08.19` — проверяемый исходный кандидат.

Оригинал: [ChrisTitusTech/winutil](https://github.com/ChrisTitusTech/winutil). Русская редакция: [TokhirjonYuldoshev/WinUtil-RU](https://github.com/TokhirjonYuldoshev/WinUtil-RU).
