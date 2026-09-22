# Walkthrough: Реализация AI-Оркестратора с памятью состояния и параллельным DAG

Реализована архитектура квантованного запуска по расписанию (Stateless Cron-driven Runner) с механизмом памяти состояния (State Dump Memory) и графом зависимостей (DAG) для параллельного исполнения потоков в директории `c:\development\buh70\routes\ai\ai_task`.

---

## 1. Архитектура и структура проекта

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
