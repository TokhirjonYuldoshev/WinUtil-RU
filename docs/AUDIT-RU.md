# WinUtil RU — технический аудит

**Дата проверки:** 25 сентября 2026 года.  
**Репозиторий:** `TokhirjonYuldoshev/WinUtil-RU`.

Этот файл фиксирует проверенное состояние проекта. Контрольная точка кода до данного docs-only обновления документации: `russian` → `d64ad95c370c412b36d1873bb3eb56dcee7f8476`. Само обновление документации не меняет runtime/backend.

## Итог

Текущий проект соответствует принятой архитектуре **«точный официальный release + русская UI-локализация»** в проверенном объёме:

- последний официальный non-draft/non-prerelease release upstream: **26.08.19**;
- exact tag commit: `086aecf4b7d165f9fd1822049435c418a48e7cba`;
- опубликованный RU stable: **26.08.19-RU** → `f23c8b896885ba2fc46f05a64151a6a89d9aa024`;
- постоянные ветки: только `main` и `russian`;
- fork `main` и upstream `main` на момент аудита совпадают: `8e3998d9fd46e9a9996bba077baefb01425b7aeb`;
- stable release после docs/CI merge не перепубликовывался;
- исходный `LICENSE` совпадает с official tag по Git blob SHA.

## Ветки

На момент аудита GitHub API возвращает ровно две ветки:

| Ветка | SHA | Назначение |
| --- | --- | --- |
| `main` | `8e3998d9fd46e9a9996bba077baefb01425b7aeb` | Оригинальная линия upstream. |
| `russian` | `d64ad95c370c412b36d1873bb3eb56dcee7f8476` до этого docs-only commit | Русская локализация и безопасная release-инфраструктура. |

Удалённые исторические `russian-dev` и docs-candidate ветки не используются.

## Official release и published RU stable

Upstream release:

- tag: `26.08.19`;
- published: 19.08.2026 22:25 UTC;
- tag ref указывает непосредственно на commit `086aecf4b7d165f9fd1822049435c418a48e7cba`;
- поле release `target_commitish=main` не используется как база сравнения.

RU release:

- tag: `26.08.19-RU`;
- target commit: `f23c8b896885ba2fc46f05a64151a6a89d9aa024`;
- `draft=false`, `prerelease=false`;
- assets: `winutil-RU.ps1`, `release.json`, `LICENSE`.

Проверенные SHA-256 опубликованных assets:

| Asset | SHA-256 |
| --- | --- |
| `winutil-RU.ps1` | `5f3ff05dbaa800dcfab72b69169b21e55559ae4cce108c70f898022d89c41ab3` |
| `release.json` | `a02b760b9c322eac9ab2c3455f32d4ee76f163a9208a207eba8587c7f813d705` |
| `LICENSE` | `61512a5ea110165ce800d00d2d85bbf1af0dc3ccc5d453ae8b5fe9ae20e6c5b5` |

## Побайтовая проверка upstream operational scope

Сравнение выполнено по Git blob SHA между exact official tag commit `086aecf...` и `russian` code state `d64ad95...`.

Контрольный scope:

- все существовавшие в official tag файлы `functions/`;
- все существовавшие в official tag файлы `scripts/`;
- `config/applications.json`;
- `config/tweaks.json`;
- `config/appx.json`;
- `config/dns.json`.

Результат:

- проверено: **97** upstream-путей;
- отсутствует в RU: **0**;
- полностью совпадает по blob SHA: **86**;
- отличается: **11**.

Четыре основные операционные конфигурации совпадают полностью:

| Файл | Blob SHA official = RU |
| --- | --- |
| `config/applications.json` | `05a4b325232d7baffd1a9148f890011c2660e8e5` |
| `config/tweaks.json` | `a67e19b9b678c6f5c14e66c34b930a7bc99e8dfb` |
| `config/appx.json` | `7a3550e947fb7c6ed39112cf1c2ada12b045e619` |
| `config/dns.json` | `5c36a5f6edd382c4a7006d43efc1278a2ad7e081` |

`LICENSE` также совпадает с official tag: blob `be8a1a82bcf58357213f359d91e363ed8de33c11`.

## 11 отличающихся upstream-файлов

