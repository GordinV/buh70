# Ревью проекта: соответствие реализации требованиям ТЗ (`TZ_agent_registry.md`)

**Дата проведения:** 09.10.2026  
**Объект ревью:** Модуль `routes/ai/ai_task/` и связанный бэкенд-роут `routes/raama/logAgentSchedule.js`  
**Базовый документ:** [`TZ_agent_registry.md`](./TZ_agent_registry.md)  
**Статус тестов на момент ревью:** 10 сьютов, 93 теста успешно (PASS), сборка `tsc` успешна (0 ошибок). Все 8 замечаний устранены.

---

## 1. Резюме ревью (Executive Summary)

Проведена комплексная проверка кодовой базы на соответствие требованиям технического задания [`TZ_agent_registry.md`](./TZ_agent_registry.md).

### Ключевые достижения:
1. **Реестр агентов (п. 3.1–3.5):** Успешно реализован механизм `AgentManifest` (`dispatch`, `resolveParentParams`). В `orchestrator.agent.ts` устранены статические импорты и жестко зашитые вызовы `startSaldoandmik`, `startCalcArvJaak` и т.д.
2. **Dockerfile (п. 3.8):** Реализована двухстадийная сборка с автоматическим копированием всех `config.json` через стейджинг-слой `/configs`.
3. **Watchdog таймаутов (п. 3.9 № 1):** Внедрен контроль зависших задач по `timeout_hours` (по умолчанию 12 часов) с фиксацией события `TASK_TIMEOUT` и повторными попытками.
4. **Бэкенд мониторинга (п. 3.10.3):** Создан синхронный обработчик `POST /task/logAgentSchedule/` (`routes/raama/logAgentSchedule.js`), пишущий в `ou.logs` под flow `ai_task.agent_schedule`.
5. **Интеграция с Genkit:** Зарегистрированы потоки `scheduleMonitorFlow` и `agentScheduleFlow` в `index.ts`, проверены через Genkit CLI / Reflection API.

### Главные несоответствия и риски, требующие устранения:
- **CLI-флаг `--task <key>` не реализован в `index.ts`** (хотя в чек-листе DoD отмечен как выполненный).
- **Реестр агентов не сканирует диск динамически**, а опирается на жестко заданный массив `KNOWN_SUBAGENTS`, что нарушает пункт 3.3 ТЗ («добавление агента = только новая папка»).
- **Каскадное перевооружение зависимых задач (`sendFinBitReport`) не работает**, так как фильтр проверяет только задачи со `schedule`, оставляя дочерние задачи во вчерашнем статусе.
- **Определение `targetDateStr` выполняется по UTC**, а не по таймзоне оркестратора (`Europe/Tallinn`), что сдвигает дату между 00:00 и 03:00 ночи.
- **Архитектурная коллизия `schedule_monitor`:** субагент одновременно зарегистрирован как расчетная задача DAG в `state.tasks` и как служебный вызов на каждом тике.

---

## 2. Детальный построчный анализ требований ТЗ

