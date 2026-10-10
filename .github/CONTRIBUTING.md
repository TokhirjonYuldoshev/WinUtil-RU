# Участие в WinUtil RU / Contributing

Этот документ относится к **[TokhirjonYuldoshev/WinUtil-RU](https://github.com/TokhirjonYuldoshev/WinUtil-RU)**. Правила работы с оригинальным WinUtil находятся в [upstream](https://github.com/ChrisTitusTech/winutil/blob/main/.github/CONTRIBUTING.md).

**Состояние GitHub на 10.10.2026:** Issues и Discussions у этого форка отключены. Для конкретного безопасного исправления используйте PR по правилам ниже; не публикуйте уязвимости или секретные журналы в открытых PR. Порядок сообщения об уязвимости указан в [SECURITY.md](SECURITY.md).

## Русская редакция

- Изменения локализации, документации и инфраструктуры форка направляйте через PR в **`russian`**.
- `main` сохраняет исходную upstream-линию.
- Один PR — одна понятная задача. Опишите проблему, итоговое поведение и выполненные проверки.
- Операционную логику установки, tweaks, DNS, AppX, Windows Update и ISO сохраняйте из точного официального тега.
- Переводите видимый текст; внутренние ключи, package IDs, имена WPF-контролов и машинные значения сохраняйте.
- Сохраняйте авторство оригинального WinUtil и исходную MIT License.
- Отдельные исправления backend рассматривайте отдельно от русской локализации.

Перед изменениями прочитайте [AGENTS.md](../AGENTS.md) и [SPEC.md](../SPEC.md). Для кода выполните соответствующие Pester-проверки и [strict parity](../tools/Test-WinUtilRussianEdition.ps1). Для правок только Markdown проверьте факты, команды, ссылки и `git diff --check`.

`winutil.ps1` — результат сборки. Его нельзя редактировать или коммитить как исходник.

Стабильный выпуск публикуется вручную после CI, проверки на Windows и отдельного подтверждения владельца. Временные рабочие ветки удаляются после завершения и проверки, что их работа сохранена.

## English

**Repository setting (2026-10-10):** Issues and Discussions are disabled for this fork. Submit an actionable, non-sensitive fix as a PR under the rules below. Never disclose security exploits or secrets in public PRs; follow [SECURITY.md](SECURITY.md).

- Target **`russian`** for localization, documentation and fork infrastructure. Keep `main` aligned with upstream.
- Keep each PR focused. Explain the problem, resulting behavior and validation.
- Preserve operational behavior from the exact official release tag, upstream attribution and the MIT License.
- Translate visible text while retaining internal keys, package IDs, control names and machine values.
- Handle backend fixes separately from the Russian localization.

Read [AGENTS.md](../AGENTS.md) and [SPEC.md](../SPEC.md) before editing. Run relevant tests and strict parity for code changes; check facts, commands, links and `git diff --check` for Markdown-only edits.

Do not edit or commit the generated `winutil.ps1`. Stable publication requires CI, Windows QA and explicit owner approval. Remove completed working branches only after confirming that their work is preserved.
