# Мониторинг фоновых задач в БД (logs_watcher), обработка ошибок и пустых выборок

## 1. Паттерн асинхронного неблокирующего запуска

Тяжелые финансовые расчеты в базе данных не должны удерживать открытое HTTP-соединение:

```text
[AI-Оркестратор] ---> POST /task/calcKondSaldoandmik/ ---> [Бэкенд Express]
                                                                |
                                                                +---> 1. INSERT INTO ou.logs (...) RETURNING id (log_id)
                                                                +---> 2. Запуск расчета в фоне (без await)
                                                                +---> 3. HTTP 200 { status: 200, result: 1, log_id: 10425, data: { status: "STARTED" } }
```

### Единая схема ответа старта (`AsyncTaskStartResponseSchema`):
```typescript
export const AsyncTaskStartResponseSchema = z.object({
  status: z.number().describe('HTTP статус код ответа'),
  result: z.number().describe('Числовой результат операции (1 - успех запуска)'),
  log_id: z.number().describe('Идентификатор лог-записи в ou.logs'),
  data: z
    .object({
      action: z.string().optional(),
      status: z.string().optional(),
      log_id: z.number().optional(),
      result: z.unknown().optional(),
    })
    .optional(),
  error_message: z.string().nullable().optional(),
});
```

---

## 2. Мониторинг прогресса через `logs_watcher`

На каждом последующем тике оркестратор опрашивает статус выполнения:

```typescript
export async function watchTaskUntilDone(
  input: WatchTaskInput,
  options: WatchTaskOptions = {}
): Promise<WatchTaskOutput> {
  const startTime = Date.now();
  while (true) {
    const logs = await readTaskLog(input.userId, input.taskName, options.apiClient);
    const latest = logs[0];

    if (latest && latest.status) {
      // Проверка на скрытые сбои даже при формальном статусе 'success'
      const inspected = inspectLogExecutionResult(latest);
      return {
        status: inspected.status, // 'success' | 'failed'
        execStart: latest.exec_start,
        execEnd: latest.exec_end || undefined,
        durationMs: Date.now() - startTime,
        error: inspected.error || undefined,
      };
    }

    if (Date.now() - startTime > maxTimeoutMs) {
      return { status: 'timeout', durationMs: Date.now() - startTime };
    }
    await sleep(pollIntervalMs);
  }
}
```

---

## 3. Критическое правило: Штатная обработка пустых выборок (No-op / 0 записей)

### Проблема:
Если на дату запроса нет новых счетов или документов (например, в выходной день), бэкенд не должен возвращать `HTTP 500 { result: null, error_message: 'Arveid ei leitud' }`! Это приводит к падению Zod-валидации, сбою субагента и блокировке всего цикла.

### Правильное решение на стороне бэкенда:
```javascript
// В бэкенд-роуте:
if (!batches.length) {
  if (isAgent) {
    // Штатная ситуация: 0 счетов за дату. Создаем и закрываем лог
    const logResult = await createLog(rekvId, userId, flowName);
    const logId = logResult?.data?.[0]?.id || null;
    if (logId) {
      await endLog(logId, 'success', null);
    }
    return res.status(200).send({
      status: 200,
      result: 1,
      log_id: logId,
      data: {
        action: flowName,
        status: 'COMPLETED',
        log_id: logId,
        result: { count: 0, message: 'Arveid ei leitud (0 arvet)' }
      },
      error_message: null
    });
  }
}
```

### Защитный fallback на стороне субагента:
```typescript
// В tools.ts субагента:
const rawResponse = await apiClient.post<unknown>('/task/getEarved/', payload);

// Защита от legacy-ответа бэкенда при 0 записей
if (
  rawResponse &&
  typeof rawResponse === 'object' &&
  'error_message' in rawResponse &&
  (rawResponse as { error_message?: string }).error_message === 'Arveid ei leitud'
) {
  return {
    status: 200,
    result: 1,
    log_id: 0,
    data: { action: 'Import FinBit arved', status: 'COMPLETED', log_id: 0 },
    error_message: null,
  };
}
return StartGetEarvedResponseSchema.parse(rawResponse);
```

---

## 4. Обнаружение скрытых ошибок (Semantic Log Inspection)

Иногда процедура или отправка email завершается с кодом успеха в БД, но в теле ответа присутствуют сетевые таймауты:
```json
{
  "status": "success",
  "result": [
    { "email": "user@example.com", "success": false, "error": "connect ETIMEDOUT" }
  ]
}
```

Функция `inspectLogExecutionResult` обязана глубоко инспектировать поле `result`:
1. Рекурсивный поиск подстрок `ETIMEDOUT`, `ECONNREFUSED`, `SMTP`, `failed`.
2. Если обнаружены ошибки при статусе `success`, задача переводится в `FAILED` для отправки на повторную попытку (Retry).