| Раздел ТЗ | Требование | Факт реализации | Статус |
|---|---|---|---|
| **3.1** | Интерфейсы `AgentManifest`, `AgentDispatchContext` | Реализованы в `shared/agent_registry.ts`. | **Соответствует** |
| **3.2** | Экспорт `manifest` во всех агентах | Экспортирован в `saldoandmik`, `calc_arv_jaak`, `getEarved`, `sendFinBitReport`, `lisa1_lisa5`, `schedule_monitor`. | **Соответствует** |
| **3.3** | Динамическое построение реестра без ручной правки | Функция `buildAgentRegistry` использует статический список `KNOWN_SUBAGENTS`, параметр `rootDir` игнорируется. | **Не соответствует** |
| **3.4** | Рефакторинг `orchestrator.agent.ts`, уход от `if (key === '...')` | Статические вызовы убраны, используется `registry[key].dispatch`. | **Соответствует** |
| **3.4 (п. 3)** | Приоритет параметров: `params.logId` из конфига не должен перезаписываться родителем (Вариант А) | В коде `task.params = { ...(task.params \|\| {}), ...parentParams }` — `parentParams` перезаписывает явно заданный `params.logId`. | **Не соответствует** |
| **3.8** | Сборка Dockerfile через `/configs` | Реализовано в `Dockerfile` (find + cp в builder, единый COPY в runner). | **Соответствует** |
| **3.9 № 1** | Watchdog `RUNNING` (`TASK_TIMEOUT`, дефолт 12 ч) | Реализован в блоке 3 `orchestrator.agent.ts`, порог `timeout_hours ?? 12`. | **Соответствует** |
| **3.9 № 2** | Посуточное перевооружение задач с `schedule` + каскад зависимостей | Перевооружение задач со `schedule` есть (`TASK_REARMED`). Зависимые задачи (`depends_on`) без расписания каскадно НЕ перевооружаются. | **Частично** |
| **3.9 № 3** | Применение `allow_parallel` | Проверка `task.allow_parallel === false && hasRunningTasks` внедрена в блоке 4. | **Соответствует** |
| **3.9 № 4** | Закрытие старого цикла при смене суток (`targetDateStr > state.cycle_date`) | Если цикл завис в `IN_PROGRESS`, принудительное закрытие старого цикла через `reporter` не вызывается. | **Частично** |
| **3.9 № 5** | Единая таймзона (`Europe/Tallinn`) для времени и дат | `isTaskScheduleReady` использует `Intl.DateTimeFormat`. Однако `targetDateStr` в начале тика вычисляется через UTC: `currentDate.toISOString().slice(0, 10)`. | **Частично** |
| **3.9 № 7** | CLI-флаг `--task <key>` для точечного сброса и запуска | В `index.ts` парсинг флага `--task` отсутствует. В схеме `OrchestratorTickInputSchema` поля нет. | **Не реализовано** |
| **3.9 № 8** | Согласование `userId: 11770` в `getEarved/config.json` | В файле по-прежнему `userId: 11770`. Причина не задокументирована. | **Не реализовано** |
| **3.10.1** | `schedule_monitor` — служебный агент вне DAG | Создан `schedule_monitor/config.json`, агент добавлен в `KNOWN_AGENT_DIRS` и попадает в `state.tasks` (конфликт со статусом чисто служебного агента). | **Коллизия** |
| **3.10.2** | Срез `buildScheduleSnapshot` | Реализована чистая функция, покрыта тестами. | **Соответствует** |
| **3.10.3** | Запись среза в `ou.logs` через `POST /task/logAgentSchedule/` | Реализован роут в `routes/raama/logAgentSchedule.js` и вызов в `schedule_monitor/tools.ts`. | **Соответствует** |
| **3.10.4** | Genkit Flow и автономный вызов | Зарегистрированы `scheduleMonitorFlow` и `agentScheduleFlow` в `index.ts`. Проверено через `run_flow`. | **Соответствует** |

---

## 3. Выявленные замечания и дефекты (Замечания)

### Замечание 1: Отсутствие CLI-флага `--task <key>` (п. 3.9 № 7)
* **Проблема:** В ТЗ и чек-листе DoD заявлен флаг `--task <key>` для точечного перезапуска задачи (например, `buh70-tick --task getEarved`). В `index.ts` парсятся только `--force`, `--full`, `--user`, `--rekv`, `--date`, `--state`. Флаг `--task` игнорируется.
* **Последствия:** Администратор не может точечно перезапустить упавшую задачу через CLI без ручного редактирования `orchestrator_state.json`.

