# ТЗ: Реестр агентов (Agent Registry) для оркестратора `ai_task`

Статус: **Реализовано (этапы 1 и 2)** — 86 тестов пройдены (10 сьютов), код собран, документация обновлена.

## 1. Цель

Убрать необходимость править `orchestrator/orchestrator.agent.ts` при добавлении нового субагента.
Сейчас добавление агента требует правки 4 разных мест (см. `AGENT.md`, раздел «Как добавить нового агента»).
После внедрения — правки орекстратора не требуются: новый агент подключается новой папкой + `config.json` + небольшим манифестом внутри своего `agent.ts`.

Тип запуска задачи (HTTP-вызов, валидация, особые случаи типа «в FinBit нет счетов» у `getEarved`) остаётся в коде агента — реестр не заменяет `tools.ts`/`schemas.ts`, только убирает жёсткую диспетчеризацию по имени.

## 2. Текущее состояние (для справки, что уже работает и трогать не нужно)

Ничего менять не требуется в:
- `orchestrator/state.manager.ts` — `loadAllAgentConfigs` уже динамически сканирует каталоги и подхватывает `config.json` новых агентов (`state.manager.ts:89-128`).
- Логике зависимостей, расписания, повторов, LLM-решений (`evaluateTaskLaunchDecision`, `evaluateTaskResultDecision`, `isTaskScheduleReady`) — работает generic по `key`.
- Условии готовности `reporter` (`allCalcFinished`, `orchestrator.agent.ts:1126`) — уже считает все задачи кроме `reporter`, не завязано на конкретные имена.

Требует изменения (жёстко зашито по имени агента):
- `dispatchTaskByKey` (`orchestrator.agent.ts:80-133`) — цепочка `if (key === '...')` со статическими импортами `start<Agent>()`.
- 3 дублирующихся блока проброса `logId` от `getEarved` к `sendFinBitReport`: `orchestrator.agent.ts:438-445`, `:855-856`, `:940-941`.

## 3. Новая архитектура

### 3.1. Интерфейс `AgentManifest`

Новый файл: `shared/agent_registry.ts` (общие типы и функция построения реестра).

```typescript
import { ApiClient } from './api_client';
import { OrchestratorState } from '../orchestrator/orchestrator.schemas';

/** Контекст, передаваемый в dispatch() при запуске/повторе задачи */
export interface AgentDispatchContext {
  key: string;
  userId: number;
  rekvId: number;
  kond: number;
  params: Record<string, unknown>;
  apiClient: ApiClient;
}

/** Манифест субагента — контракт между агентом и оркестратором */
export interface AgentManifest {
  /**
   * Неблокирующий запуск задачи (POST на бэкенд). Должен вернуть log_id
   * либо выбросить исключение (оркестратор сам обработает retry/FAILED).
   */
  dispatch: (ctx: AgentDispatchContext) => Promise<number | null>;

  /**
   * Опционально: вычисление дополнительных параметров запуска на основе
   * состояния других задач графа (Parent Context Forwarding).
   * Вызывается оркестратором перед stage запуска для ЛЮБОЙ задачи,
   * у которой есть соответствующий манифест.
   * Должна быть чистой (без побочных эффектов) и не бросать исключений
   * при отсутствии родителя — в этом случае возвращать {}.
   */
  resolveParentParams?: (state: OrchestratorState) => Record<string, unknown>;
}
```

### 3.2. Способ регистрации манифеста агентом

Каждый `<agent>/agent.ts` дополнительно экспортирует константу `manifest: AgentManifest`.
Пример для `saldoandmik/agent.ts` (без родительских параметров):

```typescript
export const manifest: AgentManifest = {
  dispatch: async (ctx) => {
    const res = await startSaldoandmik(
      { userId: ctx.params.userId as number ?? ctx.userId,
        rekvId: ctx.params.rekvId as number ?? ctx.rekvId,
        kond: ctx.params.kond as number ?? ctx.kond },
      ctx.apiClient
    );
    return res.log_id;
  },
};
```

Пример для `sendFinBitReport/agent.ts` (с проброшенным `logId`, сохраняет текущую валидацию «logId обязателен»):

```typescript
export const manifest: AgentManifest = {
  dispatch: async (ctx) => {
    const logId = ctx.params.logId as number | undefined;
    if (!logId) {
      throw new Error('sendFinBitReport viga: logId puudub (parent context getEarved log_id ei ole edastatud)');
    }
    const res = await startSendFinBitReport(
      { userId: ctx.params.userId as number ?? ctx.userId, rekvId: ctx.params.rekvId as number ?? ctx.rekvId, logId },
      ctx.apiClient
    );
    return res.log_id;
  },
  resolveParentParams: (state) => {
    const parentLogId = state.tasks['getEarved']?.log_id;
    return parentLogId ? { logId: parentLogId } : {};
  },
};
```

`getEarved/agent.ts` сохраняет существующую особую логику (синтетический успех при «Arveid ei leitud») внутри `dispatch` без изменений — просто оборачивает уже существующий `runGetEarvedSubagent`/`startGetEarved`.

Пример для `getEarved/agent.ts` (с расчетом даты выборки: текущая дата минус 2 дня):

```typescript
export const manifest: AgentManifest = {
  dispatch: async (ctx) => {
    // Дата выборки: если не передана явно в params.dateQueryFrom, вычисляем текущая дата минус 2 дня
    let dateQueryFrom = ctx.params.dateQueryFrom as string | undefined;
    if (!dateQueryFrom) {
      const d = new Date();
      d.setDate(d.getDate() - 2);
      const year = d.getFullYear();
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      dateQueryFrom = `${year}-${month}-${day}`;
    }

    const res = await startGetEarved(
      {
        userId: ctx.params.userId as number ?? ctx.userId,
        rekvId: ctx.params.rekvId as number ?? ctx.rekvId,
        dateQueryFrom,
      },
      ctx.apiClient
    );
    return res.log_id;
  },
};
```

