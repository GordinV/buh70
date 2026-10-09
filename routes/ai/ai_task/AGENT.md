# AGENT.md — роли агентов `ai_task`

Автономный микросервис (Genkit + TypeScript), который планирует, запускает и контролирует регламентные расчётные процессы `buh70`.
Полная спецификация — `ai_task.md`, история реализации — `walkthrough.md`. Этот файл — краткая карта агентов и правила работы с ними.

## Базовые принципы

- **Только API, без доступа к БД.** Все агенты общаются с бэкендом `buh70` через `HTTP POST` (`shared/api_client.ts`, `BUH70_API_BASE_URL` + `BUH70_API_TOKEN`). Хранимые процедуры вызываются внутри эндпоинтов `/task/*` бэкенда.
- **Tick-based FSM.** Оркестратор не является демоном. Cron запускает `run_tick.sh` (docker `buh70-ai-task`, `flock`-блокировка), выполняется один тик, состояние сохраняется в `state/orchestrator_state.json`, и процесс завершается.
- **Неблокирующий запуск.** Эндпоинты запуска создают запись в `ou.logs`, стартуют фоновую процедуру и сразу возвращают `log_id`. Статус задачи проверяется на следующих тиках через `POST /task/read_log/:user_id/:task_name`.
- **Конфигурация без пересборки.** `orchestrator/config.json` и `<agent>/config.json` читаются на каждом тике: время, зависимости, `prompt`, `params`.
- **Два режима решений.** Если в конфиге задан `prompt`, решение принимает Gemini (`ai.generate`, structured output). Если `prompt: null`, работают детерминированные правила FSM. Без `GEMINI_API_KEY` LLM не используется. Ключ `mock_*` включает эмуляцию LLM (`index.ts`).

## Граф задач (DAG)

```
getEarved (07:00) ──► sendFinBitReport ─┐
calc_arv_jaak (07:30) ──────────────────┤
saldoandmik (20:00) ──► lisa1_lisa5 ────┼──► reporter (когда все задачи в терминальном статусе)
                                        ┘
```

Статусы задач: `PENDING → RUNNING → SUCCESS | FAILED | SKIPPED`. Статусы цикла: `IDLE | IN_PROGRESS | COMPLETED | FAILED`.
Если предшественник в `FAILED`/`SKIPPED`, зависимые задачи каскадно переводятся в `SKIPPED`. Повторы: до `max_attempts` (по умолчанию 3), когда в логе нет `exec_start`, при ошибках или по watchdog таймаута (`timeout_hours` в `config.json`, по умолчанию 12 часов — `TASK_TIMEOUT`).

---

## Роли

### 1. `orchestrator/` — главный координатор (Meta-agent)

| | |
|---|---|
| Точка входа | `runOrchestratorTick` (`orchestrator.agent.ts`); Genkit flow `orchestratorTickFlow`; CLI `node dist/index.js [--force] [--user N] [--rekv N] [--date YYYY-MM-DD] [--state path]` |
| Устаревший режим | `runOrchestrator` / `--full`: последовательный блокирующий прогон всех субагентов с `watchTaskUntilDone` |
| Конфиг | `orchestrator/config.json`: `daily_start_time` (20:00), `timezone` (Europe/Tallinn), `max_task_attempts`, `params`, `prompt` |
| Состояние | `state.manager.ts` — чтение/валидация (Zod)/атомарная запись `state/orchestrator_state.json`, сброс при смене дня |

