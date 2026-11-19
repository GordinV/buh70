# AGENT.md — роли агентов `ai_task`

Автономный микросервис (Genkit + TypeScript), который планирует, запускает и контролирует регламентные расчётные процессы `buh70`.
Полная спецификация — `ai_task.md`, история реализации — `walkthrough.md`. Этот файл — краткая карта агентов и правила работы с ними.
Доработки надёжности цепочки FinBit (2026-11-15) — `implementation_plan.md`; правила и ограничения — раздел «Надёжность цепочки FinBit» ниже.

## Базовые принципы

- **Только API, без доступа к БД.** Все агенты общаются с бэкендом `buh70` через `HTTP POST` (`shared/api_client.ts`, `BUH70_API_BASE_URL` + `BUH70_API_TOKEN`). Хранимые процедуры вызываются внутри эндпоинтов `/task/*` бэкенда.
- **Tick-based FSM.** Оркестратор не является демоном. Cron запускает `run_tick.sh` (docker `buh70-ai-task`, `flock`-блокировка), выполняется один тик, состояние сохраняется в `state/orchestrator_state.json`, и процесс завершается.
- **Неблокирующий запуск.** Эндпоинты запуска создают запись в `ou.logs`, стартуют фоновую процедуру и сразу возвращают `log_id`. Статус задачи проверяется на следующих тиках через `POST /task/read_log/:user_id/:task_name`.
- **Конфигурация без пересборки.** `orchestrator/config.json` и `<agent>/config.json` читаются на каждом тике: время, зависимости, `prompt`, `params`.
- **Два режима решений.** Если в конфиге задан `prompt`, решение принимает Gemini (`ai.generate`, structured output). Если `prompt: null`, работают детерминированные правила FSM. Без `GEMINI_API_KEY` LLM не используется. Ключ `mock_*` включает эмуляцию LLM (`index.ts`).
- **Среда выполнения и совместимость Node.js (Critical):**
  - **Микросервис `ai_task`:** TypeScript / ES2022, работает в Docker-контейнере `buh70-ai-task` на базе **Node.js 20+ LTS (`node:20-alpine`)**. Сборка через `npm run build` (`tsc`).
  - **Основной бэкенд `buh70` (`routes/`, `models/`, `libs/`, запускаемый в PM2):** Работает на **legacy Node.js (версии < 14)**. В коде бэкенда (`.js`) **СТРОГО ЗАПРЕЩЕНО** использовать операторы ES2020+:
    - **Запрещен `??` (Nullish coalescing):** приводит к фатальному `SyntaxError: Unexpected token ?`. Вместо него использовать явные проверки `(x !== undefined && x !== null ? x : fallback)`.
    - **Запрещен `?.` (Optional chaining):** приводит к `SyntaxError: Unexpected token .`. Вместо него использовать `(x && x.y)`.
    - Код бэкенда должен быть совместим со стандартом ES6 / CommonJS.

## Граф задач (DAG)

```
getEarved (05:00) ──► check_asutus ──► inforegister - -► import_earved ──► sendFinBitReport
   выкачка счетов      проверка          поиск/кэш         частичный разбор    рассылка
   (flow getEarved)    контр-агентов     (мягкая зав.)     и сохранение        (по result.imported лога import_earved)
                                                           (flow docs.sp_loe_earved)
read_mail (06:00)
ariregister_sync (06:00) ──► libs.ariregister (независимый поток, flow ariregisterSync)
calc_arv_jaak (07:30)
reporter (08:00) ждёт sendFinBitReport, calc_arv_jaak, read_mail (не дольше max_wait_time 09:00)
saldoandmik (20:00) ──► lisa1_lisa5
```

Cron запускает тик каждые 30 минут, поэтому каждый шаг цепочки стартует на следующем тике после завершения предыдущего: цепочка FinBit, начатая в 05:00, доходит до `sendFinBitReport` к 07:00 и завершается к ~07:30, до отчёта в 08:00. Шаг тика не уменьшается: в графе есть длинные задачи.

Статусы задач: `PENDING → RUNNING → SUCCESS | FAILED | SKIPPED`. Статусы цикла: `IDLE | IN_PROGRESS | COMPLETED | FAILED`.
Если предшественник в `FAILED`/`SKIPPED`, зависимые задачи каскадно переводятся в `SKIPPED`. Повторы: до `max_attempts` (по умолчанию 3), когда в логе нет `exec_start`, при ошибках или по watchdog таймаута (`timeout_hours` в `config.json`, по умолчанию 12 часов — `TASK_TIMEOUT`). Исключение: если бэкенд пометил сбой в `ou.logs` как `retryable: false` (нет данных, нет прав), задача сразу получает `FAILED` (событие `TASK_FAILED_NON_RETRYABLE`) без повторов. Перед повтором оркестратор проверяет, нет ли сегодня более позднего успешного запуска этого flow (например, ручного перезапуска): если есть, он принимается (`TASK_RECONCILED_LOGS`).

**Защита целостности зависимостей (Downstream Lock):** Запрещено запускать, перезапускать или перевооружать (re-arm в `PENDING`) родительскую задачу $A$, если любая зависимая от неё дочерняя задача $B$ (`B.depends_on.includes(A)`) в данный момент находится в статусе `RUNNING`. Например, `saldoandmik` не может перезапуститься, пока выполняется зависящий от него `lisa1_lisa5`.

---

## Роли

### 1. `orchestrator/` — главный координатор (Meta-agent)