### 3.2.1. Изменение параметров выборки `getEarved` (текущая дата минус 2 дня)

Поток `getEarved` запрашивает счета из FinBit за определенную дату.
- **Текущее поведение:** по умолчанию использовалось `getDefaultDateQueryFrom()` = текущая дата минус 1 день (`d.setDate(d.getDate() - 1)`).
- **Новое требование:** изменить расчет даты по умолчанию на **текущая дата минус 2 дня** (`d.setDate(d.getDate() - 2)`).
- **Изменения:**
  1. Обновить функцию `getDefaultDateQueryFrom` в `getEarved/schemas.ts`: вычитать 2 дня вместо 1 (`d.setDate(d.getDate() - 2)`).
  2. Обновить описание в схеме `StartGetEarvedInputSchema` (`dateQueryFrom`: по умолчанию текущая дата минус 2 дня).
  3. В манифесте `getEarved/agent.ts` передавать вычисленный `dateQueryFrom` (или полагаться на обновленный `getDefaultDateQueryFrom()`).
  4. Обновить соответствующие unit-тесты (`getEarved.test.ts`, `orchestrator.test.ts`).

### 3.3. Построение реестра

Функция `buildAgentRegistry(rootDir?: string): Record<string, AgentManifest>` в `shared/agent_registry.ts`:

1. Использует тот же список каталогов, что и `loadAllAgentConfigs` (переиспользовать `resolveAiTaskRootDir` + перечень подкаталогов из `state.manager.ts`, либо явно передавать список ключей из уже загруженных `AgentConfig`, чтобы не дублировать логику сканирования директорий).
2. Для каждого ключа агента пытается импортировать `<root>/<agentDir>/agent` (при работе из `dist/` — `<root>/dist/<agentDir>/agent.js`; при разработке через `tsx` — `.ts` напрямую).
3. Если модуль экспортирует `manifest`, кладёт в реестр под именем `cfg.name` (совпадает с ключом в `state.tasks`).
4. Если у агента нет экспорта `manifest` — не ошибка, просто агент не будет доступен для диспетчеризации (логируется предупреждение). Это осознанный fallback: конфиг может существовать раньше кода агента (например, при подготовке к раскатке).
5. Реестр строится один раз за тик (в начале `runOrchestratorTick`), не на каждый вызов `dispatchTaskByKey`.

**Решено:** динамический импорт по имени папки (вариант 1).

```typescript
const modulePath = path.join(distDir, agentDir, 'agent.js'); // при разработке через tsx — agentDir/agent.ts
if (fs.existsSync(modulePath)) {
  const mod = require(modulePath);
  if (mod.manifest) registry[cfg.name] = mod.manifest;
}
```

Следствия этого решения (учесть при реализации):
- Ошибка в отсутствующем/битом `manifest` у одного агента не должна ронять сборку `tsc` целиком — она обнаружится только в рантайме (лог предупреждения при построении реестра, п. 3.3.4). Компенсируется т��стом `shared/agent_registry.test.ts`, который явно проверяет, что у каждого продового агента из `KNOWN_AGENT_DIRS`/каталога `manifest` присутствует и имеет ожидаемую форму (`typeof manifest.dispatch === 'function'`) — это единственная защита от «забыли добавить manifest» до деплоя.
- Путь `dist/<agentDir>/agent.js` должен физически существовать после `npm run build` — обычный `tsc` это обеспечивает автоматически, отдельного шага генерации не требуется.
- При запуске тестов через `ts-jest`/`tsx` (без `dist/`) `buildAgentRegistry` должна уметь резолвить `.ts` напрямую — предусмотреть отдельную ветку (`require.extensions` уже настроены `ts-node`/`tsx`, но нужно явно проверить в тесте на CI).

### 3.4. Изменения в `orchestrator.agent.ts`

1. Убрать статические импорты `startSaldoandmik`, `startCalcArvJaak`, `startGetEarved`, `startSendFinBitReport`, `startLisa1Lisa5` (если они не используются больше нигде в файле).
2. Заменить `dispatchTaskByKey` на:
   ```typescript
   async function dispatchTaskByKey(
     key: string,
     userId: number,
     rekvId: number,
     kond: number,
     apiClient: ApiClient,
     customParams: Record<string, unknown> = {},
     registry: Record<string, AgentManifest>
   ): Promise<number | null> {
     const manifest = registry[key];
     if (!manifest) return null;
     return manifest.dispatch({ key, userId, rekvId, kond, params: customParams, apiClient });
   }
   ```
   (Сигнатура получает `registry` явным параметром — без глобального состояния, проще тестировать.)
3. Убрать все 3 блока `if (key === 'sendFinBitReport') { const parentLogId = state.tasks['getEarved']?.log_id; ... }` и заменить единым вызовом перед каждым местом старта/повтора:
   ```typescript
   let parentParams: Record<string, unknown> = {};
   try {
     parentParams = registry[key]?.resolveParentParams?.(state) ?? {};
   } catch (err) {
     logger.warn(`resolveParentParams failed for ${key}, falling back to {}`, err);
     parentParams = {};
   }
   task.params = { ...(task.params || {}), ...parentParams, ...(task.params?.logId ? { logId: task.params.logId } : {}) };
   ```
   Точное место вставки — все 3 точки, где сейчас находится хардкод (перед retry по ошибке результата, перед retry по отсутствию `exec_start`, перед первым запуском из `PENDING`). Приоритет параметров (Вопрос 2, решено — Вариант А): если `params.logId` уже явно задан конфигом агента, он не перезаписывается родительским значением (сейчас проверка `!task.params?.logId` — сохранить эквивалентную семантику). Обработка ошибок (Вопрос 3, решено — Вариант Б): исключение в `resolveParentParams` не должно прерывать тик — перехватывается, логируется как warning, значение деградирует к `{}`.
