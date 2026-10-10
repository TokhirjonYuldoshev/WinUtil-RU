# WinUtil RU — производственный аудит 26.10.07-RU.1

**Срез GitHub: 10 октября 2026 года.** Данные получены из live GitHub Release API, refs, PR, Actions и исходных файлов. Предыдущие аудиты ниже сохранены как **исторические**, их проверки не приписываются новой версии.

## Итог повторного аудита репозитория (срез 10.10.2026)

**Границы проверки:** факты ниже подтверждены GitHub REST API, деревом `russian`, правилами ветки и журналами Actions. Это аудит **репозитория и release-процесса**, а не испытание каждой системной операции на пользовательской Windows-машине. Текущий `russian` может измениться после слияния очередного PR; указанный SHA — контрольная точка до документационных изменений.

| Область | Результат / контроль |
| --- | --- |
| Дерево `russian` | `533136d39d3b4c30463a2d6d616ba3cd3d1d01a3` до этого docs PR; GitHub tree API: 456 объектов, без усечения |
| Официальный upstream | [latest stable `26.10.07`](https://github.com/ChrisTitusTech/winutil/releases/tag/26.10.07); `main` форка → `07ccd8e2e755a706f31569808b31f5b77acad6a9` |
| Ветки | Ровно три: защищённая `russian`, официальная `main`, независимая `fix/battlenet-install-location`. Последняя сохранена по распоряжению владельца |
| PR | Открытых PR не было; документация и release-safety от [#16](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/16)/[#17](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/17) уже слиты |
| Защита `russian` | Активный ruleset `Protect russian stable`: запрет удаления / non-fast-forward, PR-only; required contexts: `strict-parity`, `Compile-and-Check`, `test`, `PS Script Analyzer` |
| Workflows | 18 YAML; семь upstream-only workflows отключены для форка через подтверждённый `disabled_manually`. RC schedule и read-only watch проверены фактическими запусками |
| Публикация | [stable `26.10.07-RU.1`](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/tag/26.10.07-RU.1) и prerelease имеют одинаковый SHA256 `7399dd337f1194374ee5fb79e89ad32178626bfc939d8df7bdc551fa09cd48f8`; stable tag остаётся на `1be881f8690aed8e9e4c230d4a0818fd8f311a95` |
| CI | После PR #17: [Unit Tests](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/38029039477), [Compile](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/38029039480), [Parity](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/38029039471), [Fork Safety](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/38029039469) — success |
| Унаследованный сайт | `docs/src/content/docs/` в основном описывает **оригинальный** WinUtil; её команды `christitus.com/win` **не запускают WinUtil-RU**. Исходные генерируемые разделы не менялись |
| Документация форка | `README.md`, `README.en.md`, `docs/README-RU.md`, `docs/AUTOMATION-RU.md`, `docs/AUDIT-RU.md`, `SPEC.md`, `.github/CONTRIBUTING.md`, `.github/SECURITY.md`, `AGENTS.md`, `.github/PULL_REQUEST_TEMPLATE.md`: проверены на версию, безопасность инструкций, атрибуцию и ссылки |

### Выявленные и исправляемые недостатки документации

- `.github/PULL_REQUEST_TEMPLATE.md` до аудита содержал только устаревшие инструкции оригинала, не объяснял parity и owner-only stable.
- `docs/src/content/docs/guides/getting-started.mdx` смешивал оригинальные команды с диагностикой форка и ошибочно указывал **13** встроенных иконок; `config/application_icons.json` фактически имеет **20** в `Icons`.
- В документации выпуска SHA `1be881...` местами был назван одновременно тегом и текущей веткой `russian`, хотя позднейшие docs/security PR уже сдвинули ветку.
- Состояние автоматизации упоминало лишь исходный запуск RC, не учитывая наблюдаемые `schedule`-успехи. Это исправляется в актуальном слое, прежние доказательства остаются в архиве.
- Вторая инструкция о PR в `main` относится только к **upstream**, не к форку; документ сайта помечен соответствующим пояснением.

### Не проверено / исключения

- Отдельный Astro build сайта и фактическая публикация `winutil.christitus.com` от имени форка **не выполнялись**: upstream-only `docs.yaml` отключён в форке; сайт наследуется от официального проекта.
- Нельзя утверждать, что все сетевые URL третьих сторон и поведение всех пакетов WinGet проверены вручную или что выполнена полноценная live Windows QA каждой системной операции.
- `fix/battlenet-install-location` содержит пять отдельных изменённых backend/config/test файлов и сознательно **не сливается, не удаляется и не отправляется в upstream**.

---

## Подтверждённый выпуск

| Предмет | Факт и доказательство |
| --- | --- |
| Latest RU stable | [26.10.07-RU.1](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/tag/26.10.07-RU.1): `draft=false`, `prerelease=false` |
| Официальный WinUtil | `26.10.07`, `07ccd8e2e755a706f31569808b31f5b77acad6a9` |
| Fork `main` | `07ccd8e2e755a706f31569808b31f5b77acad6a9` — тот же upstream stable |
| RU release candidate | [26.10.07-RU.1-rc.1](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/tag/26.10.07-RU.1-rc.1), `f1f684ab43f75f075a9947fec2552cd0c615af45` |
| RC workflow | [№ 38020610471](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/38020610471), все четыре job — success |
| Владелец проверил RC на Windows | [QA checkpoint в PR #14](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/14#issuecomment-6093518281) |
| Stable promotion | [№ 38022376836](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/38022376836), все этапы, включая reproducible build, merge и публикацию — success |
| Immutable stable Git tag (не текущая ветка) | `1be881f8690aed8e9e4c230d4a0818fd8f311a95`, тег на exact merged SHA |
| PR состояния на контрольной точке | [#13](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/13), [#14](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/14), [#15](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/15), [#16](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/16), [#17](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/17) merged; на срезе 10.10.2026 открытых PR не было |
| Ветка `russian` | Protected, ruleset **Protect russian stable** — active |

## Доказательство целостности опубликованных файлов

| Asset | Размер, байт | GitHub SHA256 |
| --- | ---: | --- |
| `winutil-RU.ps1` | 1528042 | `7399dd337f1194374ee5fb79e89ad32178626bfc939d8df7bdc551fa09cd48f8` |
| `release.json` (stable) | 42843 | `b780c83005c9772577b23b0639fc8b8cab65b5ed4a3398391cffe310e98acb60` |
| `LICENSE` | 1095 | `61512a5ea110165ce800d00d2d85bbf1af0dc3ccc5d453ae8b5fe9ae20e6c5b5` |

**Проверка:** GitHub Release API сообщает тот же SHA256 программы, что и RC; stable/release assets содержат одинаковый `winutil-RU.ps1`, а `release.json` **не обязан совпадать с RC** (различаются канал и source commit). Финальный stable workflow подтвердил равенство хеша пересобранного скрипта, неизменённого дерева кода после merge и опубликованных assets. Это не утверждение, что каждая системная операция установки, ISO или tweaking проверена владельцем вручную.

## Ветки и очистка

Live перечень веток после PR #14/#15: **3** — `russian`, `main`, `fix/battlenet-install-location`. Ветки PR #13, #14, #15 уже удалены; их история сохранена merge-коммитами, PR и тегами. **Удалять основную `main` или стабильную `russian` нельзя.**

`fix/battlenet-install-location` по сравнению с `main` расходится по истории (ahead 2, behind 1), содержит **5 уникально изменённых файлов**: `config/applications.json`, `functions/private/Install-WinUtilProgramWinget.ps1`, `functions/public/Invoke-WPFInstall.ps1`, `pester/install-workflow.Tests.ps1`, `pester/package.Tests.ps1`. Это независимое незавершённое исправление — **не удалять без отдельного решения о сохранении/отказе от работы**. Нет открытых PR, все 15 известных PR слиты; исторические Git tags и releases сохранены.

## Дополнительное замечание безопасности — исторический workflow

При аудите обнаружен прежний альтернативный ручной путь stable: `.github/workflows/russian-release.yaml` с `publish_stable=true`, который не требовал immutable RC и Environment approval. По отдельному разрешению владельца этот риск устранён: старый workflow **оставлен для ручной сборки и проверки без публикации**; удалены вход `publish_stable`, шаг `Publish-WinUtilRussianRelease.ps1` и права `contents: write`, сохранены strict parity, компиляция, проверка SHA256/манифеста и выгрузка артефактов. Добавлен защитный тест в `pester/ru-automation.Tests.ps1`. Единственный workflow для стабильной публикации — `ru-stable-promotion.yaml` с owner-only QA/RC/hash/environment gates. Сам текущий stable `26.10.07-RU.1` выпущен по защищённому пути и не менялся.

Также в `unittests.yaml` есть условный dry-run, привязанный к уже удалённой ветке PR #13 (`automation/upstream-stable-watch-6h`). Это низкоприоритетный устаревший CI-спецслучай, который не влияет на текущие релизы; удалять отдельно от docs-аудита.

## Автоматизация и документация

`Upstream RU Release Pipeline` имеет cron каждые 15 минут с `workflow_dispatch`; `Upstream Release Watch` раз в 6 часов в read-only режиме. **Фактические запуски по расписанию подтверждены:** [RC #38056142597](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/38056142597) и [Watch #38051805241](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/38051805241) — success. При отсутствии нового официального stable публикация RC в первом запуске закономерно пропущена. GitHub может задерживать другие плановые запуски. Новые RC автоматически создаются после нового upstream stable, а stable требует отдельного QA и ручного owner-only promotion в `winutil-ru-stable`.

Основной README RU/EN, русское руководство, аудит, автоматизация и `SPEC.md` обновлены и прошли CI в [документационном PR #16](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/16); [PR #17](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/17) окончательно закрыл старый ручной путь публикации stable. Текущий повторный docs-аудит устраняет несоответствия PR-шаблона и разграничивает upstream-сайт Astro/Starlight с инструкциями русского форка. Автоматически генерируемые страницы `docs/src/content/docs/code-reference/{features,tweaks}/` не редактируются вручную. Факт сборки сайта/его публикации отдельно не заявляется.

---

# Архив: технический аудит 26.09.29-RU.1

**Дата проверки:** 9 октября 2026 года. Предыдущий аудит сохранён ниже.

## После публикации: состояние `russian` и PR #11

- **Источник опубликованного `26.09.29-RU.1`:** `0f2739e7d7bc74939a8b196a4cbacd9f045dd7ef`; три исходных release asset и их SHA256 зафиксированы ниже. Новый asset для последующего исправления не публиковался.
- **Ветка `russian`:** `9f85c63d8c23ba707a120f060dfba5b957176981` по live-проверке 09.10.2026. [PR #10](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/10) (документация) слит 09.10 в 13:51:58 МСК; [PR #11](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/11) (startup) слит 09.10 в 17:21:17 МСК. Merge commit PR #11 совпадает с SHA ветки.
- **Изменение PR #11:** условный пропуск `Clear-Host` при redirected output; необязательное чтение `AppIconMode` и `Language` без ошибки при отсутствии значения. Операционные функции установки, tweaks, DNS, AppX, Windows Update и ISO не изменялись этим PR.
- **Device QA:** владелец запускал exact head `8de8c001ca5646cd10d6b7db3ec882792d201eeb`; в полученном логе нет прежних startup ошибок. Проверка относится к PR head до merge; все системные операции отдельно не проверялись.
- **Post-merge [Unit Tests](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/37943543891):** 1031 passed PowerShell 7 + 163 passed Windows PowerShell 5.1; 0 failed, skipped, notrun, inconclusive; PS Script Analyzer success.
- **Post-merge [Compile & Check](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/37943543781), [Russian Backend Parity](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/37943543870), [Fork Automation Safety](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/37943543808), [generated-file guard](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/37943543831):** jobs completed/success. WPF RU → EN → RU, bundled images, navigation layout проверены в Windows CI.

Числа **1021 + 153** ниже относятся **только к опубликованному исходному commit**; **1031 + 163** — к более позднему merge commit `russian`. CI для ветки не превращает её автоматически в новый стабильный release.
## Текущий стабильный выпуск

| Параметр | Значение |
| --- | --- |
| Выпуск | [26.09.29-RU.1](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/tag/26.09.29-RU.1), опубликованный stable, не draft и не prerelease |
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
