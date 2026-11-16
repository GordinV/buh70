# Ревью проекта: соответствие реализации требованиям ТЗ (`TZ_agent_registry.md`)

**Дата проведения:** 09.10.2026  
**Объект ревью:** Модуль `routes/ai/ai_task/` и связанный бэкенд-роут `routes/raama/logAgentSchedule.js`  
**Базовый документ:** [`TZ_agent_registry.md`](./TZ_agent_registry.md)  
**Статус тестов (актуализировано 2026-11-16, `npx jest`):** 15 сьютов, 209 тестов успешно (PASS); `npx tsc --noEmit` и `npm run build` — 0 ошибок. Из 8 замечаний 7 устранены, по № 5 принято иное решение (приоритет `parentParams`, ТЗ п. 3.4 № 3 обновлён).

---

## 1. Резюме ревью (Executive Summary)

Проведена комплексная проверка кодовой базы на соответствие требованиям технического задания [`TZ_agent_registry.md`](./TZ_agent_registry.md).

### Ключевые достижения:
1. **Реестр агентов (п. 3.1–3.5):** Успешно реализован механизм `AgentManifest` (`dispatch`, `resolveParentParams`, `validatePrerequisites`, `enrichReportStep`). В `orchestrator.agent.ts` устранены жестко зашитые вызовы `startSaldoandmik`, `startCalcArvJaak` и т.д. (диспетчеризация через `registry[key].dispatch`), а также удалены неиспользуемые импорты `start*`.
2. **Dockerfile (п. 3.8):** Реализована двухстадийная сборка с автоматическим копированием всех `config.json` через стейджинг-слой `/configs`.
3. **Watchdog таймаутов (п. 3.9 № 1):** Внедрен контроль зависших задач по `timeout_hours` (по умолчанию 12 часов) с фиксацией события `TASK_TIMEOUT` и повторными попытками.
4. **Бэкенд мониторинга (п. 3.10.3):** Создан синхронный обработчик `POST /task/logAgentSchedule/` (`routes/raama/logAgentSchedule.js`), пишущий в `ou.logs` под flow `ai_task.agent_schedule`.
5. **Интеграция с Genkit:** Зарегистрированы потоки `scheduleMonitorFlow` и `agentScheduleFlow` в `index.ts`, проверены через Genkit CLI / Reflection API.

### Статус первоначальных несоответствий и рисков (устранены в рамках доработки):
- ~~**CLI-флаг `--task <key>` не реализован в `index.ts`**~~ — **устранено** (парсинг `--task` в `index.ts`, точечный сброс в `runOrchestratorTick`, событие `TASK_RESET_MANUAL`).
- ~~**Реестр агентов не сканирует диск динамически**~~ — **устранено** (`buildAgentRegistry` в `shared/agent_registry.ts`, динамическое сканирование каталогов `root` и `root/dist` через `collectAgentDirs`; ручной список `KNOWN_SUBAGENTS` удалён).
- ~~**Каскадное перевооружение зависимых задач (`sendFinBitReport`) не работает**~~ — **устранено** (блок каскадного перевооружения `depends_on` в `runOrchestratorTick`, событие `TASK_REARMED`, транзитивный Downstream Lock `findRunningDownstreamDependents`, догоняющий каскад `getLatestResetTimestampByTask`, очистка `params.logId` в `resetTaskToPending`).
- ~~**Определение `targetDateStr` выполняется по UTC**~~ — **устранено** (вычисление `targetDateStr` в `runOrchestratorTick` через `Intl.DateTimeFormat('en-CA', { timeZone: timezone })`, а также локальная `timezone` в `calculateNextScheduledRun`, `createInitialState`, `resetCycleForNewDay` и `runOrchestrator`).
- ~~**Архитектурная коллизия `schedule_monitor`**~~ — **устранено** (`schedule_monitor` исключён через `EXCLUDED_NON_DAG_DIRS` из `shared/excluded_dirs.ts`, применяемый в `orchestrator/state.manager.ts`; не попадает в `state.tasks` и не блокирует `calcTasks`).

