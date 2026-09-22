/**
 * Пример реализации тик-функции FSM-оркестратора с гибридным AI-принятием решений
 */
import { genkit } from 'genkit';
import { googleAI } from '@genkit-ai/googleai';
import { z } from 'zod';

// Схема решения о запуске задачи
export const LaunchDecisionSchema = z.object({
  should_run: z.boolean(),
  action: z.enum(['RUN', 'WAIT', 'SKIP']),
  reason: z.string(),
  dynamic_params: z.record(z.unknown()).optional(),
});

export async function runTickExample(
  state: any,
  currentDate: Date,
  options: { ai?: any; modelName?: string } = {}
) {
  console.log(`[tick] Запуск тика на дату: ${currentDate.toISOString()}`);

  // 1. Проверка активных задач (RUNNING)
  for (const [key, task] of Object.entries<any>(state.tasks)) {
    if (task.status === 'RUNNING') {
      // опрос логов через logs_watcher ...
    }
  }

  // 2. Отбор задач, готовых к запуску (PENDING)
  const readyKeys: string[] = [];

  for (const [key, task] of Object.entries<any>(state.tasks)) {
    if (task.status !== 'PENDING') continue;

    // Проверка сбоев в предшественниках
    const depFailed = task.depends_on.some(
      (dep: string) => state.tasks[dep]?.status === 'FAILED' || state.tasks[dep]?.status === 'SKIPPED'
    );
    if (depFailed) {
      task.status = 'SKIPPED';
      task.error = 'Предшественник завершился со сбоем';
      continue;
    }

    // Проверка готовности предшественников
    const allDepsDone = task.depends_on.every((dep: string) => state.tasks[dep]?.status === 'SUCCESS');
    if (!allDepsDone) {
      continue; // Ожидаем завершения зависимостей
    }

    // Parent Context Forwarding: инъекция параметров от родителя
    if (key === 'childTask' && !task.params?.parentId && state.tasks['parentTask']?.log_id) {
      task.params = { ...task.params, parentId: state.tasks['parentTask'].log_id };
    }

    // Принятие решения: LLM (если есть prompt) или FSM
    if (task.prompt && options.ai) {
      try {
        const response = await options.ai.generate({
          model: options.modelName || 'googleai/gemini-1.5-flash',
          prompt: `Task: ${key}\nRules: ${task.prompt}\nContext: ${JSON.stringify(task)}`,
          output: { schema: LaunchDecisionSchema },
        });

        if (response.output?.action === 'RUN') {
          readyKeys.push(key);
        }
        continue;
      } catch (err) {
        console.warn(`[tick] Fallback на FSM из-за ошибки LLM:`, err);
      }
    }

    // Детерминированное расписание (FSM)
    if (!task.schedule) {
      readyKeys.push(key);
    } else {
      const [h, m] = task.schedule.time.split(':').map(Number);
      const nowMinutes = currentDate.getHours() * 60 + currentDate.getMinutes();
      if (nowMinutes >= h * 60 + m) {
        readyKeys.push(key);
      }
    }
  }

  // 3. Параллельный запуск отобранных задач
  for (const key of readyKeys) {
    const task = state.tasks[key];
    console.log(`[tick] Запуск задачи: ${key}`);
    task.status = 'RUNNING';
    task.attempts = 1;
    task.started_at = currentDate.toISOString();
    // вызов POST /task/<key>/ ...
  }

  return state;
}
