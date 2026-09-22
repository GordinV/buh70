# Архитектура Stateless FSM Оркестратора на базе Genkit

## 1. Концепция Stateless FSM и State Dump Memory

Оркестратор регламентных задач не работает в режиме непрерывно висящего в оперативной памяти сервиса. Вместо этого он построен по модели **тик-исполнения (Tick-based Execution)**:

1. Внешний триггер (системный планировщик `cron`, Windows Task Scheduler или Cloud Scheduler) с заданной периодичностью (например, каждую минуту или каждые 5 минут) вызывает скрипт запуска:
   ```cmd
   node dist/index.js >> state/cron_tick.log 2>&1
   ```
2. Процесс считывает текущий срез выполнения из файла `state/orchestrator_state.json`.
3. Анализирует состояние каждой задачи в графе:
   - Если задача в статусе `RUNNING`, опрашивает её актуальный статус через `POST /task/read_log/:user_id/:task_name`.
   - Если задача завершилась (`SUCCESS`), переводит её в `SUCCESS` и разблокирует зависимые шаги.
   - Если задача упала (`FAILED`), увеличивает счетчик `attempts` и при `attempts < max_attempts` отправляет на повторный запуск (Retry).
4. Проверяет задачи в статусе `PENDING`:
   - Если зависимости удовлетворены и расписание/AI-контроллер разрешают запуск, инициирует неблокирующий старт (`STARTED`).
5. Атомарно сохраняет обновленное состояние на диск и **немедленно завершает процесс**.

---

## 2. Атомарное сохранение состояния на диске (Windows-safe)

При работе на Windows операции перезаписи файлов могут блокироваться антивирусными сканерами или другими процессами (`EBUSY`, `EPERM`).

### Надежный паттерн сохранения:
```typescript
public async saveState(state: OrchestratorState): Promise<void> {
  const validated = OrchestratorStateSchema.parse(state);
  const dir = path.dirname(this.resolvedPath);
  if (!fs.existsSync(dir)) {
    await fs.promises.mkdir(dir, { recursive: true });
  }

  const tempPath = `${this.resolvedPath}.${Date.now()}.tmp`;
  const content = JSON.stringify(validated, null, 2);

  await fs.promises.writeFile(tempPath, content, 'utf8');
  try {
    // 1. Попытка быстрого атомарного переименования
    await fs.promises.rename(tempPath, this.resolvedPath);
  } catch (renameErr: unknown) {
    // 2. Резервный механизм для Windows при блокировке дескрипторов
    await fs.promises.copyFile(tempPath, this.resolvedPath);
    await fs.promises.unlink(tempPath).catch(() => {});
  }
}
```

В `.gitignore` обязательно исключать временные файлы:
```text
state/*.json
!state/.gitkeep
state/*.log
*.log
*.tmp
```

---

## 3. Граф зависимостей (DAG) и Parent Context Forwarding

### Определение зависимостей
Каждый агент декларирует свои зависимости в `config.json`:
```json
{
  "name": "sendFinBitReport",
  "flow": "sendFinBitReport",
  "depends_on": ["getEarved"],
  "allow_parallel": true
}
```

### Parent Context Forwarding (Проброс параметров)
Если дочерней задаче требуется результат или идентификатор лога вышестоящей задачи, оркестратор автоматически извлекает его из состояния родителя перед вызовом:
```typescript
// В orchestrator.agent.ts:
if (key === 'sendFinBitReport' && !task.params?.logId && state.tasks['getEarved']?.log_id) {
  task.params = { 
    ...(task.params || {}), 
    logId: state.tasks['getEarved'].log_id 
  };
}
```

### Каскадный пропуск (Cascade Skip)
Если родительская задача завершилась со сбоем (`FAILED`), зависимые от неё шаги автоматически помечаются как `SKIPPED`:
```typescript
const hasFailedDep = task.depends_on.some(
  (d) => state.tasks[d]?.status === 'FAILED' || state.tasks[d]?.status === 'SKIPPED'
);
if (hasFailedDep) {
  return {
    should_run: false,
    action: 'SKIP',
    reason: 'Vahele jäetud eelneva ülesande vea tõttu',
  };
}
```
