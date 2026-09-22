import * as dotenv from 'dotenv';
import { genkit } from 'genkit';
import { googleAI, gemini15Flash } from '@genkit-ai/googleai';

dotenv.config();

// Субагенты и инструменты
import { getConfig } from './shared/api_client';
import {
  WatchTaskInputSchema,
  WatchTaskOutputSchema,
} from './logs_watcher/schemas';
import { watchTaskUntilDone } from './logs_watcher/agent';
import {
  StartSaldoandmikInputSchema,
  SaldoandmikResultSchema,
} from './saldoandmik/schemas';
import { runSaldoandmikSubagent } from './saldoandmik/agent';
import {
  StartCalcArvJaakInputSchema,
  CalcArvJaakResultSchema,
} from './calc_arv_jaak/schemas';
import { runCalcArvJaakSubagent } from './calc_arv_jaak/agent';
import {
  StartGetEarvedInputSchema,
  GetEarvedResultSchema,
} from './getEarved/schemas';
import { runGetEarvedSubagent } from './getEarved/agent';
import {
  StartSendFinBitReportInputSchema,
  SendFinBitReportResultSchema,
} from './sendFinBitReport/schemas';
import { runSendFinBitReportSubagent } from './sendFinBitReport/agent';
import {
  StartLisa1Lisa5InputSchema,
  Lisa1Lisa5ResultSchema,
} from './lisa1_lisa5/schemas';
import { runLisa1Lisa5Subagent } from './lisa1_lisa5/agent';
import {
  GenerateReportInputSchema,
  SendReportResponseSchema,
} from './reporter/schemas';
import { generateAndSendReportSubagent } from './reporter/agent';
import {
  AgentLaunchDecision,
  AgentLaunchDecisionSchema,
  CycleDecision,
  CycleDecisionContext,
  CycleDecisionSchema,
  DecisionContext,
  OrchestratorInputSchema,
  OrchestratorOutputSchema,
  OrchestratorTickInputSchema,
  OrchestratorTickOutputSchema,
  TaskResultContext,
  TaskResultEvaluation,
  TaskResultEvaluationSchema,
} from './orchestrator/orchestrator.schemas';
import {
  runOrchestrator,
  runOrchestratorTick,
} from './orchestrator/orchestrator.agent';

const config = getConfig();

export function resolveModelName(modelName?: string): string {
  const n = (modelName || 'gemini-1.5-flash').trim();
  return n.startsWith('googleai/') ? n : `googleai/${n}`;
}

export const configuredModelName = resolveModelName(config.geminiModel);

// Инициализация Genkit
export const ai = genkit({
  plugins: config.geminiApiKey ? [googleAI({ apiKey: config.geminiApiKey })] : [],
  model: configuredModelName,
});

/**
 * Genkit Flow: Мониторинг логов (logs_watcher)
 */
export const logsWatcherFlow = ai.defineFlow(
  {
    name: 'logsWatcherFlow',
    inputSchema: WatchTaskInputSchema,
    outputSchema: WatchTaskOutputSchema,
  },
  async (input) => watchTaskUntilDone(input)
);

/**
 * Genkit Flow: Расчет сальдоандмика (saldoandmik)
 */
export const saldoandmikFlow = ai.defineFlow(
  {
    name: 'saldoandmikFlow',
    inputSchema: StartSaldoandmikInputSchema,
    outputSchema: SaldoandmikResultSchema,
  },
  async (input) => runSaldoandmikSubagent(input)
);

/**
 * Genkit Flow: Пересчет остатков счетов (calc_arv_jaak)
 */
export const calcArvJaakFlow = ai.defineFlow(
  {
    name: 'calcArvJaakFlow',
    inputSchema: StartCalcArvJaakInputSchema,
    outputSchema: CalcArvJaakResultSchema,
  },
  async (input) => runCalcArvJaakSubagent(input)
);

/**
 * Genkit Flow: Импорт счетов FinBit (getEarved)
 */
export const getEarvedFlow = ai.defineFlow(
  {
    name: 'getEarvedFlow',
    inputSchema: StartGetEarvedInputSchema,
    outputSchema: GetEarvedResultSchema,
  },
  async (input) => runGetEarvedSubagent(input)
);

/**
 * Genkit Flow: Отправка отчетов FinBit по импортированным счетам (sendFinBitReport)
 */
export const sendFinBitReportFlow = ai.defineFlow(
  {
    name: 'sendFinBitReportFlow',
    inputSchema: StartSendFinBitReportInputSchema,
    outputSchema: SendFinBitReportResultSchema,
  },
  async (input) => runSendFinBitReportSubagent(input)
);

/**
 * Genkit Flow: Контроль Lisa 1 / Lisa 5 (lisa1_lisa5)
 */
export const lisa1Lisa5Flow = ai.defineFlow(
  {
    name: 'lisa1Lisa5Flow',
    inputSchema: StartLisa1Lisa5InputSchema,
    outputSchema: Lisa1Lisa5ResultSchema,
  },
  async (input) => runLisa1Lisa5Subagent(input)
);

/**
 * Genkit Flow: Формирование и отправка отчета (reporter)
 */