4. `runOrchestratorTick` в начале строит `const registry = buildAgentRegistry(rootDir)` один раз и передаёт его во все места, где сейчас вызывается `dispatchTaskByKey`.
5. Блок вызова `reporter` (`generateAndSendReportSubagent`) **не трогать** — он не идёт через `dispatchTaskByKey`, это отдельный специальный шаг цикла (см. п.6 «Вне рамок»).

### 3.5. Изменения в существующих агентах

Для каждого из: `saldoandmik`, `calc_arv_jaak`, `getEarved`, `sendFinBitReport`, `lisa1_lisa5` — добавить экспорт `manifest` в `<agent>/agent.ts` по образцу из п. 3.2. Логика внутри `dispatch` должна быть эквивалентна текущей ветке в `dispatchTaskByKey` (тот же payload, те же значения по умолчанию `userId/rekvId/kond`).

`logs_watcher` и `reporter` — **манифест не нужен**, они не запускаются через `dispatchTaskByKey`.

### 3.6. Тесты

- `orchestrator/orchestrator.test.ts`: обновить тесты, которые сейчас мокают `startSaldoandmik`/`startCalcArvJaak`/и т.д. напрямую как импортированные функции — переключить на мок `AgentManifest.dispatch` через тестовый реестр, передаваемый в `runOrchestratorTick`/`dispatchTaskByKey`.
- Добавить новый тест-файл `shared/agent_registry.test.ts`:
  - агент с валидным `manifest` попадает в реестр;
  - агент без `manifest` не попадает, но не ломает построение реестра остальных;
  - `resolveParentParams` не вызывается для агентов без зависимостей (или вызывается и возвращает `{}` — зафиксировать выбранное поведение);
  - реестр строится из тестового временного каталога с фиктивными агентами (для проверки «добавление нового агента = только новая папка», без прямой зависимости от продовых каталогов).
- Существующие `*.test.ts` в каждом `<agent>/` (`calc_arv_jaak.test.ts` и т.д.) не меняются — они тестируют `run<Agent>Subagent`/`tools.ts`, которые не затрагиваются.

### 3.8. Изменения в `Dockerfile` (Вопрос 4, решено — Вариант 2)

Убрать 6 ручных строк `COPY --from=builder /app/<agent>/config.json ./<agent>/` и заменить генерацией стейджинг-каталога в builder-стадии + одной строкой копирования в runner-стадии.

Builder-стадия (после `RUN npm run build`):
```dockerfile
RUN mkdir -p /configs && \
    find . -mindepth 2 -maxdepth 2 -name config.json \
      -exec sh -c 'mkdir -p /configs/$(dirname "$1") && cp "$1" /configs/$(dirname "$1")/' _ {} \;
```

Runner-стадия (заменяет текущие 6 строк `COPY .../config.json`):
```dockerfile
COPY --from=builder /configs ./
```

Новый агент с собственным `config.json` попадает в образ автоматически, без правки `Dockerfile`. Поведение соответствует уже динамическому сканированию каталогов в `state.manager.ts → loadAllAgentConfigs`.

### 3.7. Пример «добавление нового агента» после внедрения (для итоговой проверки/демо)

1. Создать `new_agent/{schemas.ts,tools.ts,agent.ts,config.json,new_agent.test.ts}` по существующему шаблону.
2. В `agent.ts` экспортировать `manifest` (5-15 строк).
3. `Dockerfile` — **не редактировать** (см. 3.8, генерация `/configs` подхватывает новый каталог автоматически).
4. Пересобрать (`npm run build`) — `dist/new_agent/agent.js` появится автоматически, регистр находит манифест динамическим `require()` (вариант 1, см. 3.3).
5. `orchestrator/orchestrator.agent.ts` — **не редактировать**.
6. (Опционально, техдолг, см. 5.5) — при желании видеть агента в Genkit Dev UI, вручную добавить `ai.defineFlow` в `index.ts`. Не требуется для работы тика.

### 3.9. Исправление: задачи с `schedule` не стартуют в назначенное время (`getEarved` 07:00, `calc_arv_jaak` 07:30)

**Симптом (лог тиков 2026-10-08/09):** `getEarved` (07:00) и `calc_arv_jaak` (07:30) стартовали в 07:44 (цикл `INITIALIZED` в 04:40Z), а 2026-10-09 не стартовали вовсе — тик показывал `cycleDate: 2026-10-08`, `activeTasks: [lisa1_lisa5]`.

**Корневые причины (по коду `orchestrator.agent.ts` / `state.manager.ts`):**

1. **Сброс на новые сутки возможен только после завершения прошлого цикла.** `resetCycleForNewDay` вызывается лишь когда `state.status` равен `COMPLETED`/`FAILED` и нет `RUNNING` задач (блок 1.4, стр. ~654–774). Пока вчерашний цикл `IN_PROGRESS`, задачи сегодняшнего дня остаются в `SUCCESS` со вчерашней даты и не получают статус `PENDING`, поэтому проверка `schedule.time` для них даже не выполняется.
2. **У `RUNNING` задачи нет таймаута.** Блок 3 (стр. ~999–1002) только пишет в лог «on teostamisel». `maxTimeoutMs` вычисляется (стр. 590), но не используется. `lisa1_lisa5` висела в `RUNNING` >8 ч (запись в `ou.logs` без `exec_end`/`status`) → `reporter` не стартует → цикл не завершается → п.1 блокирует следующий день. Единый «зависший» шаг блокирует все остальные расписания.
3. **Расписание привязано к циклу, а не к задаче.** Флаг `allow_parallel` читается из `config.json`, но нигде в оркестраторе не применяется (параллельность обеспечивается только `Promise.all` в блоке 5). Независимые корневые задачи (`depends_on: []`) тем не менее ждут сброса общего цикла.
4. **Задержка старта до периода тика.** Запуск происходит только на тике (в логе 15-минутная сетка: :00, :15, :30), `schedule.time` проверяется как «≥ времени» — старт возможен с опозданием до интервала cron.
5. **Несогласованность таймзон.** `isTaskScheduleReady` использует `currentDate.getHours()` (TZ процесса), тогда как `evaluateTaskLaunchDecision`/`isDailyExecutionWindowOpen` используют `timezone` из конфига (`Europe/Tallinn`). Работает только потому, что `run_tick.sh` задаёт `-e TZ=Europe/Tallinn`.
6. **Ручной обход не помогает (`--force`).** `forceRun` не обходит `schedule.time`, а при ручном сбросе цикла статус `FAILED` у `getEarved` блокирует повторный запуск (повтор только в рамках `max_attempts`).