Обязанности за один тик:
1. Загрузить конфиги всех агентов и слить их с состоянием. Новый агент получает `PENDING`.
2. Проверить смену календарного дня и при необходимости начать новый цикл со сброшенными `attempts`.
3. **Cycle decision** (`evaluateCycleDecision`): LLM по `prompt` возвращает `RUN_CYCLE | WAIT_SCHEDULE | SKIP_CYCLE | PAUSE_CYCLE` и `force_run`. На `localhost`/`127.0.0.1` цикл открывается сразу.
4. Сверка с `ou.logs` (`orchestrator.tools.ts → checkTaskAlreadyRunToday`): задача, уже выполненная сегодня (для задач с расписанием — с `exec_start >= schedule.time`), помечается `SUCCESS`.
5. Инспекция `RUNNING`-задач (`Promise.allSettled`) и **result decision** (`evaluateTaskResultDecision`): глубокий разбор `result`. Если у агента есть `prompt`, вердикт о `SUCCESS`/`FAILED` выносит LLM. Затем повтор или `FAILED`.
6. **Launch decision** для `PENDING` (`evaluateTaskLaunchDecision`): LLM (`RUN | WAIT | SKIP` + `dynamic_params`) либо FSM (`depends_on`, `schedule.time/day/month`, суточное окно).
7. Параллельный запуск готовых задач через `dispatchTaskByKey`. Для `sendFinBitReport` пробрасывается `logId` родителя: `state.tasks.getEarved.log_id → params.logId`.
8. Когда все расчётные задачи завершены, вызвать `reporter`, перевести цикл в `COMPLETED` и выставить `next_scheduled_run` на завтра, `daily_start_time`.

### 2. `logs_watcher/` — наблюдатель логов (служебный субагент)

- `tools.ts → readTaskLog`: `POST /task/read_log/:user_id/:task_name`.
- `agent.ts → inspectLogExecutionResult`: глубокая инспекция `error`/`result`/`response`. Ищет скрытые ошибки при формальном `status: success` (например, `success: false` или `connect ETIMEDOUT` в элементах массива). Возвращает `hasErrors`, `errorDetails`, `resultSummary`.
- `agent.ts → watchTaskUntilDone`: блокирующий цикл опроса (`TASK_POLL_INTERVAL_MS`, `TASK_TIMEOUT_MS`). Используется только в `--full`-режиме и в `run*Subagent`.
- Не имеет `config.json` и не входит в DAG.

### 2.1. `schedule_monitor/` — монитор расписания и статусов (служебный субагент)

- `agent.ts → buildScheduleSnapshot`: чистая функция формирования среза состояния всех агентов графа (`status`, `schedule`, `next_planned_run`, `next_run_reason`, `timeout_deadline`, `attempts`, `log_id`, `error`).
- `tools.ts → logAgentSchedule`: вызов `POST /task/logAgentSchedule/` (`ou.logs`, `flow = 'ai_task.agent_schedule'`).
- `agent.ts → runScheduleMonitorSubagent`: основной исполнитель субагента (вход: `userId`, `rekvId`, опционально `state` или `stateFilePath`), возвращает `ScheduleMonitorResult` (`logId`, `status`, `snapshot`).
- `index.ts`: зарегистрированы Genkit flows `scheduleMonitorFlow` и `agentScheduleFlow` для запуска через Genkit CLI/Dev UI/Reflection API.
- `agent.ts → manifest`: экспортирует `manifest` для совместимости с реестром агентов.
- `agent.ts → runScheduleMonitor`: вызывается оркестратором на каждом тике (включая ранние выходы `IDLE_WAIT_NEXT_SCHEDULE`). Ошибки не прерывают тик.
- Не имеет `config.json` и не входит в DAG. Настраивается через `orchestrator/config.json` (`schedule_monitor.enabled`).

### 3. Расчётные субагенты (исполнители)

Все устроены одинаково: `schemas.ts` (Zod-вход/выход + константа `TASK_FLOW_*`), `tools.ts` (`start*` — неблокирующий POST), `agent.ts` (`run*Subagent` — запуск и ожидание через `logs_watcher`), `config.json`, тест.