| | |
|---|---|
| Точка входа | `runOrchestratorTick` (`orchestrator.agent.ts`); Genkit flow `orchestratorTickFlow`; CLI `node dist/index.js [--force] [--user N] [--rekv N] [--date YYYY-MM-DD] [--state path]` |
| Устаревший режим | `runOrchestrator` / `--full`: последовательный блокирующий прогон всех субагентов с `watchTaskUntilDone` |
| Конфиг | `orchestrator/config.json`: `daily_start_time` (20:00), `timezone` (Europe/Tallinn), `max_task_attempts`, `params`, `prompt` |
| Состояние | `state.manager.ts` — чтение/валидация (Zod)/атомарная запись `state/orchestrator_state.json`, динамическое обнаружение `<agent>/config.json`, фильтрация служебных каталогов (`EXCLUDED_NON_DAG_DIRS`), сброс при смене дня |

Обязанности за один тик:
1. Загрузить конфиги всех расчётных агентов и слить их с состоянием (`reconcileTasksWithConfigs`). Новый агент получает `PENDING`, служебные не-DAG каталоги (`logs_watcher`, `schedule_monitor`) исключаются из `state.tasks`.
2. Проверить смену календарного дня и при необходимости начать новый цикл со сброшенными `attempts`. Посуточное перевооружение задач (`TASK_REARMED`) блокируется, если зависимые от них задачи находятся в `RUNNING`.
3. **Cycle decision** (`evaluateCycleDecision`): LLM по `prompt` возвращает `RUN_CYCLE | WAIT_SCHEDULE | SKIP_CYCLE | PAUSE_CYCLE` и `force_run`. На `localhost`/`127.0.0.1` цикл открывается сразу.
4. Сверка с `ou.logs` (`orchestrator.tools.ts → checkTaskAlreadyRunToday`): задача, уже выполненная сегодня (для задач с расписанием — с `exec_start >= schedule.time`), помечается `SUCCESS`. При всех обращениях к `ou.logs` (`checkTaskAlreadyRunToday`, `checkTaskStatus`, `guardAgainstDuplicate`, `reporter`) используется индивидуальный `task.params?.userId ?? state.params.userId` (`resolveTaskUserId`).
5. Инспекция `RUNNING`-задач и **result decision** (`evaluateTaskResultDecision`): глубокий разбор `result`. Если у агента есть `prompt`, вердикт о `SUCCESS`/`FAILED` выносит LLM. Затем повтор или `FAILED`. Статус читается по `log_id` запуска этой задачи (`checkTaskStatus(..., task.log_id)`), без `log_id` — по последней записи flow.
6. **Launch decision** для `PENDING` (`evaluateTaskLaunchDecision`): LLM (`RUN | WAIT | SKIP` + `dynamic_params`) либо FSM (`depends_on`, `schedule.time/day/month`, суточное окно, **Downstream Lock**: блокировка запуска в `WAIT`, если любая зависимая задача находится в статусе `RUNNING`).
7. Параллельный запуск готовых задач через `dispatchTaskByKey` (с предварительной защитой от параллельного дубля `guardAgainstDuplicate`). Для зависимых задач пробрасываются параметры родителя через `manifest.resolveParentParams(state)` (`state.tasks.getEarved.log_id → params.logId` для `import_earved`, `state.tasks.import_earved.log_id → params.logId` для `sendFinBitReport`). Параметры родителя всегда приоритетнее `dynamic_params` решения LLM: модель не может подменить `logId`.
8. По расписанию в 08:00 и после завершения зависимостей (`sendFinBitReport`, `calc_arv_jaak`, `read_mail`) запускается `reporter`; если зависимости не завершились к `max_wait_time` (09:00), отчёт уходит с тем, что есть, а незавершённые шаги показываются как `RUNNING`/`PENDING` («Pooleli»). Он читает `ou.logs` по всем расчётным агентам (запись текущего цикла по `log_id`; без неё — последняя запись flow за 24 часа; задача, ещё не стартовавшая сегодня, вчерашний лог не подхватывает) (`exec_start`, `exec_end`, `durationMs`, `status`, ошибки/итоги), вызывает `manifest.enrichReportStep(stepLog, task)` для агент-специфичного обогащения отчёта и отправляет email-отчет. После завершения всех задач суточный цикл переходит в `COMPLETED` с выставлением актуального `next_scheduled_run`.

### 2. `logs_watcher/` — наблюдатель логов (служебный субагент)

- `tools.ts → readTaskLog`: `POST /task/read_log/:user_id/:task_name` (опционально `log_id`, `limit`, `hours`). Бэкенд возвращает также `retryable` и `source_log_id`.
- `agent.ts → inspectLogExecutionResult`: глубокая инспекция `error`/`result`/`response`. Ищет скрытые ошибки при формальном `status: success` (например, `success: false` или `connect ETIMEDOUT` в элементах массива). Возвращает `hasErrors`, `errorDetails`, `resultSummary`.
- `agent.ts → checkTaskStatus(userId, taskName, apiClient, logId?)`: разовая проверка статуса; с `logId` читает запись запуска, возвращает `retryable` (`false` — повтор бессмыслен, `undefined` — не указано).
- `agent.ts → watchTaskUntilDone`: блокирующий цикл опроса (`TASK_POLL_INTERVAL_MS`, `TASK_TIMEOUT_MS`). Используется только в `--full`-режиме и в `run*Subagent` (они передают `logId` запущенной задачи).
- Не имеет `config.json` и не входит в DAG (`EXCLUDED_NON_DAG_DIRS`).

### 2.1. `schedule_monitor/` — монитор расписания и статусов (служебный субагент)