**Требуемые изменения:**

| № | Изменение | Файл |
|---|---|---|
| 1 | **Watchdog `RUNNING` (`TASK_TIMEOUT`):** если `now - started_at` > таймаута задачи и в `ou.logs` нет `exec_end` → считать попытку неуспешной (`TASK_TIMEOUT` в `history`), выполнить retry по `max_attempts`, иначе `FAILED`. Порог берётся из параметра `timeout_hours` в `<agent>/config.json`; **если параметр не задан — по умолчанию 12 часов** (константа `DEFAULT_TASK_TIMEOUT_HOURS = 12`). Подробности — п. 3.9.1. | `orchestrator.agent.ts` (блок 3), `orchestrator.schemas.ts`, `state.manager.ts` |
| 2 | **Посуточное «перевооружение» задач с `schedule`:** в начале тика для каждой задачи с `schedule`, не `RUNNING`, у которой дата `finished_at`/`started_at` (в TZ оркестратора) < сегодняшней — перевести в `PENDING` (`attempts=0`, `error=null`, `log_id=null`, `TASK_REARMED` в `history`), **независимо от статуса общего цикла**. Задачи с `depends_on` перевооружаются каскадно вместе с родителями. | `orchestrator.agent.ts` |
| 3 | **Применить `allow_parallel`:** задачи с `allow_parallel: true` не блокируются состоянием других задач/цикла; `allow_parallel: false` (`reporter`) стартует строго после остальных. Покрыть тестом. | `orchestrator.agent.ts` |
| 4 | **Закрытие цикла по сменившимся суткам:** если `targetDateStr > state.cycle_date` и все задачи, кроме `RUNNING`, завершены — сначала принудительно завершить старый цикл (`reporter` со статусом по факту, зависшая → `FAILED` по п.1), затем `resetCycleForNewDay`. Цикл не должен переживать полночь бесконечно. | `orchestrator.agent.ts` |
| 5 | **Единая таймзона:** `isTaskScheduleReady(schedule, currentDate, timezone)` считает часы/минуты/день/месяц через `Intl.DateTimeFormat({ timeZone })`, а не `getHours()`. Тот же `timezone` использовать в сравнении «дата < сегодня». | `orchestrator.agent.ts` |
| 6 | **Частота тика:** cron `*/5 * * * *` (как в `ai_task.md`), допустимая задержка старта ≤ 5 мин; зафиксировать в документации. Проверить фактическую настройку cron на сервере (в логах интервал 15 мин). | `ai_task.md`, crontab |
| 7 | **`forceRun` для расписаний:** `--force` игнорирует `schedule.time` (но не `day`/`month`) и позволяет перезапуск `FAILED` задачи (`attempts=0`). Добавить явный CLI-флаг `--task <key>` для точечного сброса и запуска (например, `buh70-tick --task getEarved`) вместо ручной правки `orchestrator_state.json`. | `orchestrator.agent.ts`, `index.ts` |
| 8 | **Конфиг:** `getEarved/config.json` содержит `userId: 11770`, остальные агенты — `2477`; привести к единому значению или явно задокументировать причину (иначе `reconcileTasksWithConfigs` перепишет `params` в боевом `orchestrator_state.json`). | `getEarved/config.json` |

**Критерий приёмки:** при зависшей `lisa1_lisa5` (без `exec_end`) на следующих сутках `getEarved` и `calc_arv_jaak` стартуют на первом тике после 07:00 / 07:30 (по TZ `Europe/Tallinn`); зависшая задача автоматически помечается `TASK_TIMEOUT` через `maxTimeoutMs`, цикл закрывается, `reporter` отправляет отчёт со статусом FAILED по `lisa1_lisa5`.

**Тесты (Jest, `orchestrator.test.ts`):**
- `RUNNING` дольше `maxTimeoutMs` → `TASK_TIMEOUT` → retry/`FAILED`;
- вчерашний цикл `IN_PROGRESS` + новая дата + `getEarved` со вчерашним `SUCCESS` → `PENDING` и запуск после 07:00;
- до 07:00 задача остаётся `PENDING` (`WAIT`), после 07:00 — `RUNNING`;
- `isTaskScheduleReady` при `TZ=UTC` и `timezone=Europe/Tallinn` даёт тот же результат;
- `allow_parallel: false` (`reporter`) не стартует при наличии `RUNNING` задач.

#### 3.9.1. Параметр таймаута задачи `timeout_hours`

- **Конфиг:** необязательное поле в `<agent>/config.json`, число часов (допускается дробное, например `0.5`):
  ```json
  {
    "name": "lisa1_lisa5",
    "flow": "eelarve.salvesta_lisa_1_5_kontrol",
    "timeout_hours": 6
  }
  ```
