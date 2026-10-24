---
name: ai-task
description: >-
  Руководство по созданию, регистрации и конфигурации расчётных и служебных субагентов
  в автономном AI-оркестраторе `ai_task` (Google Genkit + TypeScript). Используйте этот скил
  при добавлении новых фоновых задач, настройке расписаний (`schedule`), графа зависимостей (DAG),
  защиты целостности (`Downstream Lock`), промптов LLM (`prompt`) и интеграции с эндпоинтами `/task/*` бэкенда `buh70`.
---

# Создание и конфигурация агентов в `ai_task`

Этот документ описывает пошаговый стандарт разработки и настройки агентов в автономном микросервисе [`ai_task`](file:///c:/development/buh70/routes/ai/ai_task) на основании архитектурной спецификации [`ai_task.md`](file:///c:/development/buh70/routes/ai/ai_task/ai_task.md), карты ролей [`AGENT.md`](file:///c:/development/buh70/routes/ai/ai_task/AGENT.md) и практик Genkit-оркестрации.

---

## 1. Архитектурные инварианты

При создании или изменении любого агента обязательно соблюдайте следующие правила:

1. **Zero Direct DB Access (Только HTTP POST API):**
   - Оркестратор и субагенты полностью изолированы от прямого подключения к PostgreSQL.
   - Все вызовы к СУБД и хранимым процедурам инкапсулированы на стороне бэкенда `buh70` в эндпоинтах `/task/<endpoint>/` и вызываются через `ApiClient` ([`shared/api_client.ts`](file:///c:/development/buh70/routes/ai/ai_task/shared/api_client.ts)).
2. **Асинхронный неблокирующий старт и Tick-based FSM:**
   - Оркестратор не является постоянно висящим в памяти демоном — он работает короткими атомарными тиками по Cron (`run_tick.sh`, каждые 5 минут с блокировкой `flock`).
   - Вызов запуска задачи (`manifest.dispatch`) в режиме тика **не ждёт** окончания расчёта в БД: бэкенд создаёт запись в `ou.logs`, запускает расчёт в фоне и немедленно возвращает `{ status: "STARTED", log_id: <number> }`.
   - Проверку завершения оркестратор выполняет на следующих тиках через `POST /task/read_log/:user_id/:task_name` (модуль [`logs_watcher`](file:///c:/development/buh70/routes/ai/ai_task/logs_watcher/agent.ts)).
3. **Динамический реестр без правки ядра оркестратора:**
   - Реестр [`shared/agent_registry.ts`](file:///c:/development/buh70/routes/ai/ai_task/shared/agent_registry.ts) и менеджер состояния [`orchestrator/state.manager.ts`](file:///c:/development/buh70/routes/ai/ai_task/orchestrator/state.manager.ts) автоматически обнаруживают каталоги агентов, читают `<agent>/config.json` и вызывают `manifest: AgentManifest` из `<agent>/agent.ts`.
   - Модифицировать [`orchestrator/orchestrator.agent.ts`](file:///c:/development/buh70/routes/ai/ai_task/orchestrator/orchestrator.agent.ts) при добавлении нового расчётного агента **не требуется**.
4. **Двухуровневое принятие решений (LLM Prompt-First + Deterministic FSM Fallback):**
   - Если в `config.json` задан `prompt`, решения о старте задачи (`evaluateTaskLaunchDecision`) и семантической оценке результата из `ou.logs` (`evaluateTaskResultDecision`) принимает модель Gemini через Genkit Structured Output (Zod).
   - Если `prompt: null` (или `GEMINI_API_KEY` не задан / произошёл сбой сети), автоматически срабатывает детерминированный fallback FSM (проверка `depends_on`, `schedule`, глубокий разбор ошибок в `result`/`error`/`response`).
5. **Защита целостности зависимостей (Downstream Lock):**
   - Запрещено запускать, перезапускать или перевооружать (`TASK_REARMED` в `PENDING`) родительскую задачу $A$, если любая зависимая от неё дочерняя задача $B$ (`B.depends_on.includes(A)`) в данный момент находится в статусе `RUNNING`.
6. **Штатная обработка пустых выборок (No-op / 0 записей):**
   - Отсутствие данных для обработки (например, 0 счетов FinBit за выходной день, `Arveid ei leitud`) должно фиксироваться как штатный `SUCCESS` (`log_id: 0` или закрытый лог со статусом `success`), а не как `HTTP 500`, чтобы не блокировать зависимые шаги графа.
7. **Языковые конвенции проекта:**
   - Комментарии в коде, описания Zod-схем и документация — **на русском языке**.
   - Сообщения в логах, резюме (`resultSummary`), причины пропуска и тексты для отчётов `reporter` — **на эстонском языке**.
8. **Требования к версиям Node.js и синтаксическая совместимость (Critical):**
   - **Микросервис `ai_task`:** разрабатывается на TypeScript / ES2022 и запускается в Docker-контейнере `buh70-ai-task` на базе **Node.js 20+ LTS (`node:20-alpine`)**. Здесь разрешены все возможности современного TS/ES.
   - **Основной бэкенд `buh70` (`routes/`, `models/`, `libs/`, запускаемый в PM2):** функционирует на **legacy Node.js (версии < 14)**.
   - При написании или рефакторинге эндпоинтов бэкенда (`.js`) **КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО** использовать операторы ES2020+:
     - Запрещен `??` (Nullish coalescing) ➔ вызывает `SyntaxError: Unexpected token ?`. Использовать явные проверки: `(val !== undefined && val !== null ? val : fallback)`.
     - Запрещен `?.` (Optional chaining) ➔ вызывает `SyntaxError: Unexpected token .`. Использовать `(obj && obj.prop)`.
   - Любое появление `??` или `?.` в коде бэкенда ломает запуск `app.js` в PM2 и приводит к падению сервера (`fetch failed`).

---

## 2. Типы агентов и текущий граф задач (DAG)

```text
read_mail (06:00)
getEarved (07:00) ──► sendFinBitReport
calc_arv_jaak (07:30)
reporter (08:00) [ежедневный сводный отчет за последние 24 часа]
saldoandmik (20:00) ──► lisa1_lisa5
```

В системе выделяются 3 категории модулей:
1. **Расчётные субагенты (входят в DAG, имеют `config.json` и `manifest`):**
   - `saldoandmik`, `calc_arv_jaak`, `read_mail`, `lisa1_lisa5`, `getEarved`, `sendFinBitReport`.
2. **Агент отчётности (`reporter/`):**
   - Имеет `config.json` (`allow_parallel: false`), опрашивает `ou.logs` за последние 24 часа по всем агентам (включая таблицу ошибок доставки почты из `read_mail`) и рассылает сводный HTML/Markdown отчёт по SMTP.
3. **Служебные субагенты (не входят в DAG, не имеют собственного `config.json`):**
   - `logs_watcher/` — чтение `POST /task/read_log/:user_id/:task_name` и глубокая инспекция `inspectLogExecutionResult`.
   - `schedule_monitor/` — формирование среза расписаний `buildScheduleSnapshot` и запись в `ou.logs` (`POST /task/logAgentSchedule/`, `flow = 'ai_task.agent_schedule'`). Управляется флагом `schedule_monitor.enabled` в `orchestrator/config.json`.

---

## 3. Структура каталога расчётного субагента

Каждый расчётный субагент изолируется в собственном подкаталоге `ai_task/<agent_name>/`:

```text
ai_task/<agent_name>/
├── config.json            # Декларативная конфигурация (flow, schedule, depends_on, timeout_hours, prompt, params)
├── schemas.ts             # Zod-схемы входных/выходных данных и константа TASK_FLOW_*
├── tools.ts               # Неблокирующий HTTP-вызов POST /task/<endpoint>/ через ApiClient
├── agent.ts               # Исполнитель run*Subagent (для --full/CLI) + экспорт manifest: AgentManifest
└── <agent_name>.test.ts   # Модульные тесты Jest
```

---

## 4. Конфигурация агента (`<agent>/config.json`)

Конфигурация валидируется схемой [`AgentConfigSchema`](file:///c:/development/buh70/routes/ai/ai_task/orchestrator/orchestrator.schemas.ts#L32-L43) на каждом тике оркестратора. Изменения в `config.json` подхватываются динамически без пересборки TypeScript-кода.

### 4.1. Поля `<agent>/config.json`

| Поле | Тип | По умолчанию | Описание |
|---|---|---|---|
| `name` | `string` | *(обязательно)* | Уникальный ключ агента (должен совпадать с именем папки `<agent_name>`) |
| `flow` | `string` | *(обязательно)* | Имя потока в таблице `ou.logs` (`propertis ->> 'flow'`), например `"eelarve.sp_koosta_saldoandmik"` |
| `description` | `string` | `undefined` | Краткое описание назначения субагента |
| `allow_parallel` | `boolean` | `true` | Разрешён ли параллельный запуск с другими готовыми задачами на одном тике (`false` для `reporter`) |
| `depends_on` | `string[]` | `[]` | Список имён агентов-предшественников в DAG. Агент стартует только когда все они в `SUCCESS` |
| `schedule` | `object \| null` | `null` | Индивидуальное расписание запуска (`{ time, day, month }`) или `null` (окно `daily_start_time`) |
| `prompt` | `string \| null` | `null` | Инструкция для LLM (принятие решения о запуске и семантическая проверка результата в `ou.logs`) |
| `max_attempts` | `number` | `3` | Лимит попыток запуска при ошибке в `ou.logs`, отсутствии `exec_start` или таймауте |
| `timeout_hours` | `number` | `12` | Порог watchdog-таймаута выполнения задачи в часах (`TASK_TIMEOUT`) |
| `params` | `object` | `{}` | Параметры по умолчанию, передаваемые в `ctx.params` (`userId`, `rekvId`, `kond` и др.) |

### 4.2. Настройка расписания (`schedule`) и часовых поясов

Схема [`TaskScheduleSchema`](file:///c:/development/buh70/routes/ai/ai_task/orchestrator/orchestrator.schemas.ts#L13-L25) работает по местному времени часового пояса из `orchestrator/config.json` (по умолчанию `"Europe/Tallinn"`):

1. **В рамках вечернего окна цикла (`"schedule": null`):**
   - Задача ожидает открытия суточного окна (`daily_start_time: "20:00"`) и/или завершения своих `depends_on` (пример: `lisa1_lisa5`, `sendFinBitReport`).
2. **Ежедневно в фиксированное время (`{ "time": "07:00" }`):**
   - Запускается каждый день на первом тике крона, когда локальное время `>= "07:00"`.
   - При сверке с `ou.logs` (`checkTaskAlreadyRunToday`) засчитываются только те сегодняшние запуски, у которых `exec_start >= schedule.time`.
3. **Ежемесячно в конкретный день (`{ "day": 1, "time": "06:00" }`):**
   - Запускается 1-го числа каждого месяца в `06:00` или позже. В остальные дни месяца задача переводится в `SKIPPED`.
4. **Ежегодно в точную дату (`{ "month": 1, "day": 15, "time": "22:00" }`):**
   - Запускается только при совпадении месяца и дня; в прочие дни получает статус `SKIPPED`.

> **Важно:** Для простого запуска по расписанию всегда используйте поле `schedule: { "time": "HH:mm" }` и оставляйте `"prompt": null`. Не кодируйте проверку часов текстом в `prompt`, чтобы избежать ошибок интерпретации UTC vs Local Time и лишнего расхода токенов.

### 4.3. Настройка `prompt` (AI-управление vs Детерминированный FSM)

- **Когда оставлять `"prompt": null`:**
  Для стандартных расчётных процедур СУБД (`saldoandmik`, `calc_arv_jaak`, `lisa1_lisa5`, `getEarved`), где достаточно проверки времени, готовности `depends_on` и отсутствия ошибок в `ou.logs`.
- **Когда задавать `"prompt": "<текст инструкции>"`:**
  Когда требуется семантический разбор сложного JSON-результата в `ou.logs -> 'result'`:
  - В `sendFinBitReport` модель анализирует массив статусов отправки писем (`success: false`, `connect ETIMEDOUT`) и формирует сводку с точными адресами получателей.
  - В `read_mail` модель классифицирует bounce-уведомления по 4 категориям: `'Aadressi viga'`, `'Domeeni viga'`, `'Postkast täis'`, `'Muud vead'`.

### 4.4. Примеры `config.json`

**Независимый агент с расписанием и без LLM (`saldoandmik/config.json`):**
```json
{
  "name": "saldoandmik",
  "flow": "eelarve.sp_koosta_saldoandmik",
  "description": "Расчет сводного сальдоандмика",
  "allow_parallel": true,
  "depends_on": [],
  "schedule": {
    "time": "20:00"
  },
  "prompt": null,
  "max_attempts": 3,
  "timeout_hours": 12,
  "params": {
    "userId": 2477,
    "rekvId": 63,
    "kond": 1
  }
}
```

**Зависимый агент с AI-промптом оценки результатов (`sendFinBitReport/config.json`):**
```json
{
  "name": "sendFinBitReport",
  "flow": "sendFinBitReport",
  "description": "Формирование и отправка email-уведомлений получателям импортированных счетов FinBit с передачей logId",
  "allow_parallel": true,
  "depends_on": [
    "getEarved"
  ],
  "schedule": null,
  "prompt": "Ты — AI-контролер регламентного процесса отправки отчетов по счетам sendFinBitReport системы buh70. Твоя задача — проанализировать результаты отправки email из логов. Если в массиве result есть ошибки (success: false, connect ETIMEDOUT, SMTP ошибки) или поле error не пустое, зафиксировать статус выполнения как FAILED, извлечь конкретные адреса получателей и текст ошибок, и сформировать информативное резюме для итогового отчета reporter. Если все письма успешно отправлены (success: true), подтвердить статус SUCCESS.",
  "max_attempts": 3,
  "params": {
    "userId": 2477,
    "rekvId": 63
  }
}
```

---

## 5. Конфигурация главного оркестратора (`orchestrator/config.json`)

Глобальное поведение цикла настраивается в [`orchestrator/config.json`](file:///c:/development/buh70/routes/ai/ai_task/orchestrator/config.json) (схема [`OrchestratorConfigSchema`](file:///c:/development/buh70/routes/ai/ai_task/orchestrator/orchestrator.schemas.ts#L49-L79)):

```json
{
  "name": "orchestrator",
  "description": "Главный координатор регламентных расчетных процессов buh70",
  "daily_start_time": "20:00",
  "timezone": "Europe/Tallinn",
  "max_task_attempts": 3,
  "params": {
    "userId": 2477,
    "rekvId": 63,
    "kond": 1
  },
  "prompt": "Ты — AI-руководитель регламентного расчетного сервиса buh70...",
  "schedule_monitor": {
    "enabled": true
  }
}
```

---

## 6. Пошаговая инструкция создания нового субагента

### Шаг 1. Определите Zod-схемы (`<agent>/schemas.ts`)

Переиспользуйте [`AsyncTaskStartResponseSchema`](file:///c:/development/buh70/routes/ai/ai_task/shared/types.ts) для валидации ответа от эндпоинта старта:

```typescript
import { z } from 'zod';
import { AsyncTaskStartResponseSchema } from '../shared/types';

export const TASK_FLOW_EXAMPLE = 'docs.sp_example_flow';

export const StartExampleInputSchema = z.object({
  userId: z.number().optional().default(2477).describe('ID пользователя'),
  rekvId: z.number().optional().default(63).describe('ID учреждения'),
});

export const StartExampleResponseSchema = AsyncTaskStartResponseSchema;

export const ExampleResultSchema = z.object({
  flow: z.literal(TASK_FLOW_EXAMPLE),
  logId: z.number(),
  status: z.enum(['success', 'failed', 'timeout']),
  execStart: z.string().optional(),
  execEnd: z.string().optional(),
  durationMs: z.number().optional(),
  error: z.string().optional(),
  hasErrors: z.boolean().optional(),
  errorDetails: z.string().optional(),
  resultSummary: z.string().optional(),
});

export type StartExampleInput = z.input<typeof StartExampleInputSchema>;
export type StartExampleResponse = z.infer<typeof StartExampleResponseSchema>;
export type ExampleResult = z.infer<typeof ExampleResultSchema>;
```

### Шаг 2. Реализуйте HTTP-инструмент запуска (`<agent>/tools.ts`)

Преобразуйте camelCase-параметры TypeScript в snake_case payload для бэкенда `buh70`:

```typescript
import { ApiClient, defaultApiClient } from '../shared/api_client';
import {
  StartExampleInput,
  StartExampleInputSchema,
  StartExampleResponse,
  StartExampleResponseSchema,
} from './schemas';

/**
 * Неблокирующий запуск фоновой задачи на бэкенде buh70
 */
export async function startExample(
  input: StartExampleInput = {},
  apiClient: ApiClient = defaultApiClient
): Promise<StartExampleResponse> {
  const validated = StartExampleInputSchema.parse(input);

  const payload = {
    user_id: validated.userId,
    rekv_id: validated.rekvId,
  };

  const rawResponse = await apiClient.post<unknown>('/task/exampleEndpoint/', payload);
  return StartExampleResponseSchema.parse(rawResponse);
}
```

### Шаг 3. Реализуйте субагент и экспортируйте `manifest` (`<agent>/agent.ts`)

В `agent.ts` обязательно экспортируйте объект `manifest: AgentManifest` ([`shared/agent_registry.ts`](file:///c:/development/buh70/routes/ai/ai_task/shared/agent_registry.ts#L22-L42)), который вызывается оркестратором на тиках:

- `dispatch(ctx)` — неблокирующий вызов `start<Agent>`, возвращающий `log_id` (`number | null`).
- `resolveParentParams(state)` *(опционально)* — чистая функция для **Parent Context Forwarding**, если агенту нужны выходные данные родительской задачи из `state.tasks` (как `sendFinBitReport` извлекает `logId` из `state.tasks['getEarved'].log_id`).
- `enrichReportStep(stepLog, task)` *(опционально)* — чистая функция для агент-специфичного обогащения строки в сводном отчёте `reporter` (например, извлечение массива `mailErrors` и генерация кастомного `resultSummary` в `read_mail` без хардкода в `orchestrator.agent.ts`).

```typescript
import { ApiClient, defaultApiClient } from '../shared/api_client';
import { AgentManifest } from '../shared/agent_registry';
import { watchTaskUntilDone } from '../logs_watcher/agent';
import {
  StartExampleInput,
  StartExampleInputSchema,
  ExampleResult,
  ExampleResultSchema,
  TASK_FLOW_EXAMPLE,
} from './schemas';
import { startExample } from './tools';

export interface ExampleOptions {
  apiClient?: ApiClient;
  sleepFn?: (ms: number) => Promise<void>;
  pollIntervalMs?: number;
  maxTimeoutMs?: number;
}

/**
 * Полный запуск субагента с ожиданием (для CLI / --full режима)
 */
export async function runExampleSubagent(
  input: StartExampleInput = {},
  options: ExampleOptions = {}
): Promise<ExampleResult> {
  const validated = StartExampleInputSchema.parse(input);
  const apiClient = options.apiClient || defaultApiClient;

  const startResult = await startExample(validated, apiClient);
  const logId = startResult.log_id;

  const watchResult = await watchTaskUntilDone(
    {
      userId: validated.userId,
      taskName: TASK_FLOW_EXAMPLE,
      pollIntervalMs: options.pollIntervalMs,
      maxTimeoutMs: options.maxTimeoutMs,
    },
    { apiClient, sleepFn: options.sleepFn }
  );

  return ExampleResultSchema.parse({
    flow: TASK_FLOW_EXAMPLE,
    logId,
    status: watchResult.status,
    execStart: watchResult.execStart,
    execEnd: watchResult.execEnd,
    durationMs: watchResult.durationMs,
    error: watchResult.error,
    hasErrors: watchResult.hasErrors,
    errorDetails: watchResult.errorDetails,
    resultSummary: watchResult.resultSummary,
  });
}

/**
 * Манифест для тикового оркестратора (обязательный экспорт)
 */
export const manifest: AgentManifest = {
  dispatch: async (ctx) => {
    const finalUserId = (ctx.params?.userId as number) ?? ctx.userId;
    const finalRekvId = (ctx.params?.rekvId as number) ?? ctx.rekvId;

    const res = await startExample(
      { userId: finalUserId, rekvId: finalRekvId },
      ctx.apiClient
    );
    return res.log_id;
  },
  // Опционально, если нужен контекст от родительского шага DAG:
  // resolveParentParams: (state) => {
  //   const parentLogId = state.tasks?.['parentAgent']?.log_id;
  //   return parentLogId ? { logId: parentLogId } : {};
  // },
  // Опционально, если нужно обогатить данные шага для ежедневного отчета reporter:
  // enrichReportStep: (stepLog, task) => ({}),
};
```

### Шаг 4. Создайте `<agent>/config.json` (динамическое автообнаружение)

1. Создайте `<agent>/config.json` (валидный JSON без комментариев и висячих запятых).
2. Реестр [`shared/agent_registry.ts`](file:///c:/development/buh70/routes/ai/ai_task/shared/agent_registry.ts) и менеджер состояния [`orchestrator/state.manager.ts`](file:///c:/development/buh70/routes/ai/ai_task/orchestrator/state.manager.ts) автоматически обнаружат новый каталог через `fs.readdirSync` — править `orchestrator.agent.ts`, `KNOWN_SUBAGENTS` или `KNOWN_AGENT_DIRS` **не требуется**.
3. При необходимости зарегистрируйте Genkit flow в [`index.ts`](file:///c:/development/buh70/routes/ai/ai_task/index.ts).

### Шаг 5. Требования к эндпоинту на стороне бэкенда `buh70`

Эндпоинт `POST /task/<endpoint>/` в монолите `buh70` обязан:
1. Создать запись в таблице `ou.logs` с `propertis ->> 'flow' = '<flow>'` и заполнить `exec_start`.
2. Запустить хранимую процедуру или фоновый обработчик асинхронно (не блокируя HTTP-ответ).
3. Немедленно вернуть HTTP 200 со структурой:
   ```json
   {
     "status": 200,
     "result": 1,
     "log_id": 10500,
     "data": {
       "action": "exampleEndpoint",
       "status": "STARTED",
       "log_id": 10500
     },
     "error_message": null
   }
   ```
4. По завершении фоновой работы обновить запись в `ou.logs`: выставить `exec_end`, `status` (`"success"` или `"failed"`), а также записать детали в `result` (JSONB), `response` или `error`.

---

## 7. Тестирование и верификация (Jest)

Для каждого нового субагента создайте модульный тест `<agent>/<agent>.test.ts`.

### Структура модульного теста

```typescript
import { startExample } from './tools';
import { runExampleSubagent, manifest } from './agent';
import { ApiClient } from '../shared/api_client';
import { TASK_FLOW_EXAMPLE } from './schemas';

describe('Example Subagent', () => {
  const mockPost = jest.fn();
  const mockApiClient = {
    post: mockPost,
  } as unknown as ApiClient;

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('startExample отправляет корректный POST запрос и возвращает log_id', async () => {
    mockPost.mockResolvedValueOnce({
      status: 200,
      result: 1,
      log_id: 12345,
      data: { action: 'exampleEndpoint', status: 'STARTED', log_id: 12345 },
      error_message: null,
    });

    const res = await startExample({ userId: 2477, rekvId: 63 }, mockApiClient);
    expect(mockPost).toHaveBeenCalledWith('/task/exampleEndpoint/', {
      user_id: 2477,
      rekv_id: 63,
    });
    expect(res.log_id).toBe(12345);
  });

  it('manifest.dispatch передает параметры из контекста и возвращает log_id', async () => {
    mockPost.mockResolvedValueOnce({
      status: 200,
      result: 1,
      log_id: 54321,
    });

    const logId = await manifest.dispatch({
      key: 'example',
      userId: 2477,
      rekvId: 63,
      kond: 1,
      params: { userId: 9999 },
      apiClient: mockApiClient,
    });

    expect(mockPost).toHaveBeenCalledWith('/task/exampleEndpoint/', {
      user_id: 9999,
      rekv_id: 63,
    });
    expect(logId).toBe(54321);
  });

  it('runExampleSubagent запускает задачу и дожидается завершения через logs_watcher', async () => {
    mockPost
      .mockResolvedValueOnce({ status: 200, result: 1, log_id: 12345 })
      .mockResolvedValueOnce({
        result: 1,
        data: [
          {
            flow: TASK_FLOW_EXAMPLE,
            status: 'success',
            exec_start: '2026-10-18T08:00:00.000Z',
            exec_end: '2026-10-18T08:00:05.000Z',
          },
        ],
      });

    const result = await runExampleSubagent(
      { userId: 2477, rekvId: 63 },
      { apiClient: mockApiClient, sleepFn: async () => {} }
    );

    expect(result.status).toBe('success');
    expect(result.logId).toBe(12345);
  });
});
```

### Команды проверки перед коммитом

В каталоге `routes/ai/ai_task/` выполните:

```bash
npm run typecheck
npm test
npm run build
```

---

## 8. Чек-лист готовности нового агента

- [ ] Создана папка `<agent_name>/` с файлами `config.json`, `schemas.ts`, `tools.ts`, `agent.ts`, `<agent_name>.test.ts`.
- [ ] В `<agent_name>/agent.ts` экспортирован `manifest: AgentManifest` с методом `dispatch` (и `resolveParentParams`, если нужен контекст родителя).
- [ ] В `<agent_name>/config.json` указаны валидные `name`, `flow`, `schedule`, `depends_on`, `max_attempts`, `timeout_hours` и `params`.
- [ ] Имя агента добавлено в `KNOWN_SUBAGENTS` ([`shared/agent_registry.ts`](file:///c:/development/buh70/routes/ai/ai_task/shared/agent_registry.ts)) и в `depends_on` у [`reporter/config.json`](file:///c:/development/buh70/routes/ai/ai_task/reporter/config.json).
- [ ] На бэкенде `buh70` реализован неблокирующий эндпоинт `POST /task/<endpoint>/`, создающий запись в `ou.logs` с указанным `flow`.
- [ ] Успешно проходят `npm run typecheck`, `npm test` и `npm run build`.

---

## 9. Навигация по кодовой базе и экономия токенов (Graphify)

Для оптимизации расхода токенов при исследовании архитектуры `buh70` и графа задач `ai_task` глобально установлен плагин **Graphify** (`C:\Users\Laptop\.gemini\config\skills\graphify\SKILL.md`).

### Рекомендации по использованию:
1. **Построение локального графа зависимостей:**
   ```bash
   graphify .              # Полный AST-анализ проекта (формирует каталог graphify-out/)
   graphify update .       # Инкрементальное обновление графа после изменения файлов
   ```
2. **Точечный поиск связей вместо чтения тяжелых файлов целиком:**
   - Кратчайший путь вызовов: `graphify path "<Source>" "<Target>"` (например, `graphify path "getEarved" "sendFinBitReport"`).
   - Смысловой поиск по графу: `graphify query "<вопрос по архитектуре>"`.
   - Анализ зависимостей узла: `graphify explain "<функция_или_модуль>"`.
3. **Правило расхода контекста:**
   - Если сгенерирован `graphify-out/graph.json`, для архитектурных вопросов сначала запрашивайте подграф через `graphify query`, что предотвращает засорение контекста простынями исходных текстов.