### Решённые открытые вопросы и доработки:
- **Отчёт `reporter` по закрытому вчерашнему циклу и задачам цикла 20:00 (`task_reporter_closed_cycle_gap`, `task_report_last_run_snapshot`):** при сбросе задач (`TASK_REARMED`, `TASK_RESET_MANUAL`, `CYCLE_RESET_NEW_DAY`) функция `snapshotLastRun` сохраняет снимок последнего запуска в `task.last_run` (`LastRunSchema`); утренний `reporter` в `08:00` использует `last_run` (в окне 24 ч) для `PENDING`-задач без `log_id`, отображая как вечерние `SUCCESS` (`saldoandmik`, `lisa1_lisa5`), так и вчерашние `FAILED` (покрыто тестами в `orchestrator.test.ts`).
- **Каскадное перевооружение (`task_cascade_rearm_gaps`):** устранены все три ограничения и покрыты тестами (А), (Б), (В) в `orchestrator.test.ts`.
- **Таймзона вне тика (`task_full_mode_utc_dates`):** переведены на `timezone` `calculateNextScheduledRun`, `createInitialState`, `resetCycleForNewDay` и `runOrchestrator` (`--full`), покрыто тестами.
- **Очистка реестра (`task_registry_cleanup_leftovers`, `task_registry_known_subagents`, `task_finbit_service_user_id`):** удалены неиспользуемые импорты `start*`, хардкод `if (key === 'sendFinBitReport')` перенесён в `manifest.validatePrerequisites`, удалены `KNOWN_SUBAGENTS` и `KNOWN_AGENT_DIRS`, добавлен `manifest` в `reporter/agent.ts`, заведена константа `FINBIT_SERVICE_USER_ID = 11770` (`shared/constants.ts`).

---

## 2. Детальный построчный анализ требований ТЗ