### Замечание 2: Статический список в `buildAgentRegistry` (п. 3.3)
* **Проблема:** В `shared/agent_registry.ts` реестр строится циклом по константе `KNOWN_SUBAGENTS`:
  ```typescript
  export const KNOWN_SUBAGENTS = ['saldoandmik', 'calc_arv_jaak', 'getEarved', 'sendFinBitReport', 'lisa1_lisa5', 'schedule_monitor'];
  ```
  Параметр `rootDir` не используется, относительный `require('../${agentName}/agent')` зашит жестко.
* **Последствия:** Добавление нового агента требует обязательной правки кода `shared/agent_registry.ts`, что прямо противоречит критерию ТЗ «новый агент добавляется созданием одной папки без правки общего кода».

### Замечание 3: Отсутствие каскадного перевооружения зависимых задач без `schedule` (п. 3.9 № 2)
* **Проблема:** В `orchestrator.agent.ts` (строки 629–637) проверка перевооружения выполняется по условию:
  ```typescript
  if (sTask.schedule && sTask.status !== 'RUNNING') { ... }
  ```
  Зависимая задача `sendFinBitReport` имеет `schedule: null` и `depends_on: ['getEarved']`.
* **Последствия:** При наступлении нового дня `getEarved` сбрасывается в `PENDING` и стартует в 07:00. Но `sendFinBitReport` остается со вчерашним статусом `SUCCESS` (или `FAILED`), так как не имеет своего `schedule`. Когда `getEarved` завершается, `sendFinBitReport` не запускается, потому что запускаются только задачи со статусом `PENDING`.

### Замечание 4: Вычисление даты тика `targetDateStr` по UTC (п. 3.9 № 5)
* **Проблема:** В `orchestrator.agent.ts` (строка 610):
  ```typescript
  const targetDateStr = options.targetDateStr || currentDate.toISOString().slice(0, 10);
  ```
* **Последствия:** `currentDate.toISOString()` возвращает дату в UTC. Для часового пояса Таллинна (`Europe/Tallinn`, UTC+2 зимой / UTC+3 летом) в период с 00:00 до 02:00/03:00 ночи `targetDateStr` будет вчерашней датой. Сброс суточного цикла и перевооружение расписаний будут запаздывать до 02:00/03:00 ночи.

### Замечание 5: Нарушение приоритета параметров `task.params.logId` (п. 3.4 № 3)
* **Проблема:** В ТЗ согласован Вариант А: если `params.logId` уже явно задан в конфиге агента, он не должен перезаписываться родителем:
  ```typescript
  // ТЗ:
  task.params = { ...(task.params || {}), ...parentParams, ...(task.params?.logId ? { logId: task.params.logId } : {}) };
  // Фактический код:
  task.params = { ...(task.params || {}), ...parentParams };
  ```
* **Последствия:** Если в конфиге для отладки задан фиксированный `logId`, вызов `resolveParentParams` безусловно перетирает его значением из состояния родителя.

### Замечание 6: Архитектурная двойственность субагента `schedule_monitor` (п. 3.10.1)
* **Проблема:** Согласно ТЗ п. 3.10.1, `schedule_monitor` — служебный агент, который **не должен** входить в `state.tasks`, не должен иметь статусов `PENDING/RUNNING` и не должен влиять на `allCalcFinished` и `reporter`.
  Однако после создания `schedule_monitor/config.json` и добавления в `KNOWN_AGENT_DIRS` агент попадает в `state.tasks`.
* **Последствия:**
  1. `schedule_monitor` вызывается дважды: штатно на каждом выходе из тика через `invokeScheduleMonitorSafe`, и дополнительно пытается стартовать как фоновая задача графа в 20:00.
  2. В `allCalcFinished` задача `schedule_monitor` учитывается как расчетная (так как фильтр исключает только `k !== 'reporter'`). Если она зависнет в `PENDING`, отправка отчета `reporter` будет заблокирована.

