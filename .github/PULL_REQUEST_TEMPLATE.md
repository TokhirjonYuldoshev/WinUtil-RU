# WinUtil-RU · Pull Request

<!-- Fork contribution policy: .github/CONTRIBUTING.md, AGENTS.md and SPEC.md.
     Submit Russian UI/docs/fork infrastructure changes to the protected `russian` branch.
     Keep `main` aligned to the exact verified official WinUtil release.
     Do not commit generated `winutil.ps1` or edit generated docs in code-reference/features and tweaks. -->

## Type of Change

<!-- Keep these labels; the repository's label-pr workflow reads the checked items. -->
- [ ] New feature
- [ ] Bug fix
- [ ] Documentation update
- [ ] Refactor
- [ ] UI/UX improvement
- [ ] Hotfix

## Description / Описание

<!-- What changed, why, and how to reproduce or review it? Include screenshots for UI. -->

## Scope and upstream compatibility / Границы изменений

- [ ] Changed only fork UI, localization, launcher, CI or documentation; operational upstream backend remains unchanged.
- [ ] This PR intentionally touches operational files (explain exact upstream behavior and request separate owner review below).
- [ ] Attribution, MIT license and original authors are preserved.
- [ ] No generated `winutil.ps1`, unrelated formatting or unrelated changes.

<!-- Select the applicable options. If operational files changed, list them and link an upstream issue/PR:
     files / why / upstream release tag / impact / rollback. Never merge backend changes into `russian`
     without explicit owner approval and strict backend parity. -->

## Validation / Проверки

- [ ] Markdown links, commands, version numbers and `git diff --check` verified (for documentation changes).
- [ ] Applicable Pester, PSScriptAnalyzer, compile and strict official-tag backend parity checks pass.
- [ ] Windows WPF RU → EN → RU and manual QA performed when UI or runtime behavior changes.
- [ ] No automatic stable release. Production release requires a tested published RC, exact SHA256 and the separate owner-approved `ru-stable-promotion.yaml`.

<!-- Paste relevant run links and list any tests not run (with reason). -->

## Related issues / Задачи

<!-- Optional: link an existing issue, e.g. "Related to #123".
     Only write "Closes #123" when the PR should actually close that issue. -->