| Раздел ТЗ | Требование | Факт реализации | Статус |
|---|---|---|---|
| **3.1** | Интерфейсы `AgentManifest`, `AgentDispatchContext` | Реализованы в `shared/agent_registry.ts`. | **Соответствует** |
| **3.2** | Экспорт `manifest` во всех агентах | Экспортирован в 11 агентах: `saldoandmik`, `calc_arv_jaak`, `getEarved`, `check_asutus`, `inforegister`, `import_earved`, `sendFinBitReport`, `lisa1_lisa5`, `read_mail`, `schedule_monitor`, `reporter` (`logs_watcher` — служебный модуль без манифеста). | **Соответствует** |
| **3.3** | Динамическое построение реестра без ручной правки | `buildAgentRegistry` (`shared/agent_registry.ts`) динамически сканирует каталоги `root` и `root/dist` через `collectAgentDirs`; ручные списки `KNOWN_SUBAGENTS` и `KNOWN_AGENT_DIRS` удалены. | **Соответствует** |
| **3.4** | Рефакторинг `orchestrator.agent.ts`, уход от `if (key === '...')` | Статические вызовы и неиспользуемые импорты `start*` удалены, диспетчеризация через `registry[key].dispatch`, предусловие `sendFinBitReport` перенесено в `manifest.validatePrerequisites`. | **Соответствует** |
| **3.4 (п. 3)** | Приоритет параметров при слиянии `task.params` и `parentParams` | В коде `task.params = { ...(task.params \|\| {}), ...parentParams }` — приоритет у `parentParams` (коммит `ea5a7ff8`); ТЗ п. 3.4 № 3 и раздел 5 № 2 обновлены под это поведение. | **Соответствует** |
| **3.8** | Сборка Dockerfile через `/configs` | Реализовано в `Dockerfile` (find + cp в builder, единый COPY в runner). | **Соответствует** |
| **3.9 № 1** | Watchdog `RUNNING` (`TASK_TIMEOUT`, дефолт 12 ч) | Реализован в блоке 3 `orchestrator.agent.ts`, порог `timeout_hours ?? 12`. | **Соответствует** |
| **3.9 № 2** | Посуточное перевооружение задач с `schedule` + каскад зависимостей | Реализовано перевооружение задач со `schedule` и каскадное перевооружение `depends_on` (`TASK_REARMED`), транзитивный Downstream Lock (`findRunningDownstreamDependents`), догоняющий каскад после `RUNNING` (`getLatestResetTimestampByTask`) и очистка `params.logId` (`resetTaskToPending`). Покрыто тестами (А), (Б), (В) в `orchestrator.test.ts`. | **Соответствует** |
| **3.9 № 3** | Применение `allow_parallel` | Проверка `task.allow_parallel === false && hasRunningTasks` внедрена в блоке 4. | **Соответствует** |
| **3.9 № 4** | Закрытие старого цикла при смене суток (`targetDateStr > state.cycle_date`) | Реализовано закрытие зависшего цикла в `runOrchestratorTick` (`CYCLE_CLOSED_DAY_CHANGE`). При любом сбросе (`TASK_REARMED`, `TASK_RESET_MANUAL`, `CYCLE_RESET_NEW_DAY`) `snapshotLastRun` сохраняет снимок в `task.last_run`, и утренний `reporter` в `08:00` выводит статус из `last_run` (в окне 24 ч) вместо `PENDING`. Покрыто тестами в `orchestrator.test.ts`. | **Соответствует** |
| **3.9 № 5** | Единая таймзона (`Europe/Tallinn`) для времени и дат | `isTaskScheduleReady`, `targetDateStr` в `runOrchestratorTick`, `calculateNextScheduledRun`, `createInitialState`, `resetCycleForNewDay` и `runOrchestrator` (`--full`) используют `timezone` (`Europe/Tallinn`). Покрыто тестами. | **Соответствует** |
| **3.9 № 7** | CLI-флаг `--task <key>` для точечного сброса и запуска | Реализован парсинг `--task` в `index.ts` (`parseTaskFlag`), добавлено поле `taskKey` в `OrchestratorTickInputSchema` и точечный сброс в `runOrchestratorTick` (`TASK_RESET_MANUAL`). | **Соответствует** |
| **3.9 № 8** | Согласование `userId: 11770` в FinBit-агентах | Выделена константа `FINBIT_SERVICE_USER_ID = 11770` (`shared/constants.ts`) с JSDoc для 5 FinBit-агентов (`getEarved`, `check_asutus`, `inforegister`, `import_earved`, `sendFinBitReport`), убрано из `description` в `getEarved/config.json`, задокументировано в `AGENT.md`, покрыто тестом в `shared/agent_registry.test.ts`. | **Соответствует** |
| **3.10.1** | `schedule_monitor` — служебный агент вне DAG | `schedule_monitor` исключён из DAG через `EXCLUDED_NON_DAG_DIRS` (`shared/excluded_dirs.ts`, применяется в `orchestrator/state.manager.ts`), из `pendingKeys` и `calcTasks` в `runOrchestratorTick`. Коллизия снята. | **Соответствует** |
| **3.10.2** | Срез `buildScheduleSnapshot` | Реализована чистая функция, покрыта тестами. | **Соответствует** |
| **3.10.3** | Запись среза в `ou.logs` через `POST /task/logAgentSchedule/` | Реализован роут в `routes/raama/logAgentSchedule.js` и вызов в `schedule_monitor/tools.ts`. | **Соответствует** |
| **3.10.4** | Genkit Flow и автономный вызов | Зарегистрированы `scheduleMonitorFlow` и `agentScheduleFlow` в `index.ts`. Проверено через `run_flow`. | **Соответствует** |

---

## 3. Выявленные замечания и дефекты (история и текущий статус)

### Замечание 1: Отсутствие CLI-флага `--task <key>` (п. 3.9 № 7) — **Устранено**
* **Что было:** В ТЗ и чек-листе DoD заявлен флаг `--task <key>`, но в `index.ts` он не парсился.
* **Исправление:** Добавлен парсинг `--task` (`index.ts`), поле `taskKey` в `OrchestratorTickInputSchema` и точечный сброс в `runOrchestratorTick` (`TASK_RESET_MANUAL`).

