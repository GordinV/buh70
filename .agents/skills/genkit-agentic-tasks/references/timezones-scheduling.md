# Работа со временем, расписанием и часовыми поясами (Timezones & Scheduling)

## 1. Ловушка UTC vs Local Time при вызове LLM

Одна из самых частых и трудноуловимых ошибок в AI-оркестраторах — передача времени в формате ISO UTC без контекста часового пояса.

### Как возникает рассинхрон:
1. В Эстонии (Таллинн) летом действует часовой пояс **UTC+3** (`Europe/Tallinn`, EEST).
2. Текущее местное время: **08:20**.
3. Код формирует контекст: `currentDate.toISOString()`, что дает строку: `2026-09-21T05:20:35.123Z`.
4. В конфигурации задачи указано: `"prompt": "Запустить задачу в 07:00 утра каждого дня"`.
5. Модель Gemini считывает `currentServerTime: 05:20` и делает логичный, но неверный для бизнеса вывод:
   > *«Текущее время 05:20 меньше 07:00. Задача должна ожидать.»*
6. В результате задача задерживается на **3 часа** и стартует только в 10:00 утра по местному времени!

---

## 2. Лучшие практики передачи времени в контекст LLM

В схему контекста (`DecisionContext`) необходимо явно включать локальное время и часовой пояс:

```typescript
export interface DecisionContext {
  currentServerTimeUtc: string;      // "2026-09-21T05:20:35Z"
  localTimeFormatted: string;        // "08:20:35"
  localDateFormatted: string;        // "2026-09-21"
  timezone: string;                  // "Europe/Tallinn"
  schedule?: TaskSchedule | null;
  // ...
}
```

Формирование с помощью `Intl.DateTimeFormat`:
```typescript
const formatter = new Intl.DateTimeFormat('en-GB', {
  timeZone: timezone || 'Europe/Tallinn',
  hour: '2-digit',
  minute: '2-digit',
  second: '2-digit',
  hour12: false,
});
const localTimeStr = formatter.format(currentDate); // "08:20:35"
```

---

## 3. Разделение ответственности: Детерминированный планировщик vs AI Prompt

Для надежности системы соблюдайте четкое правило:

| Тип условия | Где описывать | Пример |
| :--- | :--- | :--- |
| **Фиксированное время суток** | `schedule: { time: "07:00" }` | Каждый день в 07:00 |
| **День месяца / месяц года** | `schedule: { day: 1, time: "20:00" }` | 1-го числа каждого месяца |
| **Семантическое бизнес-правило** | `prompt: "..."` | Перезапуск в тестовом режиме (`localhost`), проверка статусов email |
| **Зависимость от других задач** | `depends_on: ["saldoandmik"]` | Запуск сразу после сальдоандмика |

### Когда ставить `prompt: null`:
Если задача должна просто запускаться по времени (например, импорт счетов в 07:00), устанавливайте:
```json
{
  "name": "getEarved",
  "schedule": {
    "time": "07:00"
  },
  "prompt": null
}
```
В этом случае оркестратор использует быстрый и детерминированный алгоритм `isTaskScheduleReady`:
```typescript
const currentTotalMinutes = localHour * 60 + localMinute;
const schedTotalMinutes = schedHours * 60 + schedMinutes;
if (currentTotalMinutes >= schedTotalMinutes) {
  return { ready: true, shouldSkip: false };
}
```
Это исключает галлюцинации LLM, сетевые задержки и расходы токенов на тривиальные проверки часов.
