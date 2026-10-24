# AGENT.md — роли агентов `ai_task`

Автономный микросервис (Genkit + TypeScript), который планирует, запускает и контролирует регламентные расчётные процессы `buh70`.
Полная спецификация — `ai_task.md`, история реализации — `walkthrough.md`. Этот файл — краткая карта агентов и правила работы с ними.

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
read_mail (06:00)
getEarved (07:00) ──► sendFinBitReport
calc_arv_jaak (07:30)
reporter (08:00) [ежедневный сводный отчет за последние 24 часа]
saldoandmik (20:00) ──► lisa1_lisa5
```

Статусы задач: `PENDING → RUNNING → SUCCESS | FAILED | SKIPPED`. Статусы цикла: `IDLE | IN_PROGRESS | COMPLETED | FAILED`.
Если предшественник в `FAILED`/`SKIPPED`, зависимые задачи каскадно переводятся в `SKIPPED`. Повторы: до `max_attempts` (по умолчанию 3), когда в логе нет `exec_start`, при ошибках или по watchdog таймаута (`timeout_hours` в `config.json`, по умолчанию 12 часов — `TASK_TIMEOUT`).

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
5. Инспекция `RUNNING`-задач и **result decision** (`evaluateTaskResultDecision`): глубокий разбор `result`. Если у агента есть `prompt`, вердикт о `SUCCESS`/`FAILED` выносит LLM. Затем повтор или `FAILED`.
6. **Launch decision** для `PENDING` (`evaluateTaskLaunchDecision`): LLM (`RUN | WAIT | SKIP` + `dynamic_params`) либо FSM (`depends_on`, `schedule.time/day/month`, суточное окно, **Downstream Lock**: блокировка запуска в `WAIT`, если любая зависимая задача находится в статусе `RUNNING`).
7. Параллельный запуск готовых задач через `dispatchTaskByKey` (с предварительной защитой от параллельного дубля `guardAgainstDuplicate`). Для зависимых задач пробрасываются параметры родителя через `manifest.resolveParentParams(state)` (например, `state.tasks.getEarved.log_id → params.logId` для `sendFinBitReport`).
8. По расписанию в 08:00 запускается `reporter`, который опрашивает `ou.logs` за последние 24 часа по всем расчётным агентам (`exec_start`, `exec_end`, `durationMs`, `status`, ошибки/итоги), вызывает `manifest.enrichReportStep(stepLog, task)` для агент-специфичного обогащения отчёта и отправляет email-отчет. После завершения всех задач суточный цикл переходит в `COMPLETED` с выставлением актуального `next_scheduled_run`.

### 2. `logs_watcher/` — наблюдатель логов (служебный субагент)

- `tools.ts → readTaskLog`: `POST /task/read_log/:user_id/:task_name`.
- `agent.ts → inspectLogExecutionResult`: глубокая инспекция `error`/`result`/`response`. Ищет скрытые ошибки при формальном `status: success` (например, `success: false` или `connect ETIMEDOUT` в элементах массива). Возвращает `hasErrors`, `errorDetails`, `resultSummary`.
- `agent.ts → watchTaskUntilDone`: блокирующий цикл опроса (`TASK_POLL_INTERVAL_MS`, `TASK_TIMEOUT_MS`). Используется только в `--full`-режиме и в `run*Subagent`.
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

| Агент | Endpoint | Flow в `ou.logs` | Зависимости | Расписание | Prompt | Роль |
|---|---|---|---|---|---|---|
| `saldoandmik` | `/task/calcKondSaldoandmik/` | `eelarve.sp_koosta_saldoandmik` | — | 20:00 | нет | Сводный сальдоандмик (`user_id`, `rekv_id`, `kond`) |
| `calc_arv_jaak` | `/task/calcArvJaak/` | `docs.check_arv_jaak` | — | 07:30 | нет (`prompt_test` для теста) | Пересчёт сальдо и остатков счетов (вне регламентного цикла) |
| `read_mail` | `/task/readMail/` | `mail.read_mail_errors` | — | 06:00 | нет (`prompt: null`) | Анализ входящей почты на ошибки недоставки счетов клиентам (Mail Delivery Failure). Снимает отметку отправки в БД (`docs.tuhista_arve_saatmise_staatus`) и отправляет алерт при `Muud vead` |
| `lisa1_lisa5` | `/task/calcLisa1Lisa5/` | `eelarve.salvesta_lisa_1_5_kontrol` | `saldoandmik` | — | нет | Контрольные формы Lisa 1 / Lisa 5 |
| `getEarved` | `/task/getEarved/` (`is_agent: true`, опц. `date_query_from`) | `docs.sp_loe_earved` | — | 07:00 | нет | Импорт e-счетов из FinBit (`params.userId: 11770` — сервисный аккаунт FinBit в buh70). Пишет в `ou.logs` подробный `result` (`totalFetched`, `totalImported`, `invoiceNumbers`, `batches`) и `response`. Ответ `Arveid ei leitud` считается успехом с `log_id = 0` |
| `sendFinBitReport` | `/task/sendFinBitReport/` (`logId`) | `sendFinBitReport` | `getEarved` | — | **да** (оценка результата рассылки) | Дочерний агент `getEarved`: рассылает уведомления получателям импортированных счетов. Без `logId` родителя пропускается (`SKIP`) |

### 3.1. `read_mail/` — монитор недоставки счетов по e-mail (расчётный субагент)

- **Назначение:** Автономная обработка сообщений о сбоях доставки электронной почты со счетами покупателям (NDR / Non-Delivery Reports / Bounce notices: `Mail Delivery Subsystem`, `Mailer-Daemon`, `Undelivered Mail Returned to Sender`).
- **Схема работы:**
  1. Вызывается оркестратором через API `POST /task/readMail/` ежедневно в 06:00 (до сводного отчета в 08:00). В `read_mail/config.json` задан `"prompt": null`, чтобы оркестратор запускал задачу строго по детерминированному расписанию `06:00`.
  2. Подключается к IMAP-серверу входящей почты и инкрементально считывает новые bounce-сообщения (дата последнего чтения фиксируется в `state/read_mail_state.json`).
  3. Парсит тело письма и диагностические заголовки/коды SMTP (`RFC 3464` / `RFC 2047`), определяя номер счета (`doc_number`), адрес получателя (`recipient_email`) и причину ошибки.
  4. Классифицирует ошибку по 4 стандартным статусам:
     - `Aadressi viga` — некорректный или несуществующий ящик получателя (`5.1.1`, User unknown, Invalid mailbox, No such user).
     - `Domeeni viga` — недоступный или несуществующий почтовый домен (`5.1.2`, Host/Domain not found, DNS error).
     - `Postkast täis` — переполнение почтового ящика клиента (`5.2.2`, Quota exceeded, Mailbox full).
     - `Muud vead` — любые прочие нестандартные сбои (спам-блокировки `5.7.1`, временные сетевые отказы, отказы ретрансляции и т.д.).
  5. Для каждого проблемного счета вызывает в БД процедуру `docs.tuhista_arve_saatmise_staatus(doc_id, doc_number, reason)`, сбрасывая признак отправки счета, чтобы в учетной системе бухгалтер увидел необходимость актуализации контакта или повторной отправки.
  6. **Мгновенные алерты (Alerting):** Если ошибка отнесена к категории `Muud vead` (не подпадающей под типовые правила), агент немедленно отправляет e-mail уведомление с перечнем проблемных счетов (номер счета, email, причина) администраторам на адреса `vladislav.gordin@gmail.com` и `andrei.vargunin@narva.ee`.
  7. Фиксирует полный структурированный результат разбора в `ou.logs` (`flow = 'mail.read_mail_errors'`) под ключом `result`, откуда его подхватывает `reporter` через хук `manifest.enrichReportStep`.
- **Архитектурная реализация:**
  - Полностью **in-process на бэкенде `buh70` (Node.js 13.14.0)** через встроенный низкоуровневый TLS-клиент (`tls`), без внешних npm-библиотек и без вызова внешних процессов/воркеров.
  - Поддерживает безопасную потоковую работу с UTF-8 буквами и IMAP literal buffers (`Buffer.byteLength`).

### 4. `reporter/` — итоговая отчётность

- `agent.ts → generateAndSendReportSubagent`, `tools.ts`: `formatReportMarkdown`, `formatReportHtml`, `sanitizeReportText`, `sendReportEmail` (nodemailer, `SMTP_*`, `REPORT_EMAIL_FROM/TO`).
- **Строгий запуск 1 раз в сутки в 08:00:** Запускается оркестратором строго по расписанию в 08:00 (даже если цикл запущен с `forceRun`, расписание `08:00` у `reporter` соблюдается, если не передан явно `taskKey: 'reporter'`).
- **Защита от повторного запуска в 17:00 / во второй половине дня:** После успешной отправки отчёта (`status: 'SUCCESS'` и `finished_at` за сегодняшний день) повторный запуск в текущих сутках блокируется (`!isReporterAlreadyRunToday`). Агент `reporter` исключён из сверки `ou.logs` (Step 1.4), так как является нотификатором и не пишет в `ou.logs` (что ранее приводило к сбросу в `PENDING` и ложному запуску в 17:00). Кроме того, `resetCycleForNewDay` сохраняет статус выполненных за сегодняшний день задач.
- Опрашивает `ou.logs` за последние 24 часа по всем расчётным агентам (`saldoandmik`, `calc_arv_jaak`, `getEarved`, `sendFinBitReport`, `read_mail`, `lisa1_lisa5`) с учётом их индивидуального `params.userId`.
- **Интеграция с агентами через `enrichReportStep`:** Оркестратор вызывает `registry[key]?.enrichReportStep?.(stepLog, task)`. Для `read_mail` этот хук извлекает ошибки недоставки счетов из `mail.read_mail_errors` (`mailErrors`) и формирует эстонский `resultSummary`, а `reporter` включает в ежедневный отчет отдельную таблицу **«📧 Tuvastatud vigased e-posti aadressid»** (`Arve nr`, `Saaja e-post`, `Staatus`, `Põhjus`).
- Получает по каждому шагу статус, `logId`, длительность, `error`, `resultSummary` и `overallSuccess`.
- Вызывается не через `dispatchTaskByKey`, а в отдельном блоке тика. `allow_parallel: false`.

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
