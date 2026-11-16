# Walkthrough: Реализация AI-Оркестратора с памятью состояния и параллельным DAG

Реализована архитектура квантованного запуска по расписанию (Stateless Cron-driven Runner) с механизмом памяти состояния (State Dump Memory) и графом зависимостей (DAG) для параллельного исполнения потоков в директории `c:\development\buh70\routes\ai\ai_task`.

---

## 1. Архитектура и структура проекта

> Исторический срез структуры и числа тестов по файлам на момент первой версии (часть агентов — `getEarved`, `sendFinBitReport`, `import_earved`, `check_asutus`, `inforegister`, `read_mail`, `schedule_monitor` — в дереве не показана). Актуальное общее число тестов — в разделе 3.

```
ai_task/
├── ai_task.md                  # Полная спецификация микросервиса
├── package.json                # Скрипты и зависимости (Genkit, TypeScript, Zod, Jest)
├── tsconfig.json               # Конфигурация TypeScript (ES2022, commonjs)
├── jest.config.js              # Настройки тестирования Jest (ts-jest)
├── Dockerfile                  # Контейнеризация для Cloud Run (WORKDIR /app)
├── .env.example                # Шаблон переменных окружения
├── index.ts                    # Точка входа: CLI (тик / полный запуск) + Genkit Flows
│
├── state/                      # Хранилище дампа состояния (State Memory)
│   ├── .gitkeep                # Фиксация каталога в git
│   └── orchestrator_state.json # Файл состояния текущего расчетного цикла
│
├── shared/                     # Общие модули
│   ├── types.ts                # Интерфейсы ответов API, AppConfig, TaskStatus
│   └── api_client.ts           # HTTP POST клиент (fetch, AbortController, Retry)
│
├── calc_arv_jaak/              # Новый субагент пересчета остатков счетов (параллельный поток)
│   ├── schemas.ts              # Zod-схемы входных/выходных данных
│   ├── tools.ts                # Вызов POST /task/calcArvJaak/ (flow: docs.check_arv_jaak)
│   ├── agent.ts                # Логика запуска и ожидания задачи
│   └── calc_arv_jaak.test.ts   # 2 модульных теста
│
├── saldoandmik/                # Субагент расчета сальдоандмика
│   ├── schemas.ts              # Zod-схемы
│   ├── tools.ts                # Вызов POST /task/calcKondSaldoandmik/ (flow: eelarve.sp_koosta_saldoandmik)
│   ├── agent.ts                # Логика запуска
│   └── saldoandmik.test.ts     # 2 модульных теста
│
├── lisa1_lisa5/                # Субагент контроля Lisa 1 / Lisa 5 (зависит от saldoandmik)
│   ├── schemas.ts              # Zod-схемы
│   ├── tools.ts                # Вызов POST /task/calcLisa1Lisa5/ (flow: eelarve.salvesta_lisa_1_5_kontrol)
│   ├── agent.ts                # Логика запуска
│   └── lisa1_lisa5.test.ts     # 2 модульных теста
│
├── logs_watcher/               # Субагент мониторинга логов
│   ├── schemas.ts              # Схемы статусов логов
│   ├── tools.ts                # Вызов POST /task/read_log/:user_id/:task_name
│   ├── agent.ts                # Разовая проверка checkTaskStatus + цикл ожидания watchTaskUntilDone
│   └── logs_watcher.test.ts    # 4 модульных теста
│
├── reporter/                   # Субагент итоговой отчетности
│   ├── schemas.ts              # Схемы отчета
│   ├── tools.ts                # Генерация HTML/Markdown, отправка через Nodemailer (SMTP)
│   ├── agent.ts                # Логика субагента отчетов
│   └── reporter.test.ts        # 4 модульных теста
│
└── orchestrator/               # Главный координирующий оркестратор
    ├── orchestrator.schemas.ts # Схемы TaskState, OrchestratorState, OrchestratorTick
    ├── state.manager.ts        # Менеджер состояния: чтение, валидация по Zod, запись и сброс цикла
    ├── orchestrator.tools.ts   # Проверка истории выполнения за сегодня
    ├── orchestrator.agent.ts   # Исполнитель тика runOrchestratorTick + обратная совместимость runOrchestrator
    └── orchestrator.test.ts    # 7 тестов (FSM тики, параллельный старт, DAG, пропуск при сбое)
```