- `agent.ts → buildScheduleSnapshot`: чистая функция формирования среза состояния всех агентов графа (`status`, `schedule`, `next_planned_run`, `next_run_reason`, `timeout_deadline`, `attempts`, `log_id`, `error`).
- `tools.ts → logAgentSchedule`: вызов `POST /task/logAgentSchedule/` (`ou.logs`, `flow = 'ai_task.agent_schedule'`).
- `agent.ts → runScheduleMonitorSubagent`: основной исполнитель субагента (вход: `userId`, `rekvId`, опционально `state` или `stateFilePath`), возвращает `ScheduleMonitorResult` (`logId`, `status`, `snapshot`).
- `index.ts`: зарегистрированы Genkit flows `scheduleMonitorFlow` и `agentScheduleFlow` для запуска через Genkit CLI/Dev UI/Reflection API.
- `agent.ts → manifest`: экспортирует `manifest` для совместимости с вызовом через CLI/Genkit.
- `agent.ts → runScheduleMonitor`: вызывается оркестратором на каждом тике (включая ранние выходы `IDLE_WAIT_NEXT_SCHEDULE`). Ошибки не прерывают тик.
- Не имеет `config.json` и не входит в DAG (`EXCLUDED_NON_DAG_DIRS`). Настраивается через `orchestrator/config.json` (`schedule_monitor.enabled`).

### 3. Расчётные субагенты (исполнители)

Все устроены одинаково: `schemas.ts` (Zod-вход/выход + константа `TASK_FLOW_*`), `tools.ts` (`start*` — неблокирующий POST), `agent.ts` (`run*Subagent` + `manifest: AgentManifest`), `config.json`, тест.