### Замечание 2: Статический список в `buildAgentRegistry` (п. 3.3) — **Устранено**
* **Что было:** В `shared/agent_registry.ts` реестр строился только по `KNOWN_SUBAGENTS`, параметр `rootDir` игнорировался.
* **Исправление:** В `buildAgentRegistry` (`shared/agent_registry.ts`) реализовано динамическое сканирование каталогов первого уровня `root` и `root/dist` через `collectAgentDirs`; ручные списки `KNOWN_SUBAGENTS` и `KNOWN_AGENT_DIRS` удалены.

### Замечание 3: Отсутствие каскадного перевооружения зависимых задач без `schedule` (п. 3.9 № 2) — **Устранено**
* **Что было:** Перевооружались только задачи со `schedule`, из-за чего `sendFinBitReport` оставалась со вчерашним статусом.
* **Исправление:** В `runOrchestratorTick` реализованы каскадное перевооружение (`TASK_REARMED`), транзитивный Downstream Lock (`findRunningDownstreamDependents`), догоняющее перевооружение для задач, бывших `RUNNING` в момент сброса родителя (`getLatestResetTimestampByTask`), и очистка `params.logId` (`resetTaskToPending`). Покрыто тестами (А), (Б), (В) в `orchestrator.test.ts`.

### Замечание 4: Вычисление даты тика `targetDateStr` по UTC (п. 3.9 № 5) — **Устранено**
* **Что было:** `currentDate.toISOString().slice(0, 10)` сдвигало дату между 00:00 и 02:00/03:00 по Эстонии.
* **Исправление:** Вычисление `targetDateStr` в `runOrchestratorTick`, `calculateNextScheduledRun`, `createInitialState`, `resetCycleForNewDay` и `runOrchestrator` (`--full`) переведено на `timezone` (`Europe/Tallinn`). Покрыто тестами.

### Замечание 5: Приоритет параметров `task.params.logId` (п. 3.4 № 3) — **Уточнено / принято**
* **Что было:** В ТЗ был описан Вариант А (приоритет `task.params.logId`), тогда как код делал `{ ...(task.params || {}), ...parentParams }`.
* **Текущее состояние:** Во всех местах слияния параметров перед запуском/повтором в `runOrchestratorTick` (`{ ...task.params, ...parentParams }`, при LLM-решении — `{ ...task.params, ...dynamic_params, ...parentParams }`) приоритет закреплён за `parentParams`, чтобы `resolveParentParams` всегда обновлял `logId` от родителя в новом цикле (коммит `ea5a7ff8`). Принято иное решение, чем рекомендовало ревью; формулировки ТЗ п. 3.4 № 3 и раздела 5 № 2 обновлены.

### Замечание 6: Архитектурная двойственность субагента `schedule_monitor` (п. 3.10.1) — **Устранено**
* **Что было:** `schedule_monitor` мог попадать в `state.tasks` и блокировать `calcTasks` / `reporter`.
* **Исправление:** `schedule_monitor` исключён из DAG через `EXCLUDED_NON_DAG_DIRS` (`shared/excluded_dirs.ts`, применяется в `orchestrator/state.manager.ts`) и фильтруется в `pendingKeys` и `calcTasks` (`runOrchestratorTick`).

### Замечание 7: Несогласованный `userId: 11770` в `getEarved/config.json` (п. 3.9 № 8) — **Устранено**
* **Что было:** Не было пояснения, почему у `getEarved` указан `userId: 11770` вместо `2477`.
* **Исправление:** Выделена константа `AI_TASK_SERVICE_USER_ID = 11770` с JSDoc (`shared/constants.ts`; алиас `FINBIT_SERVICE_USER_ID` сохранён для совместимости), и все агенты `ai_task`, `orchestrator/config.json`, `shared/api_client.ts`, `.env.example`, дефолты схем и `state.manager.ts` переведены с `2477` на единый сервисный `userId = 11770`. Пояснение задокументировано в `AGENT.md`, защищено тестом в `shared/agent_registry.test.ts` (из `description` в `getEarved/config.json` упоминание убрано).