- **Значение по умолчанию:** если `timeout_hours` не задан (или не число > 0) — **12 часов**.
- **Схемы:** добавить `timeout_hours: z.number().positive().optional()` в `AgentConfig` и `TaskState` (`orchestrator.schemas.ts`); `buildTaskGraphFromConfigs` и `reconcileTasksWithConfigs` (`state.manager.ts`) переносят значение из конфига в состояние задачи (как `max_attempts`), не затирая рантайм-поля.
- **Вычисление:** `timeoutMs = (task.timeout_hours ?? DEFAULT_TASK_TIMEOUT_HOURS) * 3600 * 1000`. Отсчёт от `task.started_at` (или `execStart` из `ou.logs`, если он есть). Это отдельный порог оркестратора: он не заменяет `TASK_TIMEOUT_MS` (по умолчанию 4 ч) в `logs_watcher`/`api_client` и не должен от него зависеть.
- **Поведение при превышении:** запись `TASK_TIMEOUT` в `history` (`details: task, timeout_hours, started_at`); `task.error = 'TASK_TIMEOUT: превышено N ч'`; далее retry при `attempts < max_attempts`, иначе `FAILED`. Если за это время в `ou.logs` появился `exec_end`/`status`, приоритет у фактического результата, а не у таймаута.
- **Невалидное значение** (`0`, отрицательное, не число): предупреждение в лог и использование значения по умолчанию (12 ч), тик не прерывается.
- **Тесты:** (1) без параметра задача `RUNNING` 11 ч — не таймаутится, 12+ ч — `TASK_TIMEOUT`; (2) `timeout_hours: 1` — таймаут через 1 ч; (3) невалидное значение → 12 ч; (4) `exec_end` появился раньше — таймаут не срабатывает.

### 3.10. Новый агент `schedule_monitor` — журнал расписания и статусов агентов (этап 2, **на согласование**)

**Цель.** На каждом тике фиксировать в `ou.logs` (через API, как все остальные агенты) срез: какой агент когда будет запущен и в каком статусе находится сейчас. Это даёт наблюдаемость без чтения `state/orchestrator_state.json` на сервере (причина инцидента 2026-10-08/09 была обнаружена только по ручному разбору state-файла).

#### 3.10.1. Роль в архитектуре

- Это **служебный агент**, не расчётная задача DAG. Он **не** входит в `state.tasks`, не имеет статусов `PENDING/RUNNING`, не участвует в `depends_on`, `allCalcFinished` и не блокирует `reporter` (аналогично `logs_watcher`/`reporter`).
- Вызывается **на каждом тике** отдельным блоком `runOrchestratorTick` после всех решений тика (после инспекции, перевооружения, запуска готовых задач и до атомарной записи state), чтобы в срез попали актуальные статусы.
- Вызывается и при раннем выходе тика (суточный барьер `COMPLETED`, окно ещё не открыто) — срез нужен именно тогда, чтобы видеть «живость» оркестратора.
- Сбой агента **не прерывает тик**: `try/catch`, предупреждение в лог (`[schedule-monitor] ...`), состояние оркестратора не меняется (по принципу Вопроса 3, Вариант Б).
- **Каталог без `config.json`** (`schedule_monitor/{schemas.ts,tools.ts,agent.ts,schedule_monitor.test.ts}`): `loadAllAgentConfigs` сканирует именно `config.json`, поэтому каталог не превратится в задачу DAG. Настройки — в `orchestrator/config.json` (п. 3.10.4). `manifest` не нужен (не диспетчеризуется через реестр).

#### 3.10.2. Формирование среза (чистая функция, без обращения к API)

`buildScheduleSnapshot(state, now, timezone)` в `schedule_monitor/agent.ts` возвращает:

```typescript
interface AgentScheduleEntry {
  agent: string;                 // ключ задачи (state.tasks key)
  flow: string;                  // имя flow в ou.logs
  status: 'PENDING' | 'RUNNING' | 'SUCCESS' | 'FAILED' | 'SKIPPED';
  schedule: { time?: string; day?: number; month?: number } | null;
  depends_on: string[];
  next_planned_run: string | null; // ISO в TZ оркестратора; null — запуск по зависимостям
  next_run_reason: 'SCHEDULE_TODAY' | 'SCHEDULE_TOMORROW' | 'AFTER_DEPENDENCIES' | 'RETRY' | 'RUNNING_NOW' | 'NONE';
  last_started_at: string | null;
  last_finished_at: string | null;
  timeout_deadline: string | null; // started_at + timeout_hours (только для RUNNING)
  attempts: number;
  max_attempts: number;
  log_id: number | null;         // log_id задачи в ou.logs
  error: string | null;
}
interface ScheduleSnapshot {
  tick_at: string;               // ISO
  timezone: string;
  cycle_date: string;
  cycle_status: string;
  next_scheduled_run: string | null;
  summary: { pending: number; running: number; success: number; failed: number; skipped: number };
  agents: AgentScheduleEntry[];
}
```

Правила `next_planned_run` (все даты/время считаются через `Intl.DateTimeFormat` в `timezone` из конфига, как в `isTaskScheduleReady`, п. 3.9 № 5):
- `PENDING` + `schedule.time`: сегодня в `schedule.time`, если оно ещё не наступило, иначе — завтра (`SCHEDULE_TODAY` / `SCHEDULE_TOMORROW`); для `schedule.day/month` — ближайшая подходящая дата, **строго не раньше** текущего момента.
- `PENDING` без `schedule` с `depends_on`: `null`, причина `AFTER_DEPENDENCIES`.
- `PENDING` с `attempts > 0` (ожидает повтор): ближайший тик, причина `RETRY`.
- `RUNNING`: `RUNNING_NOW`, заполняется `timeout_deadline`.
- `SUCCESS/FAILED/SKIPPED` с `schedule`: следующие сутки в `schedule.time` (согласуется с перевооружением п. 3.9 № 2). Без `schedule`: `NONE`.
- Строка длиной > лимита (`error`) усекается до 500 символов, чтобы не раздувать `ou.logs`.

#### 3.10.3. Вызов API и запись в лог