export const reporterFlow = ai.defineFlow(
  {
    name: 'reporterFlow',
    inputSchema: GenerateReportInputSchema,
    outputSchema: SendReportResponseSchema,
  },
  async (input) => generateAndSendReportSubagent(input)
);

/**
 * Формирует функцию генерации решений через Gemini (Genkit), если API ключ задан в окружении
 */
function getAiGenerateFn() {
  if (!config.geminiApiKey) {
    return undefined;
  }
  return async (promptText: string, context: DecisionContext): Promise<AgentLaunchDecision> => {
    // Если задан тестовый/моковый ключ (напр. mock_gemini_api_key), эмулируем принятие решения
    if (config.geminiApiKey.startsWith('mock_')) {
      const isTestMode =
        typeof context.apiBaseUrl === 'string' &&
        (context.apiBaseUrl.includes('localhost') || context.apiBaseUrl.includes('127.0.0.1'));
      const isSuccess =
        context.taskStatus === 'SUCCESS' ||
        (context.params as Record<string, unknown>)?.status === 'success';

      if (isTestMode && (isSuccess || context.taskStatus === 'PENDING')) {
        return {
          should_run: true,
          action: 'RUN',
          reason: `[MOCK-LLM] Режим тестирования подтвержден (localhost в ${context.apiBaseUrl}), статус: ${context.taskStatus}. Решение: запуск разрешен по правилам промпта.`,
        };
      }
      return {
        should_run: false,
        action: 'WAIT',
        reason: `[MOCK-LLM] Режим тестирования: условия запуска не удовлетворены (status=${context.taskStatus}).`,
      };
    }

    const response = await ai.generate({
      model: configuredModelName,
      prompt: `You are an intelligent autonomous orchestrator for budget accounting tasks (buh70).
Task Agent: ${context.agentName}
Agent Prompt / Rules: ${promptText}

Current Decision Context:
${JSON.stringify(context, null, 2)}

Important Time & Scheduling Guidelines:
- If evaluating time of day or daily schedules, ALWAYS refer to context.localTime and context.timezone (local business time), NEVER confuse it with UTC in currentServerTime.
- If context.isScheduleDue is true, the task's schedule condition has already arrived in the local timezone.

Evaluate the rules in the prompt against the context.
Return structured decision:
- should_run: boolean (whether the task should start now)
- reason: concise explanation
- action: "RUN" | "WAIT" | "SKIP"
- dynamic_params: optional object with updated task parameters if needed`,
      output: { schema: AgentLaunchDecisionSchema },
    });
    if (response.output) {
      return response.output;
    }
    throw new Error('LLM did not return structured output');
  };
}

/**
 * Формирует функцию генерации решений верхнего уровня по циклу через Gemini (Meta-Orchestrator)
 */
function getAiCycleGenerateFn() {
  if (!config.geminiApiKey) {
    return undefined;
  }
  return async (promptText: string, context: CycleDecisionContext): Promise<CycleDecision> => {
    // Если задан тестовый/моковый ключ (напр. mock_gemini_api_key), эмулируем решение по мета-промпту
    if (config.geminiApiKey.startsWith('mock_')) {
      const isTestMode =
        typeof context.apiBaseUrl === 'string' &&
        (context.apiBaseUrl.includes('localhost') || context.apiBaseUrl.includes('127.0.0.1'));

      if (isTestMode) {
        return {
          action: 'RUN_CYCLE',
          force_run: true,
          reason: `[MOCK-LLM] Режим тестирования подтвержден (localhost в ${context.apiBaseUrl}). Суточный цикл открыт принудительно (force_run=true).`,
        };
      }
      return {
        action: 'WAIT_SCHEDULE',
        force_run: false,
        reason: `[MOCK-LLM] Рабочий режим. Ожидание времени ${context.dailyStartTime}.`,
      };
    }

    const response = await ai.generate({
      model: configuredModelName,
      prompt: `You are an intelligent autonomous meta-orchestrator for budget accounting routine processes (buh70).
Your goal: Evaluate whether to open the daily calculation cycle right now, wait for schedule, or pause/skip.
Meta Orchestrator Prompt / Rules:
${promptText}

Current Cycle Decision Context:
${JSON.stringify(context, null, 2)}

Return structured decision:
- action: "RUN_CYCLE" | "WAIT_SCHEDULE" | "SKIP_CYCLE" | "PAUSE_CYCLE"
- force_run: boolean (set to true if rules allow running before dailyStartTime, e.g. in test mode or urgent recalculation)
- reason: concise explanation of the decision
- cycle_params_override: optional object with updated cycle parameters`,
      output: { schema: CycleDecisionSchema },
    });
    if (response.output) {
      return response.output;
    }
    throw new Error('LLM did not return structured cycle output');
  };
}

/**
 * Формирует функцию семантической оценки результатов выполнения задачи через Gemini (Genkit)
 */