---

## 2. Реализованная логика

### 2.1. Память состояния (State Dump Memory)
- Состояние расчетного цикла сохраняется в `state/orchestrator_state.json`.
- В структуре состояния для каждого потока фиксируются:
  - `flow`: имя процедуры в `ou.logs`
  - `depends_on`: список задач-предшественников
  - `allow_parallel`: признак допустимости одновременного исполнения
  - `status`: `PENDING` | `RUNNING` | `SUCCESS` | `FAILED` | `SKIPPED`
  - `log_id`, `started_at`, `finished_at`, `duration_ms`, `error`
- Атомарная запись через временный файл исключает повреждение JSON при аварийной остановке.

### 2.2. Квантованный запуск (Stateless FSM Tick Runner)
- Процесс запускается внешней службой (Cron каждые 5 минут, `node dist/index.js` или `orchestratorTickFlow`).
- При каждом запуске оркестратор:
  1. Читает `orchestrator_state.json`.
  2. Проверяет суточный барьер (если статус `COMPLETED` и время `< next_scheduled_run` — мгновенный выход с кодом `0` без вызовов API).
  3. Проверяет час начала расчетного окна (по умолчанию `20:00`).
  4. Параллельно опрашивает статус всех задач со статусом `RUNNING` через разовые запросы `POST /task/read_log/...`.
  5. Разрешает граф зависимостей `depends_on`: выявляет готовые к запуску задачи `PENDING` (или помечает `SKIPPED` при сбое предшественников).
  6. Параллельно запускает все готовые задачи (`saldoandmik` и `calc_arv_jaak` стартуют одновременно в 20:00).
  7. При завершении всех расчетных задач вызывает `reporter`, переводит цикл в `COMPLETED` и рассчитывает `next_scheduled_run = завтра 20:00`.
  8. Сохраняет состояние и немедленно завершает процесс.

---

## 3. Результаты тестирования

> Исторический срез на момент первой версии. Актуально на 2026-11-16 (`npx jest`): **15 сьютов, 190 тестов, все PASS**.

Все 6 наборов тестов успешно проходят (21 тест):

```
PASS calc_arv_jaak/calc_arv_jaak.test.ts (2 теста)
PASS orchestrator/orchestrator.test.ts (7 тестов)
PASS reporter/reporter.test.ts (4 теста)
PASS logs_watcher/logs_watcher.test.ts (4 теста)
PASS saldoandmik/saldoandmik.test.ts (2 теста)
PASS lisa1_lisa5/lisa1_lisa5.test.ts (2 теста)

Test Suites: 6 passed, 6 total
Tests:       21 passed, 21 total
```

Сборка TypeScript (`npm run build` -> `tsc`) завершается без ошибок.

---

## 4. Реестр агентов (Agent Registry) и Watchdog таймаутов

### 4.1. Реестр субагентов (`shared/agent_registry.ts`)
- Введен интерфейс `AgentManifest` (`dispatch`, `resolveParentParams`).
- Каждый агент экспортирует свой манифест в `agent.ts`.
- `buildAgentRegistry()` сканирует директории и динамически загружает манифесты.
- В `orchestrator.agent.ts` убран хардкод `dispatchTaskByKey` и проброса `logId` от `getEarved` к `sendFinBitReport`.
- Dockerfile обновлен для автоматического сбора всех `config.json` без ручного перечисления.

### 4.2. Watchdog таймаутов (`timeout_hours`, по умолчанию 12 часов)
- В схему `AgentConfig` и `TaskState` добавлен параметр `timeout_hours` (число часов, по умолчанию 12).
- При превышении таймаута для зависшей в `RUNNING` задачи (без `exec_end` в `ou.logs`) фиксируется событие `TASK_TIMEOUT`.
- Выполняется попытка повторного запуска (до `max_attempts`), либо задача переводится в `FAILED`.
- Зависшая задача больше не блокирует завершение цикла и наступление следующего календарного дня.

### 4.3. Выборка e-счетов `getEarved` (текущая дата - 5 дней)
- Функция `getDefaultDateQueryFrom()` в `getEarved/schemas.ts` вычитает 5 дней (`d.setDate(d.getDate() - 5)`; в первой версии было 2 дня).
- Схемы и unit-тесты приведены в соответствие.

