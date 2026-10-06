# WinUtil RU — технический аудит 26.09.29-RU

**Дата проверки:** 6 октября 2026 года.

**Репозиторий:** `TokhirjonYuldoshev/WinUtil-RU`.

Этот отчёт относится к опубликованному стабильному выпуску. Последующие правки документации в `russian` не меняют его исходный commit и assets.

## Основа выпуска

| Параметр | Проверенное значение |
| --- | --- |
| Русский выпуск | `26.09.29-RU`, latest, не draft и не prerelease |
| Официальный WinUtil | `26.09.29` |
| Exact official tag commit | `9419b2803e505b67a71b632205ce59132b52b41b` |
| Исходный commit русского выпуска | `adc172fe8d868ed00187afac65763bec45738136` |
| Версия локализации | `1.2.0` |
| PR обновления | [#3, merged](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/3) |
| Публикация | 6 октября 2026, 06:49:45 MSK |
| Release workflow | [Russian Release #39](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/37410763317), success |

Merge сохранён отдельным commit с исходной ancestry официального тега. Дерево исходников совпадает с проверенной на Windows сборкой: `22fdcc288b80423e05bb2bf50685d061ea6d6a6a`. Отдельная работа по Battle.net в выпуск не переносилась.

## Backend parity

[tools/Test-WinUtilRussianEdition.ps1](../tools/Test-WinUtilRussianEdition.ps1) проверяет опубликованный официальный release, exact tag commit и ancestry, затем сравнивает Git blob SHA защищённых путей:

- `functions/`;
- `scripts/`;
- `config/`;
- `xaml/`;
- `tools/autounattend.xml`;
- `LICENSE`.

Новые файлы внутри этих каталогов автоматически попадают в проверку. Изменения допустимы только в явно просмотренной allowlist.

Подтверждено на исходном commit выпуска и в release workflow:

| Проверка | Результат |
| --- | ---: |
| Защищённые upstream-пути | **130** |
| Точное совпадение Git blob | **117** |
| Просмотренные отличия UI/загрузчика | **13** |
| Разрешённые RU-добавления | **4** |
| Отсутствующие защищённые пути | **0** |
| Запрещённые изменения | **0** |
| Запрещённые добавления | **0** |

### Просмотренные отличия

1. `functions/private/Find-AppsByNameOrDescription.ps1`
2. `functions/private/Get-WinUtilEntryToolTip.ps1`
3. `functions/private/Initialize-InstallAppEntry.ps1`
4. `functions/private/Initialize-InstallCategoryAppList.ps1`
5. `functions/private/Reset-WPFCheckBoxes.ps1`
6. `functions/private/Show-CustomDialog.ps1`
7. `functions/private/Start-WinUtilUserInterface.ps1`
8. `functions/private/Step-WinUtilJob.ps1`
9. `functions/public/Invoke-WPFSelectedCheckboxesUpdate.ps1`
10. `functions/public/Invoke-WPFUIElements.ps1`
11. `scripts/main.ps1`
12. `scripts/start.ps1`
13. `xaml/inputXML.xaml`

Изменения относятся к переводу, выбору языка, About, оформлению и загрузчику форка. В `Start-WinUtilUserInterface.ps1` сохранён исходный UI lifecycle; в `Step-WinUtilJob.ps1` переводятся видимые `Text` и `ToolTip`. Механизмы установки, tweaks, DNS, AppX, Windows Update и ISO берутся из официального тега.

Разрешённые добавления:

- `config/applications_ru.json`;
- `config/localization_ru.json`;
- `functions/private/Initialize-WinUtilRussianLocalization.ps1`;
- `functions/private/Set-WinUtilLanguagePreference.ps1`.

## CI и проверка на Windows

| Проверка | Подтверждение |
| --- | --- |
| Compile & Check | [Run 37409621825](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/37409621825), success |
| Pester | [Run 37409621808](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/37409621808): **871 passed, 0 failed, 0 skipped** |
| PS Script Analyzer | Success в том же Unit Tests run |
| Russian Backend Parity | [Run 37409621838](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/37409621838), success |
| Generated-script guard | [Run 37409621844](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/37409621844), success |
| WPF готового stable | Release #39: **ru-RU → en-US → ru-RU passed** |
| Windows QA владельца | Сообщение «ВСЕ РАБОТАЕТ» после исправленной сборки; затем отдельное разрешение merge и публикации |

WPF проверяется настоящим `XamlReader.Load` без показа окна и выполнения системных операций. Ошибка второго visual child внутри ISO Border исправлена через единственный контейнер Grid; исходные имена и внутренние ISO-значения сохранены.

Успешный analyzer не означает отсутствие всех предупреждений: унаследованные convention warnings сохраняются. Сообщение владельца не перечисляет отдельные install/tweak/ISO операции; эти результаты не заявляются как независимо проверенные.

## Файлы опубликованного выпуска

Все три файла из release workflow сверены по размеру и SHA256 с GitHub release assets. Manifest подтверждает `Channel=stable`, `Prerelease=false`, точный `SourceCommit` и хеш скрипта. У скрипта сохранён UTF-8 BOM.

| Файл | Размер, байт | SHA256 |
| --- | ---: | --- |
| `winutil-RU.ps1` | 1229577 | `c9e7de14f3278294852e9a94a10340f3479d298dc7d1fe48e9cdf225357388d4` |
| `release.json` | 42841 | `9c6879cd9f34f6d3f3eea27bdc20a2784915c93da5e40c5ee48f21aeb2497af7` |
| `LICENSE` | 1095 | `61512a5ea110165ce800d00d2d85bbf1af0dc3ccc5d453ae8b5fe9ae20e6c5b5` |

[Страница стабильного выпуска](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/tag/26.09.29-RU).

## Защита ветки и выпуск

Активный ruleset **Protect russian stable** применяется к `russian`:

- запрещены удаление и force-push;
- перед merge обязателен PR;
- required checks: `strict-parity`, `Compile-and-Check`, `test`, `PS Script Analyzer`;
- required approvals: 0;
- разрешены `merge` и `squash`, bypass list пустой.

Для обновлений от официального тега используется **merge**, чтобы сохранить exact-tag ancestry.

[Russian Release](../.github/workflows/russian-release.yaml) запускается только вручную. Публикация требует `publish_stable=true`, успешных preflight/build/manifest проверок, Windows QA и явного подтверждения владельца. Существующий tag на другом SHA автоматически не заменяется и не удаляется.

## Границы проверки

Allowlist ограничивает пути изменений, но не доказывает семантическую безопасность каждой правки UI. Такие diff требуют просмотра. CI и WPF-проверка не заменяют проверку реальных системных операций на Windows.

Загрузчик следует ветке `russian`; конкретный опубликованный выпуск определяется tag, release manifest и assets. Подробности запуска: [README-RU.md](README-RU.md).

История прежних выпусков и аудитов сохранена в Git и Releases.