> **Сервисный `userId` и приоритет источников:** все агенты `ai_task` (включая цепочку FinBit и регламентные задачи `saldoandmik`, `lisa1_lisa5`, `calc_arv_jaak`, `read_mail`) и оркестратор (`orchestrator/config.json`) работают от единого сервисного аккаунта `AI_TASK_SERVICE_USER_ID = 11770` ([`shared/constants.ts`](file:///c:/development/buh70/routes/ai/ai_task/shared/constants.ts); алиас `FINBIT_SERVICE_USER_ID = AI_TASK_SERVICE_USER_ID` сохранён для совместимости), чтобы операции `ai_task` в `ou.logs` были отделены от пользовательских запусков.
>
> **Итоговый приоритет источников `userId` / `rekvId`:** явный CLI-флаг (`--user` / `--rekv`, действует только на один запуск и не сохраняется в `state`) → `<agent>/config.json` (`params.userId` / `params.rekvId`) → `orchestrator/config.json` (`params.userId` / `params.rekvId`) → дефолты кода (`AI_TASK_SERVICE_USER_ID = 11770` / `63`). Для рабочего файла `state/orchestrator_state.json` при каждом `loadState` поля `userId` и `rekvId` у задач (`CONFIG_OWNED_PARAM_KEYS`) и цикла принудительно берутся из `config.json` (а не из сохранённого `state` или env `DEFAULT_USER_ID`/`DEFAULT_REKV_ID`); динамические поля задач (например, `logId`) сохраняются.

| Агент | Endpoint | Flow в `ou.logs` | Зависимости | Расписание | `userId` | Prompt | Роль |
|---|---|---|---|---|---|---|---|
| `saldoandmik` | `/task/calcKondSaldoandmik/` | `eelarve.sp_koosta_saldoandmik` | — | 20:00 | `11770` | нет | Сводный сальдоандмик (`user_id`, `rekv_id`, `kond`) |
| `calc_arv_jaak` | `/task/calcArvJaak/` | `docs.check_arv_jaak` | — | 07:30 | `11770` | нет (`prompt_test` для теста) | Пересчёт сальдо и остатков счетов (вне регламентного цикла) |
| `read_mail` | `/task/readMail/` | `mail.read_mail_errors` | — | 06:00 | `11770` | нет (`prompt: null`) | Анализ входящей почты на ошибки недоставки счетов клиентам (Mail Delivery Failure). Снимает отметку отправки в БД (`docs.tuhista_arve_saatmise_staatus`), отправляет персональные отчеты ответственным бухгалтерам с перечнем возвращенных счетов и отправляет алерт при `Muud vead` |
| `lisa1_lisa5` | `/task/calcLisa1Lisa5/` | `eelarve.salvesta_lisa_1_5_kontrol` | `saldoandmik` | — | `11770` | нет | Контрольные формы Lisa 1 / Lisa 5 |
| `getEarved` | `/task/getEarved/` (`is_agent: true`, опц. `date_query_from`, по умолчанию сегодня минус 5 дней) | `getEarved` | — | 05:00 | `11770` | нет | **Только выкачка** e-счетов из FinBit (сервисный аккаунт `FINBIT_SERVICE_USER_ID`). Синхронно сохраняет массив счетов в `ou.logs` (`propertis.arved` = `[{rekvId, userId, count, arved: [...]}]`, `result.totalFetched`, `invoiceNumbers`) и возвращает `log_id` (`status: COMPLETED`). Разбор не выполняет. 0 счетов — штатный успех с пустым логом |
| `check_asutus` | `/task/checkAsutusAvailability/` (`log_id` лога getEarved) | `checkAsutusAvailability` | `getEarved` | — | `11770` | нет | Проверка через `libs.check_asutus_availibility` наличия контр-агентов (рег.код = `data.asutusid`) в `libs.asutus`. Список отсутствующих сохраняется в `ou.logs.changes` лога getEarved и в `result.missing`. Всегда завершается `success` (найденные отсутствующие — информация, а не ошибка) |
| `inforegister` | `/task/getInforegister/` (`log_id`, `hash` из `INFOREGISTER_HASH`) и синхронный `/task/inforegisterLookup/` (`regkood`, `hash`) | `getInforegister` (пакетный), `inforegisterLookup` (синхронный) | `check_asutus` | — | `11770` | нет | Пакетный режим берёт отсутствующих из `check_asutus.result.missing` и при `dryRun=false` сохраняет через `libs.sp_salvesta_asutus`; синхронный режим (`lookupInforegister`, `inforegisterLookupFlow`, CLI `npm run inforegister-lookup -- <regkood>`) проверяет 8-значный `regkood` и возвращает `local`, `registry`, `diff` без сохранения в `libs.asutus` (подробно — п. 3.2). |
| `import_earved` | `/task/importEarved/` (`log_id` лога getEarved) | `docs.sp_loe_earved` | `getEarved`, `check_asutus` (+ мягкая `inforegister`) | — | `11770` | нет | **Частичный импорт**: счета с отсутствующим контр-агентом пропускаются (`result.skipped`, `missing`, `totalSkipped`), остальные импортируются через `docs.sp_loe_earved`. Мягкая зависимость `soft_depends_on: ['inforegister']` — ждёт завершения `inforegister`, но стартует даже при его `FAILED`/`SKIPPED` (в отчёт добавляется пометка). Имя flow сохранено прежним: по нему `docs.get_arve_kinnitaja` находит лог импорта. Пропущенные счета подтянутся при следующей выкачке (окно `date_query_from`), когда контр-агент будет добавлен. **Результат в `result`:** `imported` — `[{doc_id, number, rekv_id}]` реально созданные документы (единственный источник для рассылки), `errors` — `[{number, asutusid, error}]`, `totalImported`, `totalFailed`. Ошибка одного счёта не откатывает остальные (подтранзакция на счёт в `docs.sp_loe_earved`). Статус лога: частичный успех → `success`; ни одного импортированного при ошибках → `failed` + `retryable: false`; исключение (БД) → `failed` + `retryable: true` (`Puudub õigused` — `false`). 0 импортированных без ошибок (выходной, все счета уже есть) — штатный `success`. Уже существующие счета процедура пропускает молча |
| `sendFinBitReport` | `/task/sendFinBitReport/` (`logId`) | `sendFinBitReport` | `import_earved` | — | `11770` | нет (детерминированная оценка, резюме формирует `enrichReportStep`) | Дочерний агент `import_earved` (получает его `log_id`): рассылает уведомления получателям счетов из `result.imported` лога импорта. Без `logId` родителя пропускается (`SKIP`). Исходы: импорт создал 0 документов → `success` без рассылки («Uusi arveid ei imporditud», `no_op`); документы есть, получателей нет → `failed`, `retryable: false`; часть писем не ушла → `failed`, `retryable: true`; все письма ушли → `success`. Лог рассылки хранит `source_log_id` (лог импорта): при повторе адресам, уже получившим письмо, оно не отправляется (`already_sent`) |
| `ariregister_sync` | `/task/syncAriregister/` (`hash` из `INFOREGISTER_HASH`, scope `sync`) | `ariregisterSync` | — | 06:00 | `11770` | нет | Ежесуточная синхронизация открытых данных Äriregister (`ettevotja_rekvisiidid__lihtandmed.csv.zip`) в `libs.ariregister` и `libs.ariregister_meta` (подробно — ниже) |
| `asutus_kehtivus` | `/task/checkAsutusKehtivus/` (`dry_run`, `max_close`, `hash` со scope `sync`) | `checkAsutusKehtivus` | `ariregister_sync` | — | `11770` | нет | Проверка закрытых/удалённых организаций в `libs.asutus` по локальной таблице `libs.ariregister` и простановка `properties->>'kehtivus'` (см. ниже; по умолчанию `dryRun: true`) |

### 3.1. `read_mail/` — монитор недоставки счетов по e-mail (расчётный субагент)

- **Назначение:** Автономная обработка сообщений о сбоях доставки электронной почты со счетами покупателям (NDR / Non-Delivery Reports / Bounce notices: `Mail Delivery Subsystem`, `Mailer-Daemon`, `Undelivered Mail Returned to Sender`).
- **Схема работы:**
  1. Вызывается оркестратором через API `POST /task/readMail/` ежедневно в 06:00 (до сводного отчета в 08:00). В `read_mail/config.json` задан `"prompt": null`, чтобы оркестратор запускал задачу строго по детерминированному расписанию `06:00`.
  2. Подключается к IMAP-серверу входящей почты и инкрементально считывает новые bounce-сообщения (дата последнего чтения фиксируется в `state/read_mail_state.json`).
  3. Парсит тело письма и диагностические заголовки/коды SMTP (`RFC 3464` / `RFC 2047`), определяя номер счета (`doc_number`), адрес получателя (`recipient_email`), причину ошибки и содержание темы исходного письма (`subject`). Тема письма обязательно сохраняется в логах выполнения и деталях ошибок.
  4. Классифицирует ошибку по 4 стандартным статусам:
     - `Aadressi viga` — некорректный или несуществующий ящик получателя (`5.1.1`, User unknown, Invalid mailbox, No such user).
     - `Domeeni viga` — недоступный или несуществующий почтовый домен (`5.1.2`, Host/Domain not found, DNS error).
     - `Postkast täis` — переполнение почтового ящика клиента (`5.2.2`, Quota exceeded, Mailbox full).
     - `Muud vead` — любые прочие нестандартные сбои (спам-блокировки `5.7.1`, временные сетевые отказы, отказы ретрансляции и т.д.).
  5. Для каждого проблемного счета вызывает в БД процедуру `docs.tuhista_arve_saatmise_staatus(l_log_id)`, сбрасывая признак отправки счета в `docs.doc.history` и обновляя лог отправки счета в `ou.logs`. Процедура возвращает массив обработанных счетов с email ответственного бухгалтера (`u.properties ->> 'email'`).
  6. **Персональное оповещение ответственных бухгалтеров:** Счета группируются по адресу электронной почты ответственного бухгалтера (`email`). Каждому бухгалтеру формируется и отправляется персональный e-mail отчет со списком не доставленных клиентам счетов (`doc_number`, `recipient_email`, причина недоставки, тема письма). Счета без указанного email ответственного фиксируются в предупреждениях логов.
  7. **Мгновенные алерты (Alerting):** Если ошибка отнесена к категории `Muud vead` (не подпадающей под типовые правила), агент отправляет дополнительное e-mail уведомление администраторам на адреса `vladislav.gordin@gmail.com` и `andrei.vargunin@narva.ee`.
  8. Фиксирует полный структурированный результат разбора в `ou.logs` (`flow = 'mail.read_mail_errors'`) под ключом `result` (включая темы писем `subject`), откуда его подхватывает `reporter` через хук `manifest.enrichReportStep`.
- **Архитектурная реализация:**
  - Полностью **in-process на бэкенде `buh70` (Node.js 13.14.0)** через встроенный низкоуровневый TLS-клиент (`tls`), без внешних npm-библиотек и без вызова внешних процессов/воркеров.
  - Поддерживает безопасную потоковую работу с UTF-8 буквами и IMAP literal buffers (`Buffer.byteLength`).
  - Строгая совместимость с версиями Node.js: отсутствие операторов `?.` и `??` в коде бэкенда `readMail.js`.

### 3.2. `inforegister/` — пакетный импорт и синхронный поиск по рег.коду (на локальной таблице Äriregister)

- **Два режима работы (общее ядро `libs/inforegisterService.js` + `libs/ariregisterStore.js` на бэкенде `buh70`):**
  1. **Пакетный (`POST /task/getInforegister/`, flow `getInforegister`):** берёт `result.missing` из лога `check_asutus`, читает данные из локальной копии Äriregister (`libs.ariregister`, платный API не вызывается, `calls_spent: 0`), сохраняет найденных активных контрагентов через `libs.sp_salvesta_asutus` (при `dry_run=false`) с пометкой `mark: 'Äriregister (automaatselt lisatud)'` и сокращённым `omvorm` из словаря `LEGAL_FORM_ABBREV` (иначе `''`; поля `tel`/`email` не заполняются). Параметры `max_calls`/`maxCalls` и `insecure_tls`/`insecureTls` принимаются для обратной совместимости и игнорируются. В `config.json` агента: `dryRun: false`, `params.userId: 11770`.
  2. **Синхронный поиск (`POST /task/inforegisterLookup/`, flow `inforegisterLookup`):** принимает `{ hash, regkood, year?, cache_only?, force_refresh?, insecure_tls?, config_rekv_id? }`. Ищет организацию в локальной таблице `libs.ariregister`, **не сохраняет** данные в `libs.asutus` и возвращает `{ regkood, asutus_id, source: 'ariregister', fetched_at, closed, local, registry, company, diff, calls_spent: 0, remaining_year: null }`, где `fetched_at` берётся из `libs.ariregister_meta.file_date`. Поле `businessType` возвращается сокращённо (`OÜ`, `AS`, `FIE`, `MTÜ`, `KÜ`, `UÜ`, `TÜ`, `SA`, `SE`, `SCE`, `KOV`), для форм без сокращения — полное название; к `address.fullAddress` добавляется почтовый индекс (`taisaadress + ', ' + indeks`, если ещё не оканчивается им). Параметры `cache_only`, `force_refresh` и `insecure_tls` принимаются для обратной совместимости и игнорируются; `year` используется только в `registry.year`.
- **Коды ответов `/task/inforegisterLookup/`:** `200` (данные найдены; либо `reason: 'not_in_registry'` — отсутствует в `libs.ariregister`, но есть в `libs.asutus` с кодом на `1/8/9`, валидной контрольной цифрой `isValidRegCodeChecksum` и не иностранным адресом `!isForeignAddress(aadress)`, включая пустой адрес → `closed: true`, `registryStatus: 'Kustutatud'`; либо `reason: 'closed_locally'` — отсутствует в `libs.ariregister`, но в `libs.asutus` уже выставлена дата `properties->>'kehtivus' <= сегодня` → `closed: true`, `registryStatus: 'Registrist puudub'`, `closed_since: local.kehtivus`. Если организация активна в `libs.ariregister`, а локальная `kehtivus <= сегодня`, реестр главнее: `closed: false`, в `diff` добавляется `{ field: 'kehtivus', local: local.kehtivus, registry: null }`. Для `Kustutatud` (`deleted_at`) также заполняется `closed_since: local.kehtivus`), `400` (`invalid_reg_code`), `401` (`unauthorized_hash`), `403` (`forbidden_scope`), `404` (`not_found`), `503` (`registry_not_loaded` — таблица `libs.ariregister_meta` пуста), `500` (неожиданная ошибка).
- **Авторизация по `hash` (маршруты `/task/getInforegister/`, `/task/inforegisterLookup/`, `/task/syncAriregister/`):**
  - В `ou.config.properties.INFOREGISTER_TOKENS` (`rekvid = 3`) хранятся только SHA-256 хеши токенов: `[{ token_sha256, user_id, rekv_id, label, scopes: ['batch'|'lookup'|'sync'], active }]`. Сам токен в БД не хранится и нигде не логируется. Выдача/отзыв — `sql/ou/add_inforegister_token.sql` (`user_id` токена `ai_task` должен совпадать с `11770`, чтобы `logs_watcher` находил логи).
  - В `ai_task` секрет задаётся единственной переменной `INFOREGISTER_HASH` (`.env`, читается через `getConfig().inforegisterHash`). При её отсутствии пакетный агент и `ariregister_sync` в тике получают `SKIP` (`INFOREGISTER_HASH puudub`) до HTTP-вызова; ответы `401`/`403` дают невозобновляемую ошибку (`retryable = false`).
  - Переходный флаг бэкенда для пакетного маршрута: `INFOREGISTER_REQUIRE_HASH_BATCH` (по умолчанию `true`; при `false` запрос без `hash` пропускается с warning, неверный `hash` отклоняется всегда).
- **Ключ платного API Inforegister:** `inforegisterLookup` и пакетный режим `getInforegister` ключ (`INFOREGISTER_API_KEY`) больше не используют и платный API не вызывают (исходный код клиента Inforegister остаётся в `libs/inforegister.js`).
- **Инструменты в `ai_task`:** `lookupInforegister` (`inforegister/tools.ts`, при 4xx/5xx возвращает `{ ok: false, reason, message }`; `retries: 1`, `timeoutMs: 45000`), Genkit flow `inforegisterLookupFlow` (`index.ts`, схема без `hash`) и CLI `npm run inforegister-lookup -- <regkood> [--cache-only] [--force-refresh] [--insecure-tls]` (флаги `--cache-only`, `--force-refresh`, `--insecure-tls` принимаются для совместимости и игнорируются).

### 4. `reporter/` — итоговая отчётность

- `agent.ts → generateAndSendReportSubagent`, `tools.ts`: `formatReportMarkdown`, `formatReportHtml`, `sanitizeReportText`, `sendReportEmail` (nodemailer, `SMTP_*`, `REPORT_EMAIL_FROM/TO`).
- **Строгий запуск 1 раз в сутки в 08:00:** Запускается оркестратором строго по расписанию в 08:00 (даже если цикл запущен с `forceRun`, расписание `08:00` у `reporter` соблюдается, если не передан явно `taskKey: 'reporter'`).
- **Защита от повторного запуска в 17:00 / во второй половине дня:** После успешной отправки отчёта (`status: 'SUCCESS'` и `finished_at` за сегодняшний день) повторный запуск в текущих сутках блокируется (`!isReporterAlreadyRunToday`). Агент `reporter` исключён из сверки `ou.logs` (Step 1.4), так как является нотификатором и не пишет в `ou.logs` (что ранее приводило к сбросу в `PENDING` и ложному запуску в 17:00). Кроме того, `resetCycleForNewDay` сохраняет статус выполненных за сегодняшний день задач.
- Опрашивает `ou.logs` по всем расчётным агентам из `state.tasks` (`saldoandmik`, `calc_arv_jaak`, `getEarved`, `check_asutus`, `inforegister`, `import_earved`, `sendFinBitReport`, `read_mail`, `lisa1_lisa5`) с учётом их индивидуального `params.userId`. Для задач, уже запущенных в текущем цикле, используется текущий `log_id`; для `PENDING`-задач без `log_id`, которые были сброшены после полуночи (`TASK_REARMED`, `TASK_RESET_MANUAL`, `CYCLE_RESET_NEW_DAY`), используется снимок `task.last_run` (если его `finished_at`/`started_at` не старше 24 часов — так в утренний отчёт попадают вечерние задачи цикла 20:00 `saldoandmik` и `lisa1_lisa5`, а также вчерашние `FAILED`). Если `last_run` отсутствует или старше 24 часов, шаг показывается как `PENDING` («Pooleli (ootab lõpetamist)»).
- **Интеграция с агентами через `enrichReportStep`:** Оркестратор вызывает `registry[key]?.enrichReportStep?.(stepLog, task)`. Для `read_mail` этот хук извлекает ошибки недоставки счетов из `mail.read_mail_errors` (`mailErrors`) и формирует эстонский `resultSummary`, а `reporter` включает в ежедневный отчет отдельную таблицу **«📧 Tuvastatud vigased e-posti aadressid»** (`Arve nr`, `Saaja e-post`, `Staatus`, `Põhjus`).
- Получает по каждому шагу статус, `logId`, длительность, `error`, `resultSummary` и `overallSuccess`.
- Вызывается не через `dispatchTaskByKey`, а в отдельном блоке тика. `allow_parallel: false`.

---

## Надёжность цепочки FinBit (реализовано 2026-11-15)

Разбор сбоя 2026-11-15: `sendFinBitReport` падал после 3 попыток, когда импорт не создал ни одного счёта. Что изменено (детали — `implementation_plan.md`):

- **Отсутствие данных — не ошибка.** «Нет счетов», «нет писем», «нечего пересчитывать» — штатный `success` с пояснением в `response`. `failed` означает, что работа была, но не выполнена.
- **Данные между шагами передаются структурой в `result`** (`result.imported` лога импорта), а не текстом в `response` / `error_message`. `docs.get_arve_kinnitaja` работает только по `result.imported`; разбор текста `id: N` и выборки по окну времени удалены. Логи импорта старого формата (без `imported`) рассылку не запускают.
- **`retryable`.** Бэкенд пишет в лог `retryable: false` для сбоев, которые повтор не лечит; оркестратор тогда не повторяет задачу. Нет поля — прежнее поведение (повторы до `max_attempts`).
- **Идемпотентность внешних эффектов.** Письма не отправляются повторно адресам, уже получившим их по тому же логу импорта; платные API и письма должны быть идемпотентны к повтору.
- **Статус по `log_id`.** Эндпоинт возвращает `log_id` той записи, в которую пишет `status` и `exec_end`, под тем же `user_id` и `flow`, по которым её читает оркестратор. Служебные записи процедур (например, запись без `flow`, которую создаёт `docs.sp_loe_earved`) в качестве `log_id` не использовать. Поиск по flow остаётся запасным путём и для сверки с запусками вне оркестратора (`checkTaskAlreadyRunToday`, `guardAgainstDuplicate`).
- **Параметры родителя приоритетнее решения LLM** (`dynamic_params` не перезаписывают `logId`).
- **Порядок выкладки.** `docs.sp_loe_earved` и `docs.get_arve_kinnitaja` (SQL) выкладываются вместе с бэкендом: новая `get_arve_kinnitaja` читает только новый формат лога импорта.

Принудительный запуск: `--task <ключ>` сбрасывает указанную задачу и её потомков в `PENDING`, расписание для неё не проверяется, зависимости проверяются, предшественники не перезапускаются; для закрытого цикла нужен ещё `--force`. Для свежей выкачки: `--task getEarved`.

---

## Как добавить нового агента

Благодаря динамическому реестру агентов (`shared/agent_registry.ts`) и автообнаружению в `orchestrator/state.manager.ts`, правка кода оркестратора `orchestrator.agent.ts`, `state.manager.ts` или `shared/agent_registry.ts` **не требуется**:

1. Создать каталог `<agent>/` с `schemas.ts`, `tools.ts` (`start<Agent>` → `POST /task/<endpoint>/`), `agent.ts`, `config.json`, `<agent>.test.ts`.
2. В `<agent>/agent.ts` экспортировать `manifest: AgentManifest`:
   - `dispatch(ctx)`: вызов `start<Agent>` с передачей параметров (`userId`, `rekvId`, `kond`, `params`, `apiClient`).
   - `resolveParentParams(state)` (опционально): если нужны параметры от родительской задачи (например, `logId` от `getEarved`).
   - `enrichReportStep(stepLog, task)` (опционально): если нужно обогатить строку в сводном отчёте `reporter` (например, `mailErrors` или кастомный `resultSummary`).
3. В `<agent>/config.json` настроить `flow`, `schedule`, `depends_on`, `prompt` (`null` для детерминированного запуска по расписанию), `params` (включая индивидуальный `userId`, если процедура пишет в `ou.logs` под сервисным пользователем), `timeout_hours` (по умолчанию 12 часов). `Dockerfile` копирует все конфиги автоматически через стадию `/configs`.
4. При необходимости зарегистрировать Genkit flow в `index.ts`.
5. На стороне `buh70` реализовать эндпоинт `/task/<endpoint>/`: он должен писать в `ou.logs` под именем `flow` и возвращать `{ status, log_id }`.

## Правила для разработчика и AI-ассистента

- Не добавлять прямой доступ к PostgreSQL. Только через API бэкенда.
- Таймаут задач контролируется watchdog оркестратора (`timeout_hours` в `config.json`, по умолчанию 12 ч).
- Состояние писать только через `state.manager.ts` (атомарная запись).
- Изменения поведения по возможности делать через `config.json` / `prompt`, а не через код.
- Сообщения в логах и отчётах — на эстонском, комментарии в коде — на русском (так сложилось в проекте).
- Проверки: `npm run typecheck`, `npm test` (jest, `--runInBand`), `npm run build` (результат в `dist/`, копируется в Docker-образ).
- `.env` и `state/orchestrator_state.json`, `state/cron_tick.log` — рабочие файлы, не коммитить.


---

## Локальная синхронизация Äriregister и lookup (2026-11-18)

- **Источник и лицензия:** открытые данные `Äriregister (RIK), avaandmed, CC BY 4.0` (`ettevotja_rekvisiidid__lihtandmed.csv.zip`, обновляется ~05:00).
- **Персональные данные (FIE):** хранятся только реквизиты из открытого файла реестра (без личных кодов); цель обработки — проверка контрагентов.
- **Субагент `ariregister_sync`:** запускается раз в сутки в `06:00` (`Europe/Tallinn`) через `POST /task/syncAriregister/` (`flow: ariregisterSync`, авторизация по `INFOREGISTER_HASH` со scope `'sync'`), не зависит от цепочки FinBit. В отчёте выводит счётчики: `Äriregister: N kirjet, +ins / ~upd / -del`.
- **`inforegisterLookup` (`POST /task/inforegisterLookup/`) и пакетный `getInforegister` (`POST /task/getInforegister/`):** оба режима ищут организации в локальной таблице `libs.ariregister` (без вызова платного API Inforegister и без расхода годового лимита; при сохранении контрагентов пишется `mark = 'Äriregister (automaatselt lisatud)'`). `fetched_at` берётся из `libs.ariregister_meta.file_date`; поля `contacts` (`emails`/`phones`/`webs`) и `latestEmployeeCount` в открытых данных отсутствуют и возвращаются пустыми/`null`. Таблица `libs.registry_cache` больше не используется ни `lookup`, ни пакетным режимом (таблицу не удалять).
- **Порядок выкладки:** (1) SQL `sql/libs/create_table_ariregister.sql` и `sql/libs/libs.sp_ariregister_apply.sql`; (2) добавить scope `'sync'` нужному токену в `ou.config.properties.INFOREGISTER_TOKENS` (`rekvid = 3`); (3) выложить бэкенд `buh70` с `libs/ariregisterSync.js` и `POST /task/syncAriregister/`; (4) выполнить ручной первый запуск синка и проверить `SELECT count(*) FROM libs.ariregister;` и `SELECT * FROM libs.ariregister_meta;`; (5) переключить `inforegisterLookup` на локальную таблицу; (6) пересобрать и выложить `ai_task` (`npm run build`).

---

## Проверка актуальности организаций `asutus_kehtivus` (2026-11-19)

- **Назначение:** дочерний агент `ariregister_sync` (`depends_on: ["ariregister_sync"]`, `schedule: null`). Вызывает `POST /task/checkAsutusKehtivus/` (`flow: checkAsutusKehtivus`, авторизация по `INFOREGISTER_HASH` со scope `'sync'`) для поиска активных контрагентов `libs.asutus` с 8-значным `regkood`, которые закрыты или удалены в Äriregister, и простановки `properties->>'kehtivus'` через `libs.set_asutuse_kehtivus`.
- **Правила отбора** (выбираются только активные карточки `libs.asutus` со `staatus < 3`, ровно 8-значным `regkood ~ '^[0-9]{8}$'`, у которых `properties->>'kehtivus'` пустой, не дата `YYYY-MM-DD` или дата больше `current_date`):
  - **Правило A (удалена в реестре):** запись найдена в `libs.ariregister` и заполнено `r.deleted_at IS NOT NULL` → устанавливается `kehtivus = r.deleted_at::date` (или текущий день `Europe/Tallinn`, если дата не задана).
  - **Правило B (отсутствует в реестре):** запись отсутствует в `libs.ariregister` (`r.regkood IS NULL`), при одновременном выполнении условий `inforegisterService.matchesNotInRegistryRule(regkood, aadress)`: 8-значный `regkood` начинается на `1`, `8` или `9` (`^[189]`), проходит проверку контрольной цифры (`isValidRegCodeChecksum`) **и** адрес не содержит иностранных маркеров (`!isForeignAddress(a.aadress)`, пустой адрес допускается) → устанавливается `kehtivus = текущий день` (`Europe/Tallinn`).
  - **Исключения (не закрываются):** организации в процессе ликвидации/банкротства (`Likvideerimisel` / `Pankrotis`, пока в `libs.ariregister` `deleted_at IS NULL`), коды на `7` (`7x` — госучреждения/муниципалитеты), коды с неверной контрольной цифрой, иностранные организации (`isForeignAddress`), а также карточки с уже проставленной датой `kehtivus <= current_date`.
- **Извещения (email) и утренний отчёт:**
  - В `asutus_kehtivus/config.json` задан `params.extraEmails: ["vladislav.gordin@gmail.com", "jelena.tsekanina@narva.ee", "svetlana.tsaikina@narva.ee"]`, который агент передаёт на бэкенд как `extra_emails` (`POST /task/checkAsutusKehtivus/` также принимает `notify_emails`). Если `extra_emails` не передан, для обоих режимов (`dry_run: true` и `dry_run: false`) используется тот же список `DEFAULT_EMAILS`.
  - SMTP и отправитель настраиваются так же, как в рассылке FinBit (`sendFinBitReport.getRobotSmtpConfig(rekvId)`): берётся карточка `ou.userid` с `kasutaja = 'Earved robot'` (`status < 3`, приоритет `rekvid` из запроса, затем `63`), отправитель формируется как `<user>@narva.ee` (по умолчанию `palk@narva.ee`), поле `properties.email` карточки не используется.
  - При реальном закрытии в `result.closed` и в письмо попадают `regkood` и `nimetus` из ответа функции `libs.set_asutuse_kehtivus` (если функция вернула `[]`, карточка попадает только в `skipped_already`). При `dry_run: true` и `candidates_total > 0` уходит письмо `[DRY RUN]` с `would_close`; при `> 200` строк в теле выводятся первые 200 и прикладывается полный `asutuste_kehtivus.csv`. При `0` кандидатов и `registry_stale` письмо не отправляется. Результат отправки (включая `error` и `skipped`) сохраняется в `ou.logs.propertis.mail` (с защитой от дубля по `log_id`); ошибка письма не делает лог `failed`.
  - В утреннем отчёте (`enrichReportStep`) пробный прогон (`dry_run: true`) выводится как `Proovikäivitus (dry-run): leitud N kandidaati, andmebaasis muudatusi ei tehtud` (без слов о закрытии), а реальное закрытие — как `Suletud kaarte: N`.
- **Защитные механизмы (guards):**
  - **Актуальность и полнота реестра:** проверка `libs.ariregister_meta` — `applied_at` в часовом поясе `Europe/Tallinn` должен быть равен сегодняшней дате (`applied_at::Europe/Tallinn = today`), а `rows_total >= 300000` (иначе эндпоинт возвращает `skipped` / `registry_stale`).
  - **Advisory lock:** PostgreSQL advisory lock (`707002`) предотвращает параллельный запуск (при занятом локе возвращается HTTP `409`).
  - **Лимит за запуск и безопасный режим:** `maxClose: 100` (`max_close`, допустимый диапазон `0..5000`, больше — `400 invalid_max_close`) ограничивает число закрываемых записей за один реальный прогон (если кандидатов > `maxClose`, задача завершается `failed` с `reason: too_many_candidates`, `retryable: false`, ничего не закрывая); в `asutus_kehtivus/config.json` по умолчанию задан `dryRun: true`.
- **Права сервисного пользователя:** для выполнения `libs.set_asutuse_kehtivus` от имени сервисного пользователя `11770` требуется роль `is_asutuste_korraldaja = true` в `ou.userid` (миграция `sql/ou/grant_asutuste_korraldaja_ai_task.sql`).
- **Порядок перехода к реальному закрытию:**
  1. Выполнить миграцию `sql/libs/libs.set_asutuse_kehtivus.sql` и `sql/ou/grant_asutuste_korraldaja_ai_task.sql` на целевой БД.
  2. Выложить обновлённый бэкенд `buh70` (`libs/asutusKehtivusService.js`, `routes/raama/checkAsutusKehtivus.js`, `routes/index.js`) и `ai_task` (`npm run build`).
  3. Проверить работу утренних пробных прогонов (`dryRun: true`).
  4. Выполнить разовое ручное первое закрытие с повышенным `max_close` (например, `2000`):
     ```powershell
     curl.exe -X POST http://<host>:3000/task/checkAsutusKehtivus/ -H "Content-Type: application/json" -d "{\"hash\":\"<INFOREGISTER_HASH>\",\"dry_run\":false,\"max_close\":2000}"
     ```
  5. Переключить `"dryRun": false` в `asutus_kehtivus/config.json`, затем пересобрать Docker-образ `ai_task` (`config.json` вшит в образ).