### Замечание 7: Несогласованный `userId: 11770` в `getEarved/config.json` (п. 3.9 № 8)
* **Проблема:** В `getEarved/config.json` поле `userId` равно `11770`, тогда как у всех остальных агентов `2477`. Причина этого отличия не отражена ни в комментариях, ни в `AGENT.md`.
* **Последствия:** При автоматическом слиянии состояний (`reconcileTasksWithConfigs`) в рабочий `orchestrator_state.json` подставляется `11770`, что может вызывать расхождение прав в `buh70` при смене пользователя запуска.

### Замечание 8: Таймаут HTTP-клиента при вызове `logAgentSchedule`
* **Проблема:** В `schedule_monitor/tools.ts` вызов `apiClient.post` выполняется с дефолтным таймаутом (30 секунд).
* **Последствия:** Поскольку `logAgentSchedule` вызывается на каждом тике (включая ранние выходы), при сетевых задержках или недоступности бэкенда каждый тик будет блокироваться на 30 секунд, задерживая cron-расписание.

---

## 4. Рекомендации и предложения (Предложения)

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

Все 8 выявленных замечаний полностью устранены, кодовая база проверена и протестирована:

| № | Замечание | Что сделано | Статус |
|---|---|---|---|
| 1 | CLI-флаг `--task <key>` | Добавлен парсинг `--task` в `index.ts`, поле `taskKey` в `OrchestratorTickInputSchema`/`OrchestratorTickOptions`. В `orchestrator.agent.ts` реализован точечный сброс задачи в `PENDING` (`attempts = 0`, `log_id = null`, событие `TASK_RESET_MANUAL`) и запуск. Покрыто тестом. | **Устранено** |
| 2 | Статический список в `buildAgentRegistry` | В `shared/agent_registry.ts` реализовано динамическое сканирование каталогов первого уровня через `fs.readdirSync(root)` с проверкой наличия `agent.ts` / `agent.js` / `dist/...` и загрузкой манифеста. Добавление новой папки агента теперь не требует правок кода. | **Устранено** |
| 3 | Каскадное перевооружение зависимых задач | В блоке 1.1.1 `orchestrator.agent.ts` добавлен цикл каскадного перевооружения: при перевооружении задачи со `schedule` (например, `getEarved`) все зависимые задачи (`sendFinBitReport`) также сбрасываются в `PENDING` (`TASK_REARMED`). Покрыто тестом. | **Устранено** |
| 4 | Дата тика `targetDateStr` по UTC | Вычисление `targetDateStr` переведено на часовой пояс оркестратора: `new Intl.DateTimeFormat('en-CA', { timeZone: timezone }).format(currentDate)`. Устранено смещение даты в Эстонии с 00:00 до 03:00. | **Устранено** |
| 5 | Приоритет параметров `task.params.logId` | Во всех 4 местах объединения параметров восстановлен приоритет: `task.params = { ...(task.params \|\| {}), ...parentParams, ...(task.params?.logId ? { logId: task.params.logId } : {}) }`. Явно заданный `logId` не затирается. Покрыто тестом. | **Устранено** |
| 6 | Архитектурная коллизия `schedule_monitor` | `schedule_monitor` исключен из `pendingKeys` (не запускается как расчетная задача DAG) и из `calcTasks` (не блокирует отправку отчета `reporter`). Запуск производится штатно на каждом выходе из тика через `invokeScheduleMonitorSafe`. | **Устранено** |
| 7 | Несогласованный `userId: 11770` в `getEarved` | Документировано в `getEarved/config.json` и таблице `AGENT.md`: `11770` — это выделенный сервисный аккаунт FinBit в buh70 с правами API. | **Устранено** |
| 8 | Таймаут вызова `logAgentSchedule` | В `schedule_monitor/tools.ts` вызов `apiClient.post` снабжен таймаутом `{ timeoutMs: 5000 }`, исключая задержки тика при сетевых сбоях. | **Устранено** |

**Результаты проверок:**
- Jest: **10 test suites, 93 tests passed (100% PASS)**
- TypeScript build (`npm run build`): **0 errors**
