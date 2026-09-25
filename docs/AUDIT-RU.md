# WinUtil RU — технический аудит

**Дата проверки:** 25 сентября 2026 года.  
**Репозиторий:** `TokhirjonYuldoshev/WinUtil-RU`.

Этот документ фиксирует состояние после внедрения strict exact-tag/backend parity gate. Контрольный успешный запуск gate выполнен на commit `3e408b374aad43cab359afb8ad485bbdfba7d2f3`; последующий docs-only commit не меняет protected runtime/backend.

## Итог

- последний официальный non-draft/non-prerelease release upstream: **26.08.19**;
- exact official tag commit: `086aecf4b7d165f9fd1822049435c418a48e7cba`;
- опубликованный RU stable: **26.08.19-RU** → `f23c8b896885ba2fc46f05a64151a6a89d9aa024`;
- постоянные ветки: только `main` и `russian`;
- fork `main` и upstream `main` на момент аудита совпадали: `8e3998d9fd46e9a9996bba077baefb01425b7aeb`;
- stable release не перепубликовывался при docs/CI изменениях;
- strict parity gate успешно проверен на Windows PowerShell.

## Что защищает strict parity

`tools/Test-WinUtilRussianEdition.ps1` не сравнивает кандидата с движущимся `main`. Он берёт базовую версию из `config/localization_ru.json`, проверяет официальный GitHub release по tag, требует `draft=false` и `prerelease=false`, затем через Git разыменовывает exact tag до commit. Annotated tags поддерживаются через peeled ref.

После этого gate требует, чтобы candidate был потомком exact official commit, и сравнивает Git blob SHA по protected tree:

- весь upstream `functions/`;
- весь upstream `scripts/`;
- весь upstream `config/`;
- весь upstream `xaml/`;
- `tools/autounattend.xml`;
- `LICENSE`.

Новые upstream-файлы внутри этих зон автоматически попадают в следующий parity check. Поэтому новый backend нельзя скрыть добавлением нового файла вместо изменения существующего.

## Контрольный результат gate

Успешный workflow `Russian Backend Parity` на commit `3e408b374aad43cab359afb8ad485bbdfba7d2f3` подтвердил:

| Проверка | Результат |
| --- | ---: |
| Official release | `26.08.19` |
| Official commit | `086aecf4b7d165f9fd1822049435c418a48e7cba` |
| Protected upstream paths | **104** |
| Exact Git blob match | **92** |
| Allowed modified upstream paths | **12** |
| Allowed RU-only additions | **4** |
| Missing protected paths | **0** |
| Forbidden modified paths | **0** |
| Forbidden additions | **0** |

### 12 reviewed modified upstream paths

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
12. `xaml/inputXML.xaml`

Они относятся к видимой локализации, поиску по русским описаниям, сохранению исходных внутренних значений при локализованном отображении, YTY/About, language switch и fork launcher/UI. Любой новый modified upstream path будет blocker, пока его отдельно не просмотрят и явно не добавят в allowlist.

### 4 разрешённых RU-only additions внутри protected roots

- `config/applications_ru.json`
- `config/localization_ru.json`
- `functions/private/Initialize-WinUtilRussianLocalization.ps1`
- `functions/private/Set-WinUtilLanguagePreference.ps1`

Любой другой новый файл внутри protected roots блокируется.

## Конфиги и LICENSE

На текущей базе exact official tag совпадают по blob SHA в том числе:

| Файл | Git blob SHA |
| --- | --- |
| `config/applications.json` | `05a4b325232d7baffd1a9148f890011c2660e8e5` |
| `config/tweaks.json` | `a67e19b9b678c6f5c14e66c34b930a7bc99e8dfb` |
| `config/appx.json` | `7a3550e947fb7c6ed39112cf1c2ada12b045e619` |
| `config/dns.json` | `5c36a5f6edd382c4a7006d43efc1278a2ad7e081` |
| `config/appnavigation.json` | `5ccf396b0535f8c5f0940d557887bae5643a1a98` |
| `config/feature.json` | `2c32d2992bd27015a5259340accad5d8e7471306` |
| `config/preset.json` | `852f0c7dfdfc5caf715b213926edd495be7a5988` |
| `config/themes.json` | `3d0cd9cf12073ff9249ef8062ebfaca8d7e10775` |
| `tools/autounattend.xml` | `d237be10991dedec9d1c7a42bb3cacde34efec8a` |
| `LICENSE` | `be8a1a82bcf58357213f359d91e363ed8de33c11` |

## CI

Для strict-gate code state `3e408b374aad43cab359afb8ad485bbdfba7d2f3` подтверждены:

- Russian Backend Parity — **success**;
- Compile & Check — **success**;
- Pester / Unit Tests — **success**;
- PS Script Analyzer — **success**;
- generated `winutil.ps1` guard — **success**.

`Russian Backend Parity` формирует JSON report как workflow artifact. CI не заменяет Windows GUI QA.

## Release safety

`.github/workflows/russian-release.yaml` остаётся manual-only через `workflow_dispatch`. Публикация требует `publish_stable=true`. Перед сборкой workflow отдельно запускает strict parity, а release builder запускает тот же preflight ещё раз.

Параметр `-SkipPreflight` из release builder удалён. Если stable release с тем же tag уже существует на другом SHA, workflow отказывается автоматически удалять или заменять его.

## Ветки

Постоянные ветки:

- `main` — оригинальная upstream-линия;
- `russian` — русская редакция.

Временная candidate-ветка разрешена только на время порта нового official release и должна начинаться от exact official tag commit. После завершения её можно удалить. Старые dev-ветки целиком не сливаются.

## Что strict gate не доказывает

Allowlist ограничивает **где** могут находиться отличия, но не может сам доказать семантическую безопасность новой правки внутри уже разрешённого UI/helper-файла. Поэтому при каждом новом official release diff всех allowlisted paths всё равно просматривается вручную.

Кроме того, автоматические проверки не заменяют ручной Windows QA: RU→EN→RU, About/YTY, вкладки, безопасная установка, согласованный tweak, AppX, Windows 11/ISO и повторный запуск/кэш.

## Оставшиеся организационные риски

1. На момент последней проверки обе ветки GitHub показывались как `protected=false`, repository rulesets были пусты. Strict gate существует в Actions, но серверная branch protection остаётся отдельной настройкой.
2. Автоматического механизма, который сам переносит перевод на новый official tag, нет. Это намеренно: candidate подготавливается отдельно, а gate проверяет уже подготовленный результат.
3. `russian` может содержать docs/CI commits новее опубликованного release. Источник published stable определяется release target SHA, а не HEAD ветки.

## Правило следующего official release

Новый stable допустим только когда:

1. определён published non-draft/non-prerelease official tag;
2. exact tag разыменован до commit;
3. candidate создан от этого commit, а не от движущегося `main`;
4. старые dev-ветки целиком не вливались;
5. `tools/Test-WinUtilRussianEdition.ps1` завершился успешно;
6. allowlisted UI/helper diff просмотрен;
7. Compile & Check, Pester и PSScriptAnalyzer прошли;
8. владелец провёл Windows QA;
9. владелец отдельно разрешил stable publication.

До этого stable не публикуется.