### 4.4. Перевооружение задач по расписанию и таймзоны
- Задачи с `schedule` автоматически переводятся в `PENDING` при смене календарных суток (`TASK_REARMED`).
- `isTaskScheduleReady` использует точный расчет в целевой временной зоне (`Intl.DateTimeFormat` по `timezone`, по умолчанию `Europe/Tallinn`).
- Проверка `allow_parallel: false` предотвращает запуск финализатора (`reporter`) при активных параллельных вычислениях.

### 4.5. Служебный субагент `schedule_monitor`
- Создан изолированный модуль `schedule_monitor/` (`schemas.ts`, `tools.ts`, `agent.ts`, `schedule_monitor.test.ts`) — **без `config.json`**.
- Агент исключён из графа задач через `EXCLUDED_NON_DAG_DIRS` (`shared/excluded_dirs.ts`); экспортирует `manifest`, но оркестратор вызывает его напрямую (`invokeScheduleMonitorSafe`), а не через `dispatchTaskByKey`.
- Функция `buildScheduleSnapshot` формирует детальный срез графа: статусы, причины планирования (`SCHEDULE_TODAY`, `SCHEDULE_TOMORROW`, `AFTER_DEPENDENCIES`, `RETRY`, `RUNNING_NOW`), дедлайны таймаутов `timeout_deadline`, усеченные ошибки и счетчики `summary`.
- Функция `logAgentSchedule` вызывает `POST /task/logAgentSchedule/` для синхронной записи среза в `ou.logs` под flow `ai_task.agent_schedule`.
- Зарегистрированы Genkit flows: `scheduleMonitorFlow` и `agentScheduleFlow` в `index.ts` с поддержкой автономного вызова и чтения состояния.
- В `orchestrator.agent.ts` внедрен безопасный вызов `invokeScheduleMonitorSafe` на каждом выходе тика (включая ранние выходы `IDLE_WAIT_NEXT_SCHEDULE`).
- Конфигурация в `orchestrator/config.json` (`schedule_monitor.enabled`, по умолчанию `true`).

### 4.6. Синхронный поиск `inforegisterLookup` и авторизация по `hash`
- На бэкенде `buh70` логика вынесена в общий сервис `libs/inforegisterService.js`; `routes/raama/getInforegister.js` и новый маршрут `POST /task/inforegisterLookup/` (`routes/raama/inforegisterLookup.js`) работают как тонкие обёртки.
- В `libs/inforegister.js` добавлена опция `skipCacheRead` (для `force_refresh: true`) и возврат `fetchedAt` из кэша/API; повторные запросы в течение 30 дней обслуживаются из `libs.registry_cache`.
- Оба маршрута защищены hash-токенами из `ou.config.properties.INFOREGISTER_TOKENS` (`rekvid = 3`, хранится только SHA-256, проверка через `crypto.timingSafeEqual` и `scopes: ['batch'|'lookup']`, SQL `sql/ou/add_inforegister_token.sql`).
- В `ai_task` добавлена переменная `INFOREGISTER_HASH` (`.env` / `getConfig().inforegisterHash`), `manifest.validatePrerequisites` (SKIP при отсутствии `INFOREGISTER_HASH`), `lookupInforegister` (`inforegister/tools.ts`), Genkit flow `inforegisterLookupFlow` (`index.ts`, схема без `hash`) и CLI `npm run inforegister-lookup`.

### 4.7. Результаты тестирования (актуально на 2026-11-16)
- `routes/ai/ai_task` (`npx jest`): **15 сьютов, 209 тестов, все PASS** (`npx tsc --noEmit` и `npm run build` — 0 ошибок).
- В `orchestrator` внедрён снимок `task.last_run` (`LastRunSchema`, `snapshotLastRun`) при сбросах `TASK_REARMED` / `TASK_RESET_MANUAL` / `CYCLE_RESET_NEW_DAY` (включая миграцию устаревшего `previous_cycle_failures`), чтобы утренний `reporter` (08:00) корректно отображал вечерние задачи цикла 20:00 (`saldoandmik`, `lisa1_lisa5`) и вчерашние `FAILED` в окне 24 ч.
- Бэкенд `buh70` (`npx jest getInforegister.test.js inforegisterService.test.js inforegisterLookup.test.js`): **3 сьюта, 32 теста, все PASS**.
