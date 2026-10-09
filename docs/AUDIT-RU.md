# WinUtil RU — технический аудит 26.09.29-RU.1

**Дата проверки:** 9 октября 2026 года. Предыдущий аудит сохранён ниже.

## Текущий стабильный выпуск

| Параметр | Значение |
| --- | --- |
| Выпуск | [26.09.29-RU.1](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/tag/26.09.29-RU.1), latest stable, не draft и не prerelease |
| Официальная основа | 26.09.29, commit `9419b2803e505b67a71b632205ce59132b52b41b` |
| Локализация | 1.2.1 |
| SourceCommit и Git tag | `0f2739e7d7bc74939a8b196a4cbacd9f045dd7ef` |
| Дерево исходников | `8858c123a72dda7bb5d3394d8d8e19aa47d921ae` |
| Merge | [PR №9](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/9), отдельный merge commit с сохранённой ancestry |
| Публикация | 09.10.2026, 13:06:30 MSK |
| Windows release build | [Russian Release №40](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/37915419210), success |

Выпуск включает исправленный UTF-8 вывод загрузчика, 20 встроенных иконок, русские окончания динамических статусов и компактный поиск рядом с вкладками. Вкладки автоматически подбирают размер по тексту и переносятся при недостаточной ширине. Операционные установки, tweaks, DNS, AppX, Updates и ISO сохранены; отдельная ветка Battle.net не включена.

## Проверки текущего выпуска

- [Unit Tests после merge](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/37850934062): **1021 passed PowerShell 7 + 153 passed Windows PowerShell 5.1**, 0 failed/skipped/inconclusive/notrun; PS Script Analyzer success с сохранёнными convention warnings.
- [Compile & Check](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/37850934033): настоящий WPF RU→EN→RU, все 20 встроенных изображений декодируются без сети. Dark/Light × масштабы75/100/150/200% × ширины800/1280/1920 WPF units; полные подписи, границы header controls, ограниченная ширина поиска и Close у правого края проверены.
- [Backend parity](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/37850934158) и release preflight: **117 exact blobs /13 reviewed UI-launcher modifications /6 allowed additions /0 forbidden differences**. При404 live metadata официального26.09.29 использована уже закреплённая historical stable запись с неизменными exact commit/tree. Ошибки авторизации/сети/сервера не разрешают fallback.
- Release №40 повторно проверил committed build inputs, WPF, stable manifest (`Channel=stable`, `Prerelease=false`, точный `SourceCommit`) и SHA256. Actual Git tag проверен независимо от mutable `target_commitish` metadata; non-forced creation и `--verify-tag` сохраняют прежние теги.
- Владелец сообщил, что предыдущая сборка работает хорошо, и явно разрешил merge/публикацию. Для final compact header отдельная ручная QA точного commit на устройстве/DPI не зафиксирована. Автоматизированное непоказанное WPF-окно не доказывает работу всех сетевых favicon и системных операций.

## Опубликованные файлы

Все три опубликованных файла независимо скачаны; рассчитанные размеры и SHA256 совпадают с GitHub Release API. Manifest подтверждает stable, версию, SourceCommit и хеш/размер скрипта. Хеш скрипта совпадает с Windows build и проверенным PR артефактом; UTF-8 BOM и исходное MIT notice сохранены.

| Файл | Размер, байт | SHA256 |
| --- | ---: | --- |
| `LICENSE` | 1095 | `61512a5ea110165ce800d00d2d85bbf1af0dc3ccc5d453ae8b5fe9ae20e6c5b5` |
| `release.json` | 42843 | `0e595c6d530a0b8807c2fbc398a1616f6414805c8324c7df2f8c19dcbae3a408` |
| `winutil-RU.ps1` | 1526879 | `aefb32c91f49dee365730229de4dbbb3c1afe3b6c59f703b81183298d13d1e78` |

Предыдущий stable26.09.29-RU и его tag/assets сохранены. Загрузчик следует текущей ветке `russian`; конкретный выпуск определяется tag, manifest и assets. [Руководство](README-RU.md).

---

## Архив: технический аудит 26.09.29-RU

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

## Исправления загрузчика и CI после полного аудита

Исходные файлы опубликованного `26.09.29-RU` и его tag/assets сохранены. После полного аудита исправлены:

- exact-SHA загрузка launcher и исходного архива;
- отдельные immutable версии кэша, атомарный manifest и сохранение предыдущего файла при ошибке обновления;
- проверка синтаксиса и WPF в source launcher; описание отделяет её от Git parity в CI;
- отказ Analyzer при severity Error без скрытия convention warnings;
- WPF build для любого PR в `russian`, независимо от имени исходной ветки;
- upstream-only guards для унаследованной публикации и автоматического управления;
- CODEOWNERS и Security Policy форка, owner-only triage вне upstream.

Поведенческие тесты `pester/russian-launcher.Tests.ps1` проверяют обновление кэша, сбои записи, восстановление предыдущего manifest, offline запуск, SHA pinning и отказ Analyzer. Установки программ, реестр Windows и ISO в этих тестах не выполняются. Подтверждённые результаты CI записываются в PR и CURRENT; описание исправлений не является заявлением о новой ручной Windows QA.