### Замечание 8: Таймаут HTTP-клиента при вызове `logAgentSchedule` — **Устранено**
* **Что было:** Вызов `apiClient.post` выполнялся с дефолтным таймаутом 30 секунд.
* **Исправление:** Для вызова `logAgentSchedule` задан короткий таймаут `{ timeoutMs: 5000 }`.

---

## 4. Рекомендации и предложения (Предложения)

> **Исторический раздел.** Рекомендации ниже — исходные предложения ревью от 09.10.2026. Пп. 1–3, 5, 7, 8 выполнены (см. раздел 5). П. 4 устарел: на момент ревью `schedule_monitor` действительно был в `KNOWN_AGENT_DIRS` и `KNOWN_SUBAGENTS` и имел `config.json` (добавлены в коммите `103cabf9`); сейчас не входит — убран из списков вместе с `config.json` в коммите `06965452`, исключение сделано через `EXCLUDED_NON_DAG_DIRS`. П. 6 (Вариант А) **отклонён** — принят приоритет `parentParams` (коммит `ea5a7ff8`). Не использовать как план работ.

### Приоритет 1 (Критические исправления логики)

1. **Реализовать каскадный сброс зависимых задач без расписания:**
   В блоке 1.1.1 `orchestrator.agent.ts` при перевооружении родительской задачи (например, `getEarved`) находить все дочерние задачи (`t.depends_on.includes(parentKey)`) и также сбрасывать их в `PENDING` (`attempts = 0`, `log_id = null`, `error = null`).
2. **Исправить вычисление `targetDateStr` с учетом таймзоны:**
   Заменить `currentDate.toISOString().slice(0, 10)` на форматирование в часовом поясе оркестратора:
   ```typescript
   const targetDateStr = options.targetDateStr ||
     new Intl.DateTimeFormat('en-CA', { timeZone: timezone }).format(currentDate);
   ```
3. **Реализовать поддержку CLI-флага `--task <key>`:**
   В `index.ts`:
   - Считывать аргумент `--task <key>`.
   - В `OrchestratorTickInputSchema` добавить поле `taskKey: z.string().optional()`.
   - В начале `runOrchestratorTick`: если передан `taskKey`, точечно переводить указанную задачу в `PENDING` (`attempts = 0`, `log_id = null`, `error = null`) и устанавливать `forceRun = true` для немедленного запуска.
4. **Разрешить коллизию `schedule_monitor` в графе DAG:**
   В `orchestrator.agent.ts` исключить `schedule_monitor` из расчетного графа задач:
   ```typescript
   const calcTasks = Object.keys(state.tasks).filter((k) => k !== 'reporter' && k !== 'schedule_monitor');
   ```
   Либо убрать `schedule_monitor` из `KNOWN_AGENT_DIRS`, сохранив его регистрацию только в Genkit Flows и реестре манифестов.

### Приоритет 2 (Соответствие архитектурным стандартам)

5. **Динамическое сканирование директорий в `buildAgentRegistry`:**
   Переписать `buildAgentRegistry`, чтобы функция сканировала `rootDir` на наличие папок с `agent.ts`/`agent.js` (переиспользуя `loadAllAgentConfigs` или `fs.readdirSync`), как описано в п. 3.3 ТЗ.
6. **Восстановить приоритет параметров (Вариант А):**
   При слиянии параметров задач сохранять приоритет явно заданного `logId`:
   ```typescript
   task.params = {
     ...(task.params || {}),
     ...parentParams,
     ...(task.params?.logId ? { logId: task.params.logId } : {}),
   };
   ```
7. **Унифицировать или задокументировать `userId` для `getEarved`:**
   В `getEarved/config.json` либо изменить `userId` на `2477`, либо добавить явный комментарий в `AGENT.md`, объясняющий необходимость отдельного пользователя `11770` для FinBit.
