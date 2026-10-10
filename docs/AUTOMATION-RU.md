# WinUtil-RU — безопасный конвейер обновлений

Статус на **10.10.2026**: [PR #13](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/13) слит; CI-исправление [PR #15](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/15) слито. Полный RC pipeline [№ 38020610471](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/38020610471) и защищённое stable promotion [№ 38022376836](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/38022376836) успешно завершились. Текущий stable — **[26.10.07-RU.1](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/tag/26.10.07-RU.1)**.

## Цель и разделение полномочий

| Событие | Автоматически | Требуется решение владельца |
| --- | --- | --- |
| В официальном WinUtil появляется новый опубликованный stable release | Проверка по GitHub API, тег и SHA | Нет |
| Обновление нашей `main` | Только обычный fast-forward на проверенный официальный stable commit | При расхождении истории — ручной разбор |
| Подготовка русской редакции | Отдельная candidate-ветка + Draft PR; версии и pinned baseline | При затронутых одновременно upstream/RU файлах — ручной перенос |
| CI, parity, тесты PS7/PS5.1, WPF, сборка | GitHub-hosted Windows runner; останавливает выпуск при любой ошибке | Нет |
| Выпуск тестовой RC | GitHub **prerelease**, точный commit и SHA256 | Владелец тестирует файл на Windows |
| Слияние RC в `russian` и stable release | Только в отдельно **вручную запущенном** workflow с указанием SHA256 и подтверждением QA | **Да: явное подтверждение владельца** |

## Частота и задержки

- Отдельный наблюдатель [Upstream Release Watch](../.github/workflows/upstream-release-watch.yaml) делает контрольную read-only проверку каждые 6 часов.
- [Upstream RU Release Pipeline](../.github/workflows/upstream-ru-release-pipeline.yaml) проверяет релизы каждые **15 минут** в **07, 22, 37 и 52 минуты каждого часа UTC**. Это не мгновенный webhook: GitHub Actions может задержать либо пропустить запланированный запуск.
- Путь `workflow_dispatch` позволяет владельцу инициировать такую же проверку вручную, не дожидаясь cron.
- Базовая проверка сравнивает официальный stable tag с pinned baseline. Автоматизация **не следует за непроверенными коммитами official main** и не применяет upstream prerelease.
- Автоматическая проверка не запускает скачанный код от upstream до подтверждения SHA релиза, но сборка кандидата всё равно исполняет проверенный исходный код официального WinUtil в GitHub-hosted runner.

## Защита основной линии

`main` синхронизируется только как точная копия коммита официального **опубликованного стабильного тега** (не произвольного состояния upstream main). Скрипт [Prepare-WinUtilRussianCandidate.ps1](../tools/automation/Prepare-WinUtilRussianCandidate.ps1) проверяет SHA тега по GitHub API, ancestry старого pinned baseline и fast-forward будущей `main`. Он применяет обычный `git push`, не `--force` и не `reset`; конфликт или запрет записи останавливает обновление. Если перенос локализации невозможен, `main` может остаться обновлённой, но `russian` будет сохранена.

Ни один автоматический шаг не переписывает `russian`. При новой версии создаётся `automation/rc-YY-MM-DD-ru-1`. Повторный запуск проверяет наличие кандидата и его точную привязку к официальному SHA, а не заменяет существующую ветку. Одновременно допускается только один открытый RC PR; при появлении следующего официального выпуска очередь RU приостанавливается до разрешения предыдущего PR.

Конфликты изменений upstream с изменениями русского форка за пределами документации останавливают перенос: **запрещено молча выбирать нашу сторону для backend, WPF или конфигурации**. Вторая обязательная защита — [Test-WinUtilRussianEdition.ps1](../tools/Test-WinUtilRussianEdition.ps1): точный официальный тег, файловая parity защищённых путей, перечень разрешённых изменений интерфейса. Новые UI-строки и особенности релиза всё равно требуют проверки человеком.

## Автоматическая сборка RC

Workflow использует точный SHA кандидатного коммита, PSScriptAnalyzer, Pester PS7, тесты PS5.1, строгую parity, сборку канала `beta` и загрузку реальной WPF-разметки на Windows. Только после их успешного завершения создаётся GitHub prerelease вида `YY.MM.DD-RU.1-rc.1`, c asset `winutil-RU.ps1`, манифестом `release.json` и лицензией. Сборка привязана к commit SHA и SHA256; существующие теги/prerelease не перезаписываются. Стабильный канал **не** публикуется данным workflow.

`GITHUB_TOKEN`-созданные PR могут требовать отдельного разрешения для автоматических PR-workflows. Именно поэтому обязательные RC-тесты выполняются внутри основного scheduled workflow, а не полагаются на доставку события от созданного ботом PR.

### Проверки, обязательные по правилам защиты `russian`

Существующий ruleset `Protect russian stable` требует **четыре контекста**: `strict-parity`, `Compile-and-Check`, `test` и `PS Script Analyzer`. Созданные `GITHUB_TOKEN` pull requests могут оказаться в ожидании разрешения на PR-триггеры. Поэтому после создания RC кандидатный workflow отдельно вызывает `workflow_dispatch` для `russian-parity-check.yaml`, `compile-check.yaml` и `unittests.yaml` с **точным ref RC-ветки**, и проверяет отсутствие уже запущенных workflow_dispatch для того же кандидата. Это не подмена статусов: настоящие GitHub-hosted jobs должны завершиться успешно, и обычный PR merge проверяет ruleset. Возможные блокировки прав Actions или красные проверки не обходятся через `--admin`.

## Ручная проверка и продвижение в stable

После появления RC пользователь скачивает её из GitHub Releases и **на своём Windows ПК** проверяет RU/EN, первый запуск, меню установки, логи, обновления и важные сценарии. Эти действия не могут быть достоверно заменены только CI.

Чтобы выпустить stable, владелец `TokhirjonYuldoshev` вручную запускает workflow [Promote Tested RU RC to Stable](../.github/workflows/ru-stable-promotion.yaml) на `russian` и указывает:

1. Номер текущего открытого RC PR.
2. Точный тег протестированного prerelease.
3. SHA256 файла `winutil-RU.ps1` из протестированного prerelease.
4. Подтверждение `I_TESTED_THIS_RC`.

Это **отдельное действие пользователя**, не автоматически последующий job. Перед merge workflow сверяет SHA PR, immutable RC-tag, скачанные assets и подтверждённый SHA256. Затем воспроизводит standalone-сборку кандидата, требует идентичного бинарного SHA256, пытается обычный PR merge по ожидаемому head SHA, подтверждает полное равенство дерева `russian` с проверенным кандидатом, проверяет parity и SHA256 на merge SHA, и лишь после этого создаёт новый неизменяемый stable tag/release. Ошибка любого шага блокирует stable. Важная оговорка: если отказ случится **после** разрешённого merge, ветка `russian` уже изменена, но публикации стабильного релиза не будет; потребуется разбор без force-push.

**Защищённая среда:** Settings → Environments → `winutil-ru-stable` → Required reviewers → `TokhirjonYuldoshev`. Владелец подтвердил настройку required reviewer и разрешение self-review; текущему подключению GitHub недоступна независимая административная проверка этих параметров. Итоговый [promotion workflow № 38022376836](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/38022376836) завершился успешно. Перед будущими выпусками необходимо сохранять проверку owner-only dispatch, точного SHA256 и Environment approval.

## Подтверждённый производственный цикл 26.10.07-RU.1

| Контрольная точка | Подтверждённый результат |
| --- | --- |
| Официальный тег | `26.10.07`, commit `07ccd8e2e755a706f31569808b31f5b77acad6a9` |
| Fork `main` | Fast-forward до того же официального commit |
| Кандидат | [PR #14](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/14), commit `f1f684ab43f75f075a9947fec2552cd0c615af45` |
| Тестовый выпуск | [26.10.07-RU.1-rc.1](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/tag/26.10.07-RU.1-rc.1), [RC CI #38020610471](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/38020610471) — success |
| Проверка Windows | [Подтверждение владельца](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/14#issuecomment-6093518281) |
| Защищённый stable | [26.10.07-RU.1](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/tag/26.10.07-RU.1), [workflow #38022376836](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/38022376836) — success |
| Итог `russian` и stable tag | `1be881f8690aed8e9e4c230d4a0818fd8f311a95` |
| SHA256 `winutil-RU.ps1` RC и stable | `7399dd337f1194374ee5fb79e89ad32178626bfc939d8df7bdc551fa09cd48f8` |

Проверка Windows PowerShell 5.1 сначала выявила раздельную установку Pester между `pwsh` и `powershell`. Исправление [PR #15](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/15) добавило установку Pester 5.8.0 в правильной среде и реальный smoke-test; после этого полная сборка RC прошла. PowerShell 7 RC: **1040 tests passed, 0 failed**. Ни стабильный merge, ни тег не создавались до отдельного разрешения владельца.

## Проверка legacy release пути

В репозитории ещё есть ручной `russian-release.yaml` с `publish_stable=true`, использованный в прежних версиях. Он выполняет backend parity, сборку и проверку SHA256, **но не требует RC тег, подтверждённый SHA256 опубликованной RC и Environment**, как `ru-stable-promotion.yaml`. Для выпусков по правилу обязательного Windows QA используйте **только новый защищённый promotion**. Ограничение старого пути требует отдельного CI/security изменения и согласования; этот документационный PR не меняет workflow.

## Права и эксплуатация

- Для автоматического обновления `main` и создания RC PR в репозитории должен быть разрешён `GITHUB_TOKEN` с `contents: write` и `pull-requests: write`; в Settings → Actions → General может потребоваться включить **Allow GitHub Actions to create and approve pull requests**. При запрете работа останавливается, настройки самостоятельно не меняются.
- Monitor получает только `contents: read`. Pipeline job подготовки RC получает `contents: write` и `pull-requests: write` только там, где это необходимо; проверочные jobs read-only. Stable publishing получает права записи только по вручную вызванному событию.
- Семь отключённых upstream-only workflows не включаются. `main`, `russian` и release-теги никогда не переписываются принудительно.
- GitHub Actions хранит build artifact 30 дней. GitHub prerelease остаётся доступным, пока его не удалит владелец.
- Если необходимо остановить автоматизацию, нужно вручную отключить **Upstream RU Release Pipeline**, а не удалять существующие теги, stable releases или backend. `Upstream Release Watch` может продолжать read-only проверку.
- **Следующие версии:** после появления нового официального stable автоматический конвейер должен подготовить очередной RC; проверка на Windows и отдельное подтверждение владельца обязательны перед стабильным релизом. Ветка `fix/battlenet-install-location` содержит независимую незавершённую работу и не должна сливаться либо удаляться автоматически.