function getAiTaskResultGenerateFn() {
  if (!config.geminiApiKey) {
    return undefined;
  }
  return async (promptText: string, context: TaskResultContext): Promise<TaskResultEvaluation> => {
    // Если задан тестовый/моковый ключ (напр. mock_gemini_api_key), эмулируем семантическую оценку
    if (config.geminiApiKey.startsWith('mock_')) {
      if (context.hasErrors) {
        return {
          is_success: false,
          status: 'FAILED',
          summary: context.resultSummary || 'Vead täitmisel',
          error: context.errorDetails || context.logError || 'Viga logides',
        };
      }
      return {
        is_success: true,
        status: 'SUCCESS',
        summary: context.resultSummary || 'Edukalt täidetud',
        error: null,
      };
    }

    const response = await ai.generate({
      model: configuredModelName,
      prompt: `You are an intelligent autonomous controller and auditor for budget accounting tasks (buh70).
Task Agent: ${context.agentName}
Task Flow: ${context.flow}
Controller Prompt / Rules: ${promptText}

Task Execution Results from ou.logs:
${JSON.stringify(context, null, 2)}

Evaluate whether the task execution was truly successful or if it failed based on the prompt instructions and the execution details (check result array, individual recipient statuses, SMTP timeouts, connection errors).
Return structured decision:
- is_success: boolean (true if all critical requirements are satisfied, false if any errors/failures)
- status: "SUCCESS" | "FAILED"
- summary: concise informational summary for the final report. IMPORTANT: The final report is strictly in Estonian. You MUST write the summary in Estonian (e.g. "Ülesanne docs.check_arv_jaak edukalt täidetud ilma vigadeta"), NEVER in Russian!
- error: description of errors if failed, or null if successful`,
      output: { schema: TaskResultEvaluationSchema },
    });
    if (response.output) {
      return response.output;
    }
    throw new Error('LLM did not return structured task result evaluation output');
  };
}

/**
 * Genkit Flow: Исполнитель тика оркестратора (orchestratorTickFlow)
 */
export const orchestratorTickFlow = ai.defineFlow(
  {
    name: 'orchestratorTickFlow',
    inputSchema: OrchestratorTickInputSchema,
    outputSchema: OrchestratorTickOutputSchema,
  },
  async (input) =>
    runOrchestratorTick(input, {
      aiGenerateFn: getAiGenerateFn(),
      aiCycleGenerateFn: getAiCycleGenerateFn(),
      aiTaskResultGenerateFn: getAiTaskResultGenerateFn(),
    })
);

/**
 * Genkit Flow: Полный запуск оркестратора (orchestratorFlow)
 */
export const orchestratorFlow = ai.defineFlow(
  {
    name: 'orchestratorFlow',
    inputSchema: OrchestratorInputSchema,
    outputSchema: OrchestratorOutputSchema,
  },
  async (input) => runOrchestrator(input)
);

/**
 * CLI запуск при вызове напрямую (node dist/index.js или npx tsx index.ts)
 */
async function main() {
  const args = process.argv.slice(2);

  // Парсинг базовых CLI-флагов
  const forceRun = args.includes('--force');
  const isFullRun = args.includes('--full');

  const userIdx = args.indexOf('--user');
  const userId = userIdx !== -1 ? parseInt(args[userIdx + 1], 10) : config.defaultUserId;

  const rekvIdx = args.indexOf('--rekv');
  const rekvId = rekvIdx !== -1 ? parseInt(args[rekvIdx + 1], 10) : config.defaultRekvId;

  const dateIdx = args.indexOf('--date');
  const targetDateStr = dateIdx !== -1 ? args[dateIdx + 1] : undefined;

  const statePathIdx = args.indexOf('--state');
  const stateFilePath = statePathIdx !== -1 ? args[statePathIdx + 1] : undefined;

  if (isFullRun) {
    console.log(`=== buh70 AI-Orkestraatori täistsükli käivitamine (--full) ===`);
    console.log(`Parameetrid: userId=${userId}, rekvId=${rekvId}, forceRun=${forceRun}`);

    const result = await runOrchestrator(
      { userId, rekvId, forceRun },
      { targetDateStr }
    );

    console.log(`\n=== Täitmise tulemus: ${result.message} ===`);
    console.log(JSON.stringify(result, null, 2));
  } else {
    // По умолчанию: выполнение одного тика FSM
    console.log(`=== buh70 AI-Orkestraatori tikk-käivitamine (Stateless FSM Tick) ===`);
    console.log(`Parameetrid: userId=${userId}, rekvId=${rekvId}, forceRun=${forceRun}`);

    const result = await runOrchestratorTick(
      { userId, rekvId, forceRun, stateFilePath },
      {
        targetDateStr,
        aiGenerateFn: getAiGenerateFn(),
        aiCycleGenerateFn: getAiCycleGenerateFn(),
        aiTaskResultGenerateFn: getAiTaskResultGenerateFn(),
      }
    );

    console.log(`\n=== Tigi tulemus: ${result.message} [${result.action}] ===`);
    console.log(JSON.stringify(result, null, 2));
  }
}

// Запускаем CLI только если скрипт вызван напрямую
if (require.main === module) {
  main().catch((err) => {
    console.error('Orkestraatori käivitamise saatuslik viga:', err);
    process.exit(1);
  });
}