8. **Задать короткий таймаут для вызова `logAgentSchedule`:**
   В `schedule_monitor/tools.ts` передавать таймаут 5000 мс (`{ timeoutMs: 5000 }`), чтобы сбой логирования не затягивал тик оркестратора.

---

## 5. Итог устранения замечаний

Из 8 выявленных замечаний 7 устранены, по № 5 принято иное решение, чем рекомендовало ревью (приоритет `parentParams` вместо Варианта А, ТЗ обновлено):

| № | Замечание | Что сделано | Статус |
|---|---|---|---|
| 1 | CLI-флаг `--task <key>` | Добавлен парсинг `--task` в `index.ts`, поле `taskKey` в `OrchestratorTickInputSchema`/`OrchestratorTickOptions`. В `orchestrator.agent.ts` реализован точечный сброс задачи в `PENDING` (`attempts = 0`, `log_id = null`, событие `TASK_RESET_MANUAL`) и запуск. Покрыто тестом. | **Устранено** |
| 2 | Статический список в `buildAgentRegistry` | В `shared/agent_registry.ts` реализовано динамическое сканирование `root` и `root/dist` через `collectAgentDirs`; ручные списки `KNOWN_SUBAGENTS` и `KNOWN_AGENT_DIRS` удалены. Покрыто тестом фиктивного агента во временном каталоге. | **Устранено** |
| 3 | Каскадное перевооружение зависимых задач | В `runOrchestratorTick` реализованы каскадное перевооружение (`TASK_REARMED`), транзитивный Downstream Lock (`findRunningDownstreamDependents`), догоняющее перевооружение после `RUNNING` (`getLatestResetTimestampByTask`) и очистка `params.logId` (`resetTaskToPending`). Покрыто тестами (А), (Б), (В) в `orchestrator.test.ts`. | **Устранено** |
| 4 | Дата тика `targetDateStr` по UTC | Вычисление `targetDateStr` переведено на часовой пояс оркестратора: `new Intl.DateTimeFormat('en-CA', { timeZone: timezone }).format(currentDate)`. Устранено смещение даты в Эстонии с 00:00 до 03:00. | **Устранено** |
| 5 | Приоритет параметров `task.params.logId` | В `orchestrator.agent.ts` закреплён приоритет `parentParams` (`{ ...(task.params \|\| {}), ...parentParams }`, коммит `ea5a7ff8`), чтобы `logId` предшественника не залипал между циклами. Формулировки ТЗ п. 3.4 № 3 и раздела 5 № 2 обновлены. | **Принято иное решение** |
| 6 | Архитектурная коллизия `schedule_monitor` | `schedule_monitor` исключен из `pendingKeys` (не запускается как расчетная задача DAG) и из `calcTasks` (не блокирует отправку отчета `reporter`). Запуск производится штатно на каждом выходе из тика через `invokeScheduleMonitorSafe`. | **Устранено** |
| 7 | Несогласованный `userId: 11770` в `getEarved` | Выделена константа `AI_TASK_SERVICE_USER_ID = 11770` (`shared/constants.ts`, алиас `FINBIT_SERVICE_USER_ID`) с JSDoc; все агенты `ai_task`, оркестратор, `api_client`, `.env.example` и дефолты схем переведены с `2477` на единый `11770`. Задокументировано в `AGENT.md` и покрыто тестом в `shared/agent_registry.test.ts`. | **Устранено** |
| 8 | Таймаут вызова `logAgentSchedule` | В `schedule_monitor/tools.ts` вызов `apiClient.post` снабжен таймаутом `{ timeoutMs: 5000 }`, исключая задержки тика при сетевых сбоях. | **Устранено** |

**Результаты проверок:**
- Jest (`npx jest`, 2026-11-16): **15 test suites, 209 tests passed (100% PASS)**
- TypeScript build (`npx tsc --noEmit`, `npm run build`, 2026-11-16): **0 ошибок (PASS)**