Все 11 patch были просмотрены отдельно:

1. `functions/private/Find-AppsByNameOrDescription.ps1`
2. `functions/private/Get-WinUtilEntryToolTip.ps1`
3. `functions/private/Initialize-InstallAppEntry.ps1`
4. `functions/private/Initialize-InstallCategoryAppList.ps1`
5. `functions/private/Reset-WPFCheckBoxes.ps1`
6. `functions/private/Set-WinUtilTweaksProgressIndicator.ps1`
7. `functions/private/Show-CustomDialog.ps1`
8. `functions/public/Invoke-WPFSelectedCheckboxesUpdate.ps1`
9. `functions/public/Invoke-WPFUIElements.ps1`
10. `scripts/main.ps1`
11. `scripts/start.ps1`

Проверенные отличия относятся к:

- переводу видимого текста;
- поиску по русским описаниям;
- сохранению исходной category identity при переведённой подписи;
- отображению локализованных ComboBox значений при сохранении исходного `Content`/ID;
- YTY-заставке;
- RU/EN language switch;
- About/атрибуции;
- self-elevation URL русского standalone release.

Во время этого аудита в этих patch не обнаружено добавления новой операции установки, tweak, DNS, AppX, Windows Update или ISO. Это не отменяет обязательный повторный review на каждом новом official tag.

## Полный diff относительно official tag

В `russian` ожидаемо присутствуют дополнительные localization/build/test/docs файлы и UI-правки. Это означает, что **всё дерево форка не обязано быть побайтово равно upstream**. Побайтовая гарантия относится к операционному backend и явно проверяемым upstream-путям; разрешённые UI/launcher/build отличия должны быть перечислены и просмотрены.

## CI

Для merge commit `d64ad95c370c412b36d1873bb3eb56dcee7f8476` GitHub Actions завершились успешно:

- Compile & Check — success;
- Unit Tests / Pester — success;
- PS Script Analyzer — success;
- generated `winutil.ps1` guard — success.

`Compile & Check` запускается на push в `main`/`russian` и PR в `main`/`russian`.

`Unit Tests` запускает Pester и PSScriptAnalyzer; PR triggers настроены для `main`/`russian`.

CI не заменяет Windows GUI QA.

## Stable release safety

`.github/workflows/russian-release.yaml`:

- запускается только вручную через `workflow_dispatch`;
- требует запуск из `russian`;
- публикация выполняется только при `publish_stable=true`;
- если release с тем же tag уже существует на другом commit, workflow останавливается и **не удаляет/не заменяет** его автоматически.

Поэтому обычный docs/code push в `russian` не должен публиковать stable.

## Известные ограничения и оставшиеся задачи

1. GitHub API сообщает `protected=false` для обеих текущих веток; repository rulesets на момент аудита пусты. Защита от случайного прямого push остаётся организационной, а не серверной.
2. `tools/Build-WinUtilRussianRelease.ps1` ожидает `tools/Test-WinUtilRussianEdition.ps1`, если не указан `-SkipPreflight`. Такого файла сейчас нет.
3. Manual release workflow использует `-SkipPreflight`. Перед следующим stable нужен новый реально существующий parity/preflight gate, а не слепое восстановление исторического скрипта.
4. Автоматического candidate-builder, который сам переносит локализацию на новый exact tag и доказывает backend parity, сейчас нет. Новый release должен пройти отдельную candidate-подготовку.
5. Branch `russian` может содержать docs/CI commits новее опубликованного release. Источником опубликованного stable служит release target SHA, а не просто HEAD `russian`.
6. Ручной Windows QA остаётся обязательным перед новым stable.

## Правило для следующего official release

Новая версия считается допустимой кандидатурой только если:

1. определён exact official release tag commit;
2. candidate создан от него, не от текущего upstream `main`;
3. старые dev-ветки целиком не вливались;
4. каждый операционный backend mismatch либо отсутствует, либо является blocker;
5. все разрешённые UI/helper отличия просмотрены;
6. compile/Pester/PSScriptAnalyzer прошли;
7. владелец провёл Windows QA;
8. владелец отдельно разрешил публикацию stable.

До выполнения этих пунктов stable release не публикуется.