- `schedule_monitor/tools.ts → logAgentSchedule(snapshot, apiClient)` → `POST /task/logAgentSchedule/` (по образцу `calc_arv_jaak/tools.ts`: Zod-валидация входа и ответа `{ status, log_id }`).
- Payload: `{ user_id, rekv_id, snapshot }`.
- Эндпоинт бэкенда `buh70` **синхронный** (запись одной строки, без фоновой процедуры): пишет в `ou.logs` под `flow = 'ai_task.agent_schedule'` с `exec_start = exec_end = now()`, `status = 'success'`, срез — в jsonb-поле `result` (читать с `COALESCE`, `properties::jsonb`-правила проекта). Возвращает `{ status: 'success', log_id }`.
- Чтение: существующий `POST /task/read_log/:user_id/:task_name` с `task_name = 'ai_task.agent_schedule'` — новых эндпоинтов чтения не требуется.
- `log_id` записи пишется в консоль тика (`[schedule-monitor] срез записан, log_id: N`); в `state` **не** сохраняется и событие в `history` **не** добавляется (иначе ~288 записей/сутки при cron `*/5` раздуют state-файл).

#### 3.10.4. Конфиг и интеграция

`orchestrator/config.json`:
```json
{
  "schedule_monitor": { "enabled": true }
}
```
- Если блок отсутствует — агент **включён** с параметрами по умолчанию. `enabled: false` полностью отключает вызов.
- Схема `OrchestratorConfigSchema` (`orchestrator.schemas.ts`/`loadOrchestratorConfig`) расширяется необязательным объектом `schedule_monitor` (Zod, `.optional()`).
- `index.ts` (CLI) и `buh70-tick`: вывод в консоль одной строки `[schedule-monitor] ...` — отдельного флага не требуется.
- `Dockerfile`: правок не нужно (нет `config.json`; `dist/schedule_monitor/*.js` собирается `tsc`).

#### 3.10.5. Тесты (Jest)

`schedule_monitor/schedule_monitor.test.ts`:
- `buildScheduleSnapshot`: `PENDING` до/после `schedule.time` → `SCHEDULE_TODAY` / `SCHEDULE_TOMORROW`; одинаковый результат при `TZ=UTC` и `timezone=Europe/Tallinn`;
- `PENDING` с `depends_on` и без `schedule` → `AFTER_DEPENDENCIES`, `next_planned_run = null`;
- `RUNNING` с `timeout_hours` → корректный `timeout_deadline`; без параметра — 12 ч;
- завершённая задача со `schedule` → следующие сутки; переход через полночь и конец месяца;
- `summary` совпадает с числом задач по статусам;
- `logAgentSchedule`: вызывает `/task/logAgentSchedule/` с `user_id`, `rekv_id`, `snapshot`, парсит `log_id`; невалидный ответ → ошибка Zod.

`orchestrator/orchestrator.test.ts`:
- тик вызывает `logAgentSchedule` ровно один раз, **в том числе** при раннем выходе (`COMPLETED` до `next_scheduled_run`);
- исключение в `logAgentSchedule` не прерывает тик и не меняет `state.tasks`;
- `enabled: false` → вызова нет.

#### 3.10.6. Критерий приёмки

После очередного тика `POST /task/read_log/:user_id/ai_task.agent_schedule` возвращает свежую запись, в которой для каждого агента (`getEarved` 07:00, `calc_arv_jaak` 07:30, `saldoandmik` 20:00, …) видны текущий статус, ближайший плановый запуск и его причина; при зависшей задаче видны `RUNNING_NOW` и `timeout_deadline`.

**Принятые решения (согласовано):**
1. Срез пишется **на каждом тике**, без фильтров и троттлинга. Формат state не меняется.
2. Имя flow в `ou.logs` — `ai_task.agent_schedule`, эндпоинт — `/task/logAgentSchedule/`.
3. Чистка старых записей не требуется.

#### 3.10.7. План работ (код пока не менялся)

