# Structured Output и гибридное принятие решений в Genkit

## 1. Конфигурация Genkit с поддержкой Gemini

```typescript
import { genkit } from 'genkit';
import { googleAI } from '@genkit-ai/googleai';
import { z } from 'zod';

export const ai = genkit({
  plugins: [
    googleAI({
      apiKey: process.env.GEMINI_API_KEY,
    }),
  ],
});
```

Нормализация имени модели (поддержка `gemini-3.7-flash`, `gemini-1.5-flash`, `gemini-2.5-flash`):
```typescript
export function resolveModelName(rawName?: string): string {
  const name = rawName?.trim() || 'gemini-1.5-flash';
  if (name.startsWith('googleai/')) {
    return name;
  }
  return `googleai/${name}`;
}
```

---

## 2. Zod-схемы для Structured Output

LLM должна возвращать строго типизированные объекты, валидируемые через Zod:

### Схема решения о запуске задачи (Task Launch Decision):
```typescript
export const AgentLaunchDecisionSchema = z.object({
  should_run: z.boolean().describe('Следует ли запустить задачу прямо сейчас'),
  reason: z.string().describe('Краткое обоснование принятого решения'),
  action: z.enum(['RUN', 'WAIT', 'SKIP']).default('RUN').describe('Предписанное действие'),
  dynamic_params: z.record(z.unknown()).optional().describe('Скорректированные параметры вызова'),
});
export type AgentLaunchDecision = z.infer<typeof AgentLaunchDecisionSchema>;
```

### Схема семантической оценки логов (Task Result Evaluation):
```typescript
export const TaskResultEvaluationSchema = z.object({
  is_success: z.boolean().describe('Является ли выполнение задачи успешным'),
  status: z.enum(['SUCCESS', 'FAILED']).describe('Итоговый статус задачи'),
  summary: z.string().describe('Краткое информативное резюме для итогового отчета'),
  error: z.string().nullable().optional().describe('Текст ошибки, если задача упала'),
});
```

---

## 3. Гибридный алгоритм (Prompt Priority + FSM Fallback)

Главный принцип надежности: **система не должна ломаться при сбоях LLM или отсутствии сети**.

```typescript
export async function evaluateTaskLaunchDecision(
  key: string,
  task: TaskState,
  context: DecisionContext,
  aiGenerateFn?: (prompt: string, ctx: DecisionContext) => Promise<AgentLaunchDecision>
): Promise<AgentLaunchDecision> {
  // 1. Приоритет промпта: если задан prompt, обращаемся к LLM
  if (task.prompt && task.prompt.trim().length > 0) {
    if (aiGenerateFn) {
      try {
        const decision = await aiGenerateFn(task.prompt, context);
        return AgentLaunchDecisionSchema.parse(decision);
      } catch (llmErr) {
        console.warn(`[orchestrator] LLM сбой для ${key}, переключение на FSM fallback:`, llmErr);
      }
    }
  }

  // 2. Детерминированный fallback (FSM):
  // Проверка предшественников, расписания по часам и суточного окна
  const schedCheck = isTaskScheduleReady(task.schedule, new Date());
  if (schedCheck.ready) {
    return { should_run: true, action: 'RUN', reason: 'Детерминированное правило FSM' };
  }
  return { should_run: false, action: 'WAIT', reason: schedCheck.reason || 'Ожидание по расписанию' };
}
```

---

## 4. Паттерн мокирования в Unit-тестах Jest

Для тестирования логики без обращения к внешнему Gemini API функции генерации передаются через dependency injection:

```typescript
it('должен корректно обрабатывать структурированный ответ LLM', async () => {
  const mockAiFn = jest.fn().mockResolvedValue({
    should_run: true,
    action: 'RUN',
    reason: 'Mocked LLM launch',
  });

  const decision = await evaluateTaskLaunchDecision('calc_arv_jaak', taskState, context, mockAiFn);
  expect(decision.action).toBe('RUN');
  expect(mockAiFn).toHaveBeenCalledTimes(1);
});
```