| Агент | Endpoint | Flow в `ou.logs` | Зависимости | Расписание | Prompt | Роль |
|---|---|---|---|---|---|---|
| `saldoandmik` | `/task/calcKondSaldoandmik/` | `eelarve.sp_koosta_saldoandmik` | — | 20:00 | нет | Сводный сальдоандмик (`user_id`, `rekv_id`, `kond`) |
| `calc_arv_jaak` | `/task/calcArvJaak/` | `docs.check_arv_jaak` | — | 07:30 | нет (`prompt_test` для теста) | Пересчёт сальдо и остатков счетов |
| `lisa1_lisa5` | `/task/calcLisa1Lisa5/` | `eelarve.salvesta_lisa_1_5_kontrol` | `saldoandmik` | — | нет | Контрольные формы Lisa 1 / Lisa 5 |
| `getEarved` | `/task/getEarved/` (`is_agent: true`, опц. `date_query_from`) | `docs.sp_loe_earved` | — | 07:00 | нет | Импорт e-счетов из FinBit (userId: 11770 — сервисный аккаунт FinBit в buh70). Ответ `Arveid ei leitud` считается успехом с `log_id = 0` |
| `sendFinBitReport` | `/task/sendFinBitReport/` (`logId`) | `sendFinBitReport` | `getEarved` | — | **да** (оценка результата рассылки) | Дочерний агент `getEarved`: рассылает уведомления получателям импортированных счетов. Без `logId` родителя пропускается (`SKIP`) |

### 4. `reporter/` — итоговая отчётность

- `agent.ts → generateAndSendReportSubagent`, `tools.ts`: `formatReportMarkdown`, `formatReportHtml`, `sanitizeReportText`, `sendReportEmail` (nodemailer, `SMTP_*`, `REPORT_EMAIL_FROM/TO`).
- Запускается оркестратором, когда все остальные задачи в `SUCCESS | FAILED | SKIPPED`. `depends_on` в конфиге — перечень всех расчётных агентов.
- Получает по каждому шагу статус, `logId`, длительность, `error`, `resultSummary` и `overallSuccess` (нет ни одного `FAILED`).
- Вызывается не через `dispatchTaskByKey`, а в отдельном блоке тика. `allow_parallel: false`.

---

## Как добавить нового агента

Благодаря реестру агентов (`shared/agent_registry.ts`), правка кода оркестратора `orchestrator.agent.ts` больше **не требуется**:

1. Создать каталог `<agent>/` с `schemas.ts`, `tools.ts` (`start<Agent>` → `POST /task/<endpoint>/`), `agent.ts`, `config.json`, `<agent>.test.ts`.
2. В `<agent>/agent.ts` экспортировать `manifest: AgentManifest`:
   - `dispatch(ctx)`: вызов `start<Agent>` с передачей параметров (`userId`, `rekvId`, `kond`, `params`, `apiClient`).
   - `resolveParentParams(state)` (опционально): если нужны параметры от родительской задачи (например, `logId` от `getEarved`).
3. В `<agent>/config.json` настроить `flow`, `schedule`, `depends_on`, `timeout_hours` (по умолчанию 12 часов) и т.д. `Dockerfile` копирует все конфиги автоматически через стадию `/configs`.
4. Добавить агента в `depends_on` у `reporter/config.json`.
5. При необходимости зарегистрировать Genkit flow в `index.ts`.
6. На стороне `buh70` реализовать эндпоинт `/task/<endpoint>/`: он должен писать в `ou.logs` под именем `flow` и возвращать `{ status, log_id }`.

## Правила для разработчика и AI-ассистента

- Не добавлять прямой доступ к PostgreSQL. Только через API бэкенда.
- Таймаут задач контролируется watchdog оркестратора (`timeout_hours` в `config.json`, по умолчанию 12 ч).
- Состояние писать только через `state.manager.ts` (атомарная запись).
- Изменения поведения по возможности делать через `config.json` / `prompt`, а не через код.
- Сообщения в логах и отчётах — на эстонском, комментарии в коде — на русском (так сложилось в проекте).
- Проверки: `npm run typecheck`, `npm test` (jest, `--runInBand`), `npm run build` (результат в `dist/`, копируется в Docker-образ).
- `.env` и `state/orchestrator_state.json`, `state/cron_tick.log` — рабочие файлы, не коммитить.