| Шаг | Работа | Файлы | Проверка |
|---|---|---|---|
| 0 | Перед стартом: прогнать `npm run typecheck`, `npm run build`, `npm test` — зафиксировать базу (72 теста). | — | зелёный базовый прогон |
| 1 | **Схемы.** Zod: `AgentScheduleEntrySchema`, `ScheduleSnapshotSchema`, вход `LogAgentScheduleInputSchema` (`userId`, `rekvId`, `snapshot`), ответ `{ status, log_id }`; константа `TASK_FLOW_AGENT_SCHEDULE = 'ai_task.agent_schedule'`. | `schedule_monitor/schemas.ts` | typecheck |
| 2 | **Расчёт среза.** `buildScheduleSnapshot(state, now, timezone)` — чистая функция; `computeNextPlannedRun` (TZ-aware, `schedule.time/day/month`, переход через полночь/конец месяца/год), усечение `error` до 500 символов, `summary` по статусам. | `schedule_monitor/agent.ts` | юнит-тесты п. 3.10.5 |
| 3 | **API-вызов.** `logAgentSchedule(input, apiClient)` → `POST /task/logAgentSchedule/` с `user_id`, `rekv_id`, `snapshot`; Zod-парсинг ответа (по образцу `calc_arv_jaak/tools.ts`). | `schedule_monitor/tools.ts` | юнит-тест с моком `ApiClient` |
| 4 | **Обёртка агента.** `runScheduleMonitor(state, params, apiClient, now)`: строит срез, вызывает API, возвращает `log_id` либо `null`; `try/catch` — ошибка только в warning `[schedule-monitor]`, наружу не бросает. | `schedule_monitor/agent.ts` | тест «ошибка API не бросает» |
| 5 | **Конфиг.** В `orchestrator.schemas.ts` добавить необязательный `schedule_monitor: { enabled (default true) }`; в `orchestrator/config.json` добавить явный блок; обновить `loadOrchestratorConfig`. | `orchestrator/orchestrator.schemas.ts`, `orchestrator/config.json` | тест загрузки конфига с блоком и без него |
| 6 | **Интеграция в тик.** В `runOrchestratorTick` вызвать `runScheduleMonitor` на **каждом** выходе из тика: нормальное завершение **и** ранние выходы (суточный барьер `COMPLETED`, окно не открыто); вызов — после всех изменений статусов, но до возврата результата. Реестр, `reporter` и `allCalcFinished` не трогать; `ai_task.agent_schedule` не попадает в `state.tasks`. | `orchestrator/orchestrator.agent.ts` | тесты п. 3.10.5 (оркестратор) |
| 7 | **Тесты оркестратора.** Вызов ровно 1 раз за тик, в т.ч. при раннем выходе; сбой не меняет `state.tasks`; `enabled: false` → вызова нет; существующие тесты не сломаны (моки `ApiClient` дополнить обработкой `/task/logAgentSchedule/`). | `orchestrator/orchestrator.test.ts` | `npm test` |
| 8 | **Бэкенд `buh70`** (реализовано): эндпоинт `POST /task/logAgentSchedule/` (`routes/raama/logAgentSchedule.js`) — синхронная вставка 1 строки в `ou.logs` (`flow = 'ai_task.agent_schedule'`, `status = 'success'`, `exec_start = exec_end = clock_timestamp()`, срез в `result`), ответ `{ status: 200, result: 1, log_id, data: { action: 'logAgentSchedule', status: 'COMPLETED', log_id } }`. | `routes/raama/logAgentSchedule.js`, `routes/index.js` | проверено (синтаксис, контракт API) |
| 9 | **Сборка и регрессия.** `npm run typecheck`, `npm run build`, `npm test` — все зелёные, число тестов не меньше базы + новые; проверить, что `dist/schedule_monitor/*.js` создан. | — | DoD этапа 2 |
| 10 | **Документация.** `AGENT.md` (раздел «Роли» — служебный агент `schedule_monitor`, чем отличается от расчётных, что не имеет `config.json`), `walkthrough.md` (раздел 4.6), отметить DoD этапа 2 в этом ТЗ. | `AGENT.md`, `walkthrough.md`, `TZ_agent_registry.md` | ревью |
| 11 | **Выкладка и приёмка.** Сначала задеплоить эндпоинт бэкенда (шаг 8), затем образ `ai_task`. Проверка: после очередного тика `read_log/ai_task.agent_schedule` возвращает свежую запись со всеми агентами (критерий п. 3.10.6). Откат: `schedule_monitor.enabled = false` в `orchestrator/config.json` без пересборки. | сервер | критерий приёмки 3.10.6 |

**Порядок и зависимости:** шаги 1→2→3→4 последовательны; 5 можно параллельно с 2–4; 6 после 4 и 5; 7 после 6; 8 независим и идёт параллельно с 1–7 (блокирует только 11); 9–10 после 7; 11 после 8 и 9.

**Риски плана:**
- Ранние выходы тика разбросаны по `runOrchestratorTick` — риск пропустить один из выходов. Митигация: единая точка вызова (обёртка/`finally`) и тест на каждый тип раннего выхода.
- Тик запускается под `flock` каждые 5 минут — вызов API добавляет задержку; задать короткий таймаут `ApiClient` для этого вызова, чтобы он не растягивал тик.
- Эндпоинт ещё не существует — до шага 8 в консоли тика будет warning; это ожидаемо и не является сбоем.

## 4. Критерии готовности (Definition of Done)

- [x] `shared/agent_registry.ts` создан, содержит `AgentManifest`, `AgentDispatchContext`, `buildAgentRegistry`.
- [x] Все 5 расчётных агентов (`saldoandmik`, `calc_arv_jaak`, `getEarved`, `sendFinBitReport`, `lisa1_lisa5`) экспортируют `manifest` с эквивалентным текущему поведением.
- [x] Параметры выборки счетов `getEarved` обновлены: дата по умолчанию вычисляется как **текущая дата минус 2 дня** (`getDefaultDateQueryFrom`).
- [x] Реализованы изменения п. 3.9: watchdog `RUNNING` (`TASK_TIMEOUT` с дефолтом 12 ч), посуточное перевооружение задач с `schedule`, применение `allow_parallel`, единая таймзона, флаг `--task <key>`; `getEarved` (07:00) и `calc_arv_jaak` (07:30) стартуют вовремя даже при зависшей задаче предыдущего цикла.
- [x] `dispatchTaskByKey` не содержит `if (key === '...')` по конкретным именам агентов.
- [x] Логика проброса `logId` от `getEarved` к `sendFinBitReport` вынесена в `resolveParentParams` и вызывается generic-кодом (0 упоминаний строки `'sendFinBitReport'` в основном цикле `runOrchestratorTick`, кроме самого `resolveParentParams` внутри `sendFinBitReport/agent.ts`).
- [x] `npm run typecheck`, `npm run build`, `npm test` проходят без ошибок и без уменьшения числа тестов (все 9 сьютов, 72 теста).
- [x] Демо-агент (см. п. 3.7) добавляется без единой правки `orchestrator.agent.ts` и `Dockerfile` — покрыто тестом `agent_registry.test.ts`.
- [x] Обновлённый `Dockerfile` (п. 3.8) собирает конфиги автоматически через слой `/configs`.
- [x] `AGENT.md` (раздел «Как добавить нового агента») обновлён под новую процедуру.
- [x] `walkthrough.md` дополнен описанием реестра (по текущей практике проекта — фиксировать реализованную архитектуру).

**Этап 2 — `schedule_monitor` (п. 3.10) — реализовано:**
- [x] Создан каталог `schedule_monitor/` (`config.json`, `schemas.ts`, `tools.ts`, `agent.ts`, тест, экспорт `manifest`); агент зарегистрирован в `KNOWN_AGENT_DIRS`, `KNOWN_SUBAGENTS` и как Genkit Flow (`scheduleMonitorFlow` / `agentScheduleFlow`).
- [x] `buildScheduleSnapshot` — чистая функция, TZ-aware, покрыта тестами (п. 3.10.5).
- [x] Оркестратор вызывает `logAgentSchedule` на каждом тике (включая ранний выход); сбой не прерывает тик и не меняет state.
- [x] Контракт вызова `POST /task/logAgentSchedule/` и обработка ответа реализованы (`flow = 'ai_task.agent_schedule'`); срез читается через `/task/read_log/`.
- [x] Блок `schedule_monitor` в `orchestrator/config.json` (`enabled`) валидируется Zod; по умолчанию включён.
- [x] `AGENT.md` и `walkthrough.md` описывают субагент мониторинга; `typecheck`, `build`, `test` зелёные (90 тестов, 10 сьютов).

## 5. Риски и открытые вопросы (на обсуждение до реализации)

1. ~~Способ импорта манифеста в `dist/`~~ — **решено**: динамический `require()` по имени папки (вариант 1). См. 3.3.
2. ~~Порядок слияния `parentParams` и явно заданных `task.params`~~ — **решено**: Вариант А. Явно заданное в `task.params` всегда имеет приоритет над значением из `resolveParentParams` (сохраняется текущее правило, эквивалент проверки `!task.params?.logId`). См. код в 3.4.
3. ~~Ошибка в `resolveParentParams`~~ — **решено**: Вариант Б (defensive). Вызов оборачивается в `try/catch` на уровне оркестратора; при исключении — предупреждение в лог и деградация к `{}`, тик не прерывается. См. обновлённый код в 3.4.
4. ~~Docker/деплой~~ — **решено**: Вариант 2 (generic COPY). `Dockerfile` меняется в рамках этого ТЗ: builder-стадия собирает все `config.json` в стейджинг-каталог `/configs` с сохранением структуры подкаталогов, runner-стадия копирует его одной строкой вместо шести ручных `COPY .../<agent>/config.json`. Новый агент подхватывается автоматически. См. 3.8.
5. ~~Genkit `defineFlow` в `index.ts`~~ — **решено**: Вариант A (принятый техдолг). Регистрация flow остаётся ручной и опциональной — используется только Dev UI/трассировкой, не влияет на работу тика, поэтому не блокирует добавление агента через реестр. Явно зафиксировано в чек-листе «как добавить агента» (3.7) и в DoD.

## 6. Вне рамок этого ТЗ (явно не делается)

- Замена `<agent>/tools.ts`/`schemas.ts` на декларативный конфиг (вариант C из предыдущего обсуждения) — не рассматривается.
- Реструктуризация расположения `config.json` в единый каталог `configs/` (вариант 3 из п.5.4) — не делается, текущий Dockerfile-фикс (вариант 2) достаточен и не требует переноса файлов.
- Автогенерация Genkit flows в `index.ts` из реестра (вариант B из п.5.5) — принят вариант A (ручная регистрация остаётся, это техдолг, не блокирующий задачу).
- Изменение формата `state/orchestrator_state.json` — не требуется, реестр не сериализуется в состояние.
- Изменение поведения `reporter` (специальный шаг цикла, не участвует в реестре).

## 7. Затрагиваемые файлы (сводка)

| Файл | Действие |
|---|---|
| `shared/agent_registry.ts` | Новый файл |
| `shared/agent_registry.test.ts` | Новый файл |
| `saldoandmik/agent.ts` | Добавить `export const manifest` |
| `calc_arv_jaak/agent.ts` | Добавить `export const manifest` |
| `getEarved/agent.ts` | Добавить `export const manifest` (передача вычисленного `dateQueryFrom`) |
| `getEarved/schemas.ts` | Обновить `getDefaultDateQueryFrom` (вычитать 2 дня вместо 1) и схему `StartGetEarvedInputSchema` |
| `getEarved/getEarved.test.ts` | Обновить проверки даты `dateQueryFrom` под расчет (-2 дня) |
| `sendFinBitReport/agent.ts` | Добавить `export const manifest` (+ `resolveParentParams`) |
| `lisa1_lisa5/agent.ts` | Добавить `export const manifest` |
| `orchestrator/orchestrator.agent.ts` | Убрать хардкод в `dispatchTaskByKey` и 3 блоках проброса `logId`; построение и передача `registry`; **п. 3.9:** watchdog таймаута `RUNNING`, посуточное перевооружение задач с `schedule`, `allow_parallel`, TZ-aware `isTaskScheduleReady`, закрытие цикла при смене суток, флаг `--task` |
| `orchestrator/orchestrator.test.ts` | Обновить моки под новую точку внедрения (`registry` вместо прямых импортов); тесты п. 3.9 |
| `getEarved/config.json` | Согласовать `userId` (11770 vs 2477) |
| `ai_task.md` | Cron `*/5`, описание `--task`, таймаута и перевооружения |
| `AGENT.md` | Обновить раздел «Как добавить нового агента» |
| `walkthrough.md` | Дополнить описанием реестра |
| `Dockerfile` | Заменить 6 ручных `COPY .../config.json` на генерацию `/configs` в builder-стадии + одну `COPY` в runner-стадии (см. 3.8) |
| `index.ts` | Не меняется в рамках этого ТЗ (см. п.5.5, вариант A — принятый техдолг) |
| `schedule_monitor/{schemas,tools,agent}.ts`, `schedule_monitor.test.ts` | **Этап 2:** новые файлы (п. 3.10) |
| `orchestrator/orchestrator.agent.ts` | **Этап 2:** блок вызова `logAgentSchedule` на каждом тике (в т.ч. при раннем выходе) |
| `orchestrator/orchestrator.schemas.ts`, `orchestrator/config.json` | **Этап 2:** необязательный блок `schedule_monitor` |
| backend `buh70`: `/task/logAgentSchedule/` | **Этап 2:** синхронная запись среза в `ou.logs` |
