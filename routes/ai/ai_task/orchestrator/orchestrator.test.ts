import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import { ApiClient } from '../shared/api_client';
import {
  runOrchestrator,
  runOrchestratorTick,
  isTaskScheduleReady,
  evaluateTaskLaunchDecision,
  isDailyExecutionWindowOpen,
  evaluateCycleDecision,
  evaluateTaskResultDecision,
} from './orchestrator.agent';
import { TASK_FLOW_SALDOANDMIK } from '../saldoandmik/schemas';
import { TASK_FLOW_CALC_ARV_JAAK } from '../calc_arv_jaak/schemas';
import { TASK_FLOW_GET_EARVED } from '../getEarved/schemas';
import { TASK_FLOW_CHECK_ASUTUS } from '../check_asutus/schemas';
import { TASK_FLOW_IMPORT_EARVED } from '../import_earved/schemas';
import { TASK_FLOW_SEND_FIN_BIT_REPORT } from '../sendFinBitReport/schemas';
import { TASK_FLOW_LISA1_LISA5 } from '../lisa1_lisa5/schemas';
import {
  StateManager,
  calculateNextScheduledRun,
  createInitialState,
  getDefaultTaskGraph,
  loadAgentConfig,
  loadAllAgentConfigs,
  loadOrchestratorConfig,
  reconcileTasksWithConfigs,
  resetCycleForNewDay,
} from './state.manager';
import {
  AgentConfig,
  CycleDecision,
  CycleDecisionContext,
  DecisionContext,
  AgentLaunchDecision,
  OrchestratorConfig,
  OrchestratorState,
  TaskResultContext,
  TaskResultEvaluation,
  TaskState,
} from './orchestrator.schemas';
import { getConfig } from '../shared/api_client';
import { resolveModelName, parseTaskFlag } from '../index';
import { generateAndSendReportSubagent } from '../reporter/agent';

// Мокируем отправку отчета, чтобы исключить внешние сетевые SMTP-запросы во время тестов
jest.mock('../reporter/agent', () => ({
  generateAndSendReportSubagent: jest.fn().mockResolvedValue({
    sent: true,
    deliveryChannel: 'local_fallback',
    timestamp: '2026-09-15T20:00:00.000Z',
    formattedReport: 'Mock test report',
  }),
}));

// Мокируем runScheduleMonitor по умолчанию, чтобы не засорять сетевые моки остальных тестов
jest.mock('../schedule_monitor/agent', () => {
  const actual = jest.requireActual('../schedule_monitor/agent');
  return {
    ...actual,
    runScheduleMonitor: jest.fn().mockResolvedValue(12345),
  };
});
import { runScheduleMonitor } from '../schedule_monitor/agent';

// Файлы состояния тестов создаются в уникальном временном каталоге (а не рядом с тестом),
// чтобы параллельные воркеры Jest и повторные прогоны не пересекались по одним и тем же путям
const TEST_STATE_DIR = fs.mkdtempSync(path.join(os.tmpdir(), 'ai_task_orchestrator_test_'));
const testStatePath = (fileName: string): string => path.join(TEST_STATE_DIR, fileName);

// Реальные паузы повторов ApiClient в тестах отключены (jest.setup.js, API_RETRY_BASE_DELAY_MS=0), и на прогретой
// машине каждый тест занимает десятки миллисекунд. Но при полном параллельном прогоне под нагрузкой
// (в т.ч. при холодном кэше трансформации ts-jest) отдельные тесты этого файла всё равно выходили за стандартные
// 5 секунд (наблюдалось до 16 с), поэтому увеличенный лимит оставлен как страховка только для этого файла.
jest.setTimeout(30000);

afterAll(() => {
  // Очистка временного каталога вместе со всеми оставшимися файлами состояния
  fs.rmSync(TEST_STATE_DIR, { recursive: true, force: true });
});

describe('Главный Оркестратор', () => {
  // Уникальный файл состояния на каждый тест: тест, прерванный по таймауту и продолжающий
  // работать в фоне, не сможет перезаписать состояние следующего теста
  let testStateFile = testStatePath('test_orchestrator_state.json');
  let testStateSeq = 0;

  beforeEach(() => {
    testStateSeq += 1;
    testStateFile = testStatePath(`test_orchestrator_state_${testStateSeq}.json`);
  });

  afterEach(() => {
    if (fs.existsSync(testStateFile)) {
      try {
        fs.unlinkSync(testStateFile);
      } catch {
        // ignore
      }
    }
  });

  describe('runOrchestrator (Полный последовательный запуск)', () => {
    it('должен последовательно выполнить saldoandmik, calcArvJaak, getEarved и lisa1_lisa5 при чистой истории', async () => {
      const calledUrls: string[] = [];

      const mockFetch = jest.fn().mockImplementation(async (url: string) => {
        calledUrls.push(url);

        // Проверка истории
        if (url.includes('/task/read_log/')) {
          const isWatcherCall = calledUrls.filter((u) => u === url).length > 1;

          if (!isWatcherCall) {
            return {
              ok: true,
              status: 200,
              json: async () => ({ result: 1, data: [] }),
            };
          }

          let flow = TASK_FLOW_SALDOANDMIK;
          if (url.includes('docs.check_arv_jaak')) flow = TASK_FLOW_CALC_ARV_JAAK;
          if (url.includes('/getEarved')) flow = TASK_FLOW_GET_EARVED;
          if (url.includes('checkAsutusAvailability')) flow = TASK_FLOW_CHECK_ASUTUS;
          if (url.includes('docs.sp_loe_earved')) flow = TASK_FLOW_IMPORT_EARVED;
          if (url.includes('sendFinBitReport')) flow = TASK_FLOW_SEND_FIN_BIT_REPORT;
          if (url.includes('salvesta_lisa_1_5_kontrol')) flow = TASK_FLOW_LISA1_LISA5;

          return {
            ok: true,
            status: 200,
            json: async () => ({
              result: 1,
              data: [
                {
                  flow,
                  status: 'success',
                  exec_start: '2026-09-14T10:00:00.000Z',
                  exec_end: '2026-09-14T10:10:00.000Z',
                  ...(flow === TASK_FLOW_CHECK_ASUTUS ? { result: { missing: [], totalMissing: 0, source_log_id: 104 } } : {}),
                  ...(flow === TASK_FLOW_IMPORT_EARVED
                    ? { result: { totalFetched: 1, totalImported: 1, totalSkipped: 0, skipped: [], missing: [] } }
                    : {}),
                },
              ],
            }),
          };
        }

        // Запуск сальдо
        if (url.includes('/task/calcKondSaldoandmik/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 101,
              data: { action: 'calcKondSaldoandmik', status: 'STARTED', log_id: 101 },
            }),
          };
        }

        // Запуск пересчета остатков счетов
        if (url.includes('/task/calcArvJaak/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 102,
              data: { action: 'calcArvJaak', status: 'STARTED', log_id: 102 },
            }),
          };
        }

        // Запуск импорта счетов FinBit
        if (url.includes('/task/getEarved/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 104,
              data: { action: 'Import FinBit arved', status: 'STARTED', log_id: 104 },
            }),
          };
        }

        // Проверка контр-агентов (check_asutus)
        if (url.includes('/task/checkAsutusAvailability/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 106,
              data: { action: 'checkAsutusAvailability', status: 'STARTED', log_id: 106 },
            }),
          };
        }

        // Разбор и сохранение счетов (import_earved)
        if (url.includes('/task/importEarved/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 107,
              data: { action: 'importEarved', status: 'STARTED', log_id: 107 },
            }),
          };
        }

        // Запуск отправки отчета FinBit
        if (url.includes('/task/sendFinBitReport/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 105,
              data: { action: 'sendFinBitReport', status: 'STARTED', log_id: 105 },
            }),
          };
        }

        // Запуск контроля
        if (url.includes('/task/calcLisa1Lisa5/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 103,
              data: { action: 'calcLisa1Lisa5', status: 'STARTED', log_id: 103 },
            }),
          };
        }

        throw new Error(`Unhandled url: ${url}`);
      });

      const client = new ApiClient({}, mockFetch as unknown as typeof fetch);
      const result = await runOrchestrator(
        { userId: 2477, rekvId: 63, pollIntervalMs: 5 },
        { apiClient: client, sleepFn: jest.fn().mockResolvedValue(undefined), targetDateStr: '2026-09-14' }
      );

      expect(result.overallSuccess).toBe(true);
      expect(result.steps).toHaveLength(7);
      expect(result.steps[0].stepName).toBe(TASK_FLOW_SALDOANDMIK);
      expect(result.steps[0].status).toBe('SUCCESS');
      expect(result.steps[1].stepName).toBe(TASK_FLOW_CALC_ARV_JAAK);
      expect(result.steps[1].status).toBe('SUCCESS');
      expect(result.steps[2].stepName).toBe(TASK_FLOW_GET_EARVED);
      expect(result.steps[2].status).toBe('SUCCESS');
      expect(result.steps[3].stepName).toBe(TASK_FLOW_CHECK_ASUTUS);
      expect(result.steps[3].status).toBe('SUCCESS');
      expect(result.steps[4].stepName).toBe(TASK_FLOW_IMPORT_EARVED);
      expect(result.steps[4].status).toBe('SUCCESS');
      expect(result.steps[5].stepName).toBe(TASK_FLOW_SEND_FIN_BIT_REPORT);
      expect(result.steps[5].status).toBe('SUCCESS');
      // sendFinBitReport получает log_id именно лога импорта (docs.sp_loe_earved), а не выкачки getEarved
      expect(mockFetch.mock.calls.some((c) => String(c[0]).includes('/task/sendFinBitReport/') && String(c[1]?.body).includes('"logId":107'))).toBe(true);
      expect(result.steps[6].stepName).toBe(TASK_FLOW_LISA1_LISA5);
      expect(result.steps[6].status).toBe('SUCCESS');
    });

    it('должен останавливать выполнение Шага контроля Lisa 1/5, если расчет сальдо упал с ошибкой', async () => {
      const mockFetch = jest.fn().mockImplementation(async (url: string) => {
        if (url.includes('/task/read_log/')) {
          if (url.includes('docs.check_arv_jaak')) {
            return {
              ok: true,
              status: 200,
              json: async () => ({
                result: 1,
                data: [{ flow: TASK_FLOW_CALC_ARV_JAAK, status: 'success', exec_start: '2026-09-14T10:00:00.000Z' }],
              }),
            };
          }
          if (url.includes('/getEarved')) {
            return {
              ok: true,
              status: 200,
              json: async () => ({
                result: 1,
                data: [{ flow: TASK_FLOW_GET_EARVED, status: 'success', exec_start: '2026-09-14T10:00:00.000Z' }],
              }),
            };
          }
          return { ok: true, status: 200, json: async () => ({ result: 1, data: [] }) };
        }

        // Падение при старте сальдоандмика
        if (url.includes('/task/calcKondSaldoandmik/')) {
          return {
            ok: false,
            status: 500,
            statusText: 'Internal Server Error',
            text: async () => 'Database connection timeout',
          };
        }

        // Успешный запуск calcArvJaak (независимый поток)
        if (url.includes('/task/calcArvJaak/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 102,
              data: { action: 'calcArvJaak', status: 'STARTED', log_id: 102 },
            }),
          };
        }

        // Успешный запуск getEarved (независимый поток)
        if (url.includes('/task/getEarved/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 104,
              data: { action: 'Import FinBit arved', status: 'STARTED', log_id: 104 },
            }),
          };
        }

        throw new Error(`Unexpected URL: ${url}`);
      });

      const client = new ApiClient({}, mockFetch as unknown as typeof fetch);
      const result = await runOrchestrator(
        { userId: 2477, rekvId: 63, pollIntervalMs: 5 },
        { apiClient: client, sleepFn: jest.fn().mockResolvedValue(undefined), targetDateStr: '2026-09-14' }
      );

      expect(result.overallSuccess).toBe(false);
      expect(result.steps[0].status).toBe('FAILED');
      expect(result.steps[1].status).toBe('SKIPPED');
      expect(result.steps[2].status).toBe('SKIPPED');
      expect(result.steps[3].status).toBe('SKIPPED');
      expect(result.steps[3].error).toContain('Vahele jäetud saldoandmiku arvestuse vea tõttu');
    });
  });

  describe('runOrchestratorTick (Stateless FSM Tick Runner с памятью состояния и DAG)', () => {
    it('Тик 1: должен параллельно запустить независимые потоки (saldoandmik, calc_arv_jaak и getEarved) при открытии окна 20:00', async () => {
      const calledUrls: string[] = [];
      const mockFetch = jest.fn().mockImplementation(async (url: string) => {
        calledUrls.push(url);
        if (url.includes('/task/calcKondSaldoandmik/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 10425,
              data: { action: 'calcKondSaldoandmik', status: 'STARTED', log_id: 10425 },
            }),
          };
        }
        if (url.includes('/task/calcArvJaak/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 10426,
              data: { action: 'calcArvJaak', status: 'STARTED', log_id: 10426 },
            }),
          };
        }
        if (url.includes('/task/getEarved/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 10429,
              data: { action: 'Import FinBit arved', status: 'STARTED', log_id: 10429 },
            }),
          };
        }
        if (url.includes('/task/readMail/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 10430,
              data: { action: 'readMail', status: 'STARTED', log_id: 10430 },
            }),
          };
        }
        if (url.includes('/task/read_log/')) {
          return { ok: true, status: 200, json: async () => ({ result: 1, data: [] }) };
        }
        throw new Error(`Unexpected url: ${url}`);
      });

      const client = new ApiClient({}, mockFetch as unknown as typeof fetch);
      const tick1 = await runOrchestratorTick(
        { stateFilePath: testStateFile, forceRun: true },
        {
          apiClient: client,
          currentDate: new Date('2026-09-15T20:00:00.000Z'),
          dailyStartHour: 20,
        }
      );

      expect(tick1.action).toBe('TICK_EXECUTED');
      expect(tick1.activeTasks).toContain('saldoandmik');
      expect(tick1.activeTasks).toContain('calc_arv_jaak');
      expect(tick1.activeTasks).toContain('getEarved');
      expect(calledUrls.some((u) => u.includes('/task/calcKondSaldoandmik/'))).toBe(true);
      expect(calledUrls.some((u) => u.includes('/task/calcArvJaak/'))).toBe(true);
      expect(calledUrls.some((u) => u.includes('/task/getEarved/'))).toBe(true);

      // Проверяем, что файл состояния записан на диск
      expect(fs.existsSync(testStateFile)).toBe(true);
      const savedState = JSON.parse(fs.readFileSync(testStateFile, 'utf8'));
      expect(savedState.tasks.saldoandmik.status).toBe('RUNNING');
      expect(savedState.tasks.saldoandmik.log_id).toBe(10425);
      expect(savedState.tasks.calc_arv_jaak.status).toBe('RUNNING');
      expect(savedState.tasks.calc_arv_jaak.log_id).toBe(10426);
      expect(savedState.tasks.getEarved.status).toBe('RUNNING');
      expect(savedState.tasks.getEarved.log_id).toBe(10429);
      expect(savedState.tasks.lisa1_lisa5.status).toBe('PENDING');
    });

    it('Тик 2: инспекция завершения saldoandmik и запуск зависимого lisa1_lisa5', async () => {
      const stateContent = {
        version: 1,
        cycle_date: '2026-09-15',
        status: 'IN_PROGRESS',
        last_tick_at: '2026-09-15T20:00:00.000Z',
        next_scheduled_run: null,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: {
          saldoandmik: {
            flow: TASK_FLOW_SALDOANDMIK,
            depends_on: [],
            allow_parallel: true,
            status: 'RUNNING',
            log_id: 10425,
            started_at: '2026-09-15T20:00:00.000Z',
          },
          calc_arv_jaak: {
            flow: TASK_FLOW_CALC_ARV_JAAK,
            depends_on: [],
            allow_parallel: true,
            status: 'RUNNING',
            log_id: 10426,
            started_at: '2026-09-15T20:00:00.000Z',
          },
          lisa1_lisa5: {
            flow: TASK_FLOW_LISA1_LISA5,
            depends_on: ['saldoandmik'],
            allow_parallel: true,
            status: 'PENDING',
          },
          reporter: {
            flow: 'email_report',
            depends_on: ['saldoandmik', 'calc_arv_jaak', 'lisa1_lisa5'],
            allow_parallel: false,
            status: 'PENDING',
          },
        },
        history: [],
      };
      fs.writeFileSync(testStateFile, JSON.stringify(stateContent));

      const mockFetch = jest.fn().mockImplementation(async (url: string) => {
        // Опрос статуса saldoandmik -> success
        if (url.includes('/task/read_log/') && url.includes('saldoandmik')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              result: 1,
              data: [{ flow: TASK_FLOW_SALDOANDMIK, status: 'success', exec_start: '2026-09-15T20:00:00.000Z' }],
            }),
          };
        }

        // Опрос статуса calc_arv_jaak -> еще выполняется (status: null)
        if (url.includes('/task/read_log/') && url.includes('docs.check_arv_jaak')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              result: 1,
              data: [{ flow: TASK_FLOW_CALC_ARV_JAAK, status: null, exec_start: '2026-09-15T20:00:00.000Z' }],
            }),
          };
        }

        // Старт lisa1_lisa5
        if (url.includes('/task/calcLisa1Lisa5/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 10427,
              data: { action: 'calcLisa1Lisa5', status: 'STARTED', log_id: 10427 },
            }),
          };
        }

        if (url.includes('/task/read_log/')) {
          return { ok: true, status: 200, json: async () => ({ result: 1, data: [] }) };
        }
        throw new Error(`Unexpected url: ${url}`);
      });

      const client = new ApiClient({}, mockFetch as unknown as typeof fetch);
      const tick2 = await runOrchestratorTick(
        { stateFilePath: testStateFile, forceRun: true },
        {
          apiClient: client,
          currentDate: new Date('2026-09-15T20:05:00.000Z'),
          dailyStartHour: 20,
          maxTimeoutMs: 3600000,
        }
      );

      expect(tick2.completedTasks).toContain('saldoandmik');
      expect(tick2.activeTasks).toContain('calc_arv_jaak');
      expect(tick2.activeTasks).toContain('lisa1_lisa5');

      const savedState = JSON.parse(fs.readFileSync(testStateFile, 'utf8'));
      expect(savedState.tasks.saldoandmik.status).toBe('SUCCESS');
      expect(savedState.tasks.lisa1_lisa5.status).toBe('RUNNING');
      expect(savedState.tasks.lisa1_lisa5.log_id).toBe(10427);
    });

    it('Тик 3: завершение всех расчетов, отправка отчета и установка next_scheduled_run на 20:00 завтра', async () => {
      const stateContent = {
        version: 1,
        cycle_date: '2026-09-15',
        status: 'IN_PROGRESS',
        last_tick_at: '2026-09-15T20:05:00.000Z',
        next_scheduled_run: null,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: {
          saldoandmik: {
            flow: TASK_FLOW_SALDOANDMIK,
            depends_on: [],
            allow_parallel: true,
            status: 'SUCCESS',
            log_id: 10425,
          },
          calc_arv_jaak: {
            flow: TASK_FLOW_CALC_ARV_JAAK,
            depends_on: [],
            allow_parallel: true,
            status: 'RUNNING',
            log_id: 10426,
            started_at: '2026-09-15T20:00:00.000Z',
          },
          lisa1_lisa5: {
            flow: TASK_FLOW_LISA1_LISA5,
            depends_on: ['saldoandmik'],
            allow_parallel: true,
            status: 'RUNNING',
            log_id: 10427,
            started_at: '2026-09-15T20:05:00.000Z',
          },
          reporter: {
            flow: 'email_report',
            depends_on: ['saldoandmik', 'calc_arv_jaak', 'lisa1_lisa5'],
            allow_parallel: false,
            status: 'PENDING',
          },
        },
        history: [],
      };
      fs.writeFileSync(testStateFile, JSON.stringify(stateContent));

      const mockFetch = jest.fn().mockImplementation(async (url: string) => {
        if (url.includes('/task/read_log/')) {
          const flow = url.includes('salvesta_lisa_1_5_kontrol')
            ? TASK_FLOW_LISA1_LISA5
            : TASK_FLOW_CALC_ARV_JAAK;
          return {
            ok: true,
            status: 200,
            json: async () => ({
              result: 1,
              data: [
                {
                  flow,
                  status: 'success',
                  exec_start: '2026-09-15T20:00:00.000Z',
                  exec_end: '2026-09-15T20:10:00.000Z',
                },
              ],
            }),
          };
        }
        throw new Error(`Unexpected url: ${url}`);
      });

      const client = new ApiClient({}, mockFetch as unknown as typeof fetch);
      const tick3 = await runOrchestratorTick(
        { stateFilePath: testStateFile, forceRun: true },
        {
          apiClient: client,
          currentDate: new Date('2026-09-15T20:15:00.000Z'),
          dailyStartHour: 20,
          maxTimeoutMs: 3600000,
        }
      );

      expect(tick3.cycleStatus).toBe('COMPLETED');
      expect(tick3.action).toBe('CYCLE_COMPLETED');
      const expectedNextRun = calculateNextScheduledRun('2026-09-15', 20);
      expect(tick3.nextScheduledRun).toBe(expectedNextRun);

      // Проверяем сохраненный файл состояния
      const savedState = JSON.parse(fs.readFileSync(testStateFile, 'utf8'));
      expect(savedState.status).toBe('COMPLETED');
      expect(savedState.tasks.reporter.status).toBe('SUCCESS');
      expect(savedState.next_scheduled_run).toBe(expectedNextRun);
    });

    it('Тик 4: при статусе COMPLETED до наступления 20:00 следующего дня завершает работу без вызовов API', async () => {
      const stateContent = {
        version: 1,
        cycle_date: '2026-09-15',
        status: 'COMPLETED',
        last_tick_at: '2026-09-15T20:15:00.000Z',
        next_scheduled_run: '2026-09-16T20:00:00.000Z',
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: {
          saldoandmik: { flow: TASK_FLOW_SALDOANDMIK, depends_on: [], status: 'SUCCESS' },
          calc_arv_jaak: { flow: TASK_FLOW_CALC_ARV_JAAK, depends_on: [], status: 'SUCCESS' },
          lisa1_lisa5: { flow: TASK_FLOW_LISA1_LISA5, depends_on: ['saldoandmik'], status: 'SUCCESS' },
          reporter: { flow: 'email_report', depends_on: [], status: 'SUCCESS' },
        },
        history: [],
      };
      fs.writeFileSync(testStateFile, JSON.stringify(stateContent));

      const mockFetch = jest.fn();
      const client = new ApiClient({}, mockFetch as unknown as typeof fetch);

      // Запуск днем 16-го сентября (в 14:00, до 20:00)
      const tick4 = await runOrchestratorTick(
        { stateFilePath: testStateFile },
        {
          apiClient: client,
          currentDate: new Date('2026-09-16T14:00:00.000Z'),
          dailyStartHour: 20,
        }
      );

      expect(tick4.action).toBe('IDLE_WAIT_NEXT_SCHEDULE');
      expect(tick4.cycleStatus).toBe('COMPLETED');
      expect(mockFetch).not.toHaveBeenCalled();
    });

    it('Каскадный пропуск: если предшественник упал с ошибкой, зависимый поток получает статус SKIPPED', async () => {
      const stateContent = {
        version: 1,
        cycle_date: '2026-09-15',
        status: 'IN_PROGRESS',
        last_tick_at: '2026-09-15T20:00:00.000Z',
        next_scheduled_run: null,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: {
          saldoandmik: {
            flow: TASK_FLOW_SALDOANDMIK,
            depends_on: [],
            allow_parallel: true,
            status: 'RUNNING',
            attempts: 3,
            max_attempts: 3,
            log_id: 10425,
            started_at: '2026-09-15T20:00:00.000Z',
          },
          calc_arv_jaak: {
            flow: TASK_FLOW_CALC_ARV_JAAK,
            depends_on: [],
            allow_parallel: true,
            status: 'SUCCESS',
            log_id: 10426,
          },
          lisa1_lisa5: {
            flow: TASK_FLOW_LISA1_LISA5,
            depends_on: ['saldoandmik'],
            allow_parallel: true,
            status: 'PENDING',
          },
          reporter: {
            flow: 'email_report',
            depends_on: ['saldoandmik', 'calc_arv_jaak', 'lisa1_lisa5'],
            allow_parallel: false,
            status: 'PENDING',
          },
        },
        history: [],
      };
      fs.writeFileSync(testStateFile, JSON.stringify(stateContent));

      const mockFetch = jest.fn().mockImplementation(async (url: string) => {
        // Опрос лога saldoandmik возвращает failed
        if (url.includes('/task/read_log/') && url.includes('saldoandmik')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              result: 1,
              error_message: 'Calculation fatal SQL error',
              data: [{ flow: TASK_FLOW_SALDOANDMIK, status: 'failed', exec_start: '2026-09-15T20:00:00.000Z' }],
            }),
          };
        }
        throw new Error(`Unexpected url: ${url}`);
      });

      const client = new ApiClient({}, mockFetch as unknown as typeof fetch);
      const tick = await runOrchestratorTick(
        { stateFilePath: testStateFile, forceRun: true },
        {
          apiClient: client,
          currentDate: new Date('2026-09-15T20:05:00.000Z'),
          dailyStartHour: 20,
        }
      );

      expect(tick.failedTasks).toContain('saldoandmik');
      expect(tick.skippedTasks).toContain('lisa1_lisa5');

      const savedState = JSON.parse(fs.readFileSync(testStateFile, 'utf8'));
      expect(savedState.tasks.saldoandmik.status).toBe('FAILED');
      expect(savedState.tasks.lisa1_lisa5.status).toBe('SKIPPED');
    });

    it('Повторный запуск (Retry): должен перезапустить задачу, если в логах нет даты/времени старта (exec_start отсутствует)', async () => {
      const stateContent = {
        version: 1,
        cycle_date: '2026-09-15',
        status: 'IN_PROGRESS',
        last_tick_at: '2026-09-15T20:00:00.000Z',
        next_scheduled_run: null,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: {
          saldoandmik: {
            flow: TASK_FLOW_SALDOANDMIK,
            depends_on: [],
            allow_parallel: true,
            status: 'RUNNING',
            attempts: 1,
            max_attempts: 3,
            log_id: 10425,
            started_at: '2026-09-15T20:00:00.000Z',
          },
          calc_arv_jaak: {
            flow: TASK_FLOW_CALC_ARV_JAAK,
            depends_on: [],
            allow_parallel: true,
            status: 'SUCCESS',
            log_id: 10426,
          },
          lisa1_lisa5: {
            flow: TASK_FLOW_LISA1_LISA5,
            depends_on: ['saldoandmik'],
            allow_parallel: true,
            status: 'PENDING',
          },
          reporter: {
            flow: 'email_report',
            depends_on: ['saldoandmik', 'calc_arv_jaak', 'lisa1_lisa5'],
            allow_parallel: false,
            status: 'PENDING',
          },
        },
        history: [],
      };
      fs.writeFileSync(testStateFile, JSON.stringify(stateContent));

      const mockFetch = jest.fn().mockImplementation(async (url: string) => {
        // Опрос логов возвращает пустую запись без exec_start
        if (url.includes('/task/read_log/') && url.includes('saldoandmik')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              result: 1,
              data: [{ flow: TASK_FLOW_SALDOANDMIK, status: null, exec_start: null }],
            }),
          };
        }
        // Повторный запуск сальдо
        if (url.includes('/task/calcKondSaldoandmik/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 10499,
              data: { action: 'calcKondSaldoandmik', status: 'STARTED', log_id: 10499 },
            }),
          };
        }
        throw new Error(`Unexpected url: ${url}`);
      });

      const client = new ApiClient({}, mockFetch as unknown as typeof fetch);
      const tick = await runOrchestratorTick(
        { stateFilePath: testStateFile, forceRun: true },
        {
          apiClient: client,
          currentDate: new Date('2026-09-15T20:15:00.000Z'),
          dailyStartHour: 20,
        }
      );

      expect(tick.activeTasks).toContain('saldoandmik');

      const savedState = JSON.parse(fs.readFileSync(testStateFile, 'utf8'));
      expect(savedState.tasks.saldoandmik.status).toBe('RUNNING');
      expect(savedState.tasks.saldoandmik.attempts).toBe(2);
      expect(savedState.tasks.saldoandmik.log_id).toBe(10499);

      const retryEvent = savedState.history.find((e: { event: string }) => e.event === 'TASK_RETRY');
      expect(retryEvent).toBeDefined();
      expect(retryEvent.details).toContain('attempt: 2/3');
    });

    it('Повторный запуск (Retry): должен перезапустить задачу при status: failed, пока attempts < 3', async () => {
      const stateContent = {
        version: 1,
        cycle_date: '2026-09-15',
        status: 'IN_PROGRESS',
        last_tick_at: '2026-09-15T20:00:00.000Z',
        next_scheduled_run: null,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: {
          calc_arv_jaak: {
            flow: TASK_FLOW_CALC_ARV_JAAK,
            depends_on: [],
            allow_parallel: true,
            status: 'RUNNING',
            attempts: 1,
            max_attempts: 3,
            log_id: 10426,
            started_at: '2026-09-15T20:00:00.000Z',
          },
          saldoandmik: {
            flow: TASK_FLOW_SALDOANDMIK,
            depends_on: [],
            allow_parallel: true,
            status: 'SUCCESS',
            log_id: 10425,
          },
          lisa1_lisa5: {
            flow: TASK_FLOW_LISA1_LISA5,
            depends_on: ['saldoandmik'],
            allow_parallel: true,
            status: 'PENDING',
          },
          reporter: {
            flow: 'email_report',
            depends_on: ['saldoandmik', 'calc_arv_jaak', 'lisa1_lisa5'],
            allow_parallel: false,
            status: 'PENDING',
          },
        },
        history: [],
      };
      fs.writeFileSync(testStateFile, JSON.stringify(stateContent));

      const mockFetch = jest.fn().mockImplementation(async (url: string) => {
        if (url.includes('/task/read_log/') && url.includes('docs.check_arv_jaak')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              result: 1,
              error_message: 'Temporary DB lock timeout',
              data: [{ flow: TASK_FLOW_CALC_ARV_JAAK, status: 'failed', exec_start: '2026-09-15T20:00:00.000Z' }],
            }),
          };
        }
        if (url.includes('/task/calcArvJaak/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 10500,
              data: { action: 'calcArvJaak', status: 'STARTED', log_id: 10500 },
            }),
          };
        }
        throw new Error(`Unexpected url: ${url}`);
      });

      const client = new ApiClient({}, mockFetch as unknown as typeof fetch);
      const tick = await runOrchestratorTick(
        { stateFilePath: testStateFile, forceRun: true },
        {
          apiClient: client,
          currentDate: new Date('2026-09-15T20:05:00.000Z'),
          dailyStartHour: 20,
        }
      );

      expect(tick.activeTasks).toContain('calc_arv_jaak');

      const savedState = JSON.parse(fs.readFileSync(testStateFile, 'utf8'));
      expect(savedState.tasks.calc_arv_jaak.status).toBe('RUNNING');
      expect(savedState.tasks.calc_arv_jaak.attempts).toBe(2);
      expect(savedState.tasks.calc_arv_jaak.log_id).toBe(10500);
    });

    it('Отсутствие таймаута: задача, выполняющаяся более 4 часов, не прерывается по таймауту и остается в RUNNING', async () => {
      const stateContent = {
        version: 1,
        cycle_date: '2026-09-15',
        status: 'IN_PROGRESS',
        last_tick_at: '2026-09-15T20:00:00.000Z',
        next_scheduled_run: null,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: {
          saldoandmik: {
            flow: TASK_FLOW_SALDOANDMIK,
            depends_on: [],
            allow_parallel: true,
            status: 'RUNNING',
            attempts: 1,
            max_attempts: 3,
            log_id: 10425,
            started_at: '2026-09-15T20:00:00.000Z', // Запущен 8 часов назад
          },
          calc_arv_jaak: {
            flow: TASK_FLOW_CALC_ARV_JAAK,
            depends_on: [],
            allow_parallel: true,
            status: 'SUCCESS',
            log_id: 10426,
          },
          lisa1_lisa5: {
            flow: TASK_FLOW_LISA1_LISA5,
            depends_on: ['saldoandmik'],
            allow_parallel: true,
            status: 'PENDING',
          },
          reporter: {
            flow: 'email_report',
            depends_on: ['saldoandmik', 'calc_arv_jaak', 'lisa1_lisa5'],
            allow_parallel: false,
            status: 'PENDING',
          },
        },
        history: [],
      };
      fs.writeFileSync(testStateFile, JSON.stringify(stateContent));

      const mockFetch = jest.fn().mockImplementation(async (url: string) => {
        // Лог возвращает статус in progress с валидным exec_start
        if (url.includes('/task/read_log/') && url.includes('saldoandmik')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              result: 1,
              data: [{ flow: TASK_FLOW_SALDOANDMIK, status: null, exec_start: '2026-09-15T20:00:00.000Z' }],
            }),
          };
        }
        throw new Error(`Unexpected url: ${url}`);
      });

      const client = new ApiClient({}, mockFetch as unknown as typeof fetch);
      // Текущее время — спустя 8 часов (04:00 следующего утра)
      const tick = await runOrchestratorTick(
        { stateFilePath: testStateFile, forceRun: true },
        {
          apiClient: client,
          currentDate: new Date('2026-09-16T04:00:00.000Z'),
          dailyStartHour: 20,
        }
      );

      // Задача не должна быть сброшена в FAILED по таймауту
      expect(tick.activeTasks).toContain('saldoandmik');
      expect(tick.failedTasks).not.toContain('saldoandmik');

      const savedState = JSON.parse(fs.readFileSync(testStateFile, 'utf8'));
      expect(savedState.tasks.saldoandmik.status).toBe('RUNNING');
      expect(savedState.tasks.saldoandmik.error).toBeNull();
    });
  });

  describe('Time & Date Scheduler (isTaskScheduleReady и запуск по расписанию)', () => {
    it('isTaskScheduleReady должен возвращать ready: true, если schedule не задан', () => {
      const now = new Date('2026-09-15T20:00:00');
      expect(isTaskScheduleReady(null, now)).toEqual({ ready: true, shouldSkip: false });
      expect(isTaskScheduleReady(undefined, now)).toEqual({ ready: true, shouldSkip: false });
      expect(isTaskScheduleReady({}, now)).toEqual({ ready: true, shouldSkip: false });
    });

    it('isTaskScheduleReady должен проверять время запуска (schedule.time)', () => {
      // 08:30
      const sched = { time: '08:30' };

      // До наступления времени (08:15)
      const beforeTime = new Date('2026-09-15T08:15:00');
      const resBefore = isTaskScheduleReady(sched, beforeTime);
      expect(resBefore.ready).toBe(false);
      expect(resBefore.shouldSkip).toBe(false);
      expect(resBefore.reason).toContain('Ootel kuni 08:30');

      // В момент наступления времени (08:30)
      const exactTime = new Date('2026-09-15T08:30:00');
      const resExact = isTaskScheduleReady(sched, exactTime);
      expect(resExact.ready).toBe(true);
      expect(resExact.shouldSkip).toBe(false);

      // Сразу после наступления времени (08:35)
      const afterTime = new Date('2026-09-15T08:35:00');
      const resAfter = isTaskScheduleReady(sched, afterTime);
      expect(resAfter.ready).toBe(true);
      expect(resAfter.shouldSkip).toBe(false);
    });

    it('isTaskScheduleReady должен пропускать задачу (shouldSkip), если день или месяц не совпадают', () => {
      const date15Sept = new Date('2026-09-15T20:00:00'); // 15 сентября

      // Другой день месяца (1-е число)
      const resWrongDay = isTaskScheduleReady({ day: 1 }, date15Sept);
      expect(resWrongDay.ready).toBe(false);
      expect(resWrongDay.shouldSkip).toBe(true);
      expect(resWrongDay.reason).toContain('Käivitamine on kavandatud kuupäevale 1');

      // Тот же день месяца (15-е число)
      const resRightDay = isTaskScheduleReady({ day: 15 }, date15Sept);
      expect(resRightDay.ready).toBe(true);
      expect(resRightDay.shouldSkip).toBe(false);

      // Другой месяц (октябрь, 10)
      const resWrongMonth = isTaskScheduleReady({ month: 10 }, date15Sept);
      expect(resWrongMonth.ready).toBe(false);
      expect(resWrongMonth.shouldSkip).toBe(true);
      expect(resWrongMonth.reason).toContain('Käivitamine on kavandatud kuule 10');

      // Тот же месяц (сентябрь, 9)
      const resRightMonth = isTaskScheduleReady({ month: 9 }, date15Sept);
      expect(resRightMonth.ready).toBe(true);
      expect(resRightMonth.shouldSkip).toBe(false);
    });

    it('runOrchestratorTick: задача с будущим временем schedule.time ожидает в PENDING, а при наступлении времени стартует', async () => {
      const stateContent = {
        version: 1,
        cycle_date: '2026-09-15',
        status: 'IN_PROGRESS',
        last_tick_at: '2026-09-15T20:00:00.000Z',
        next_scheduled_run: null,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: {
          getEarved: {
            flow: TASK_FLOW_GET_EARVED,
            depends_on: [],
            allow_parallel: true,
            schedule: { time: '22:00' },
            status: 'PENDING',
          },
        },
        history: [],
      };
      fs.writeFileSync(testStateFile, JSON.stringify(stateContent));

      const mockFetch = jest.fn().mockImplementation(async (url: string) => {
        if (url.includes('/task/getEarved/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 8888,
              data: { action: 'Import FinBit arved', status: 'STARTED', log_id: 8888 },
            }),
          };
        }
        if (url.includes('/task/read_log/')) {
          return { ok: true, status: 200, json: async () => ({ result: 1, data: [] }) };
        }
        throw new Error(`Unexpected url: ${url}`);
      });

      const client = new ApiClient({}, mockFetch as unknown as typeof fetch);

      // Тик в 20:00 (до наступления 22:00)
      const tickBefore = await runOrchestratorTick(
        { stateFilePath: testStateFile, forceRun: true },
        {
          apiClient: client,
          currentDate: new Date('2026-09-15T20:00:00'),
        }
      );

      // getEarved не должен стартовать, остается PENDING
      expect(tickBefore.pendingTasks).toContain('getEarved');
      expect(tickBefore.activeTasks).not.toContain('getEarved');
      expect(mockFetch).not.toHaveBeenCalled();

      // Тик в 22:05 (сразу после наступления 22:00)
      const tickAfter = await runOrchestratorTick(
        { stateFilePath: testStateFile, forceRun: true },
        {
          apiClient: client,
          currentDate: new Date('2026-09-15T22:05:00'),
        }
      );

      // getEarved должен запуститься и стать RUNNING
      expect(tickAfter.activeTasks).toContain('getEarved');
      expect(mockFetch).toHaveBeenCalledWith(
        expect.stringContaining('/task/getEarved/'),
        expect.anything()
      );

      const saved = JSON.parse(fs.readFileSync(testStateFile, 'utf8'));
      expect(saved.tasks.getEarved.status).toBe('RUNNING');
      expect(saved.tasks.getEarved.log_id).toBe(8888);
    });

    it('runOrchestratorTick: задача с несоответствующим днем месяца помечается SKIPPED', async () => {
      const stateContent = {
        version: 1,
        cycle_date: '2026-09-15',
        status: 'IN_PROGRESS',
        last_tick_at: '2026-09-15T20:00:00.000Z',
        next_scheduled_run: null,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: {
          getEarved: {
            flow: TASK_FLOW_GET_EARVED,
            depends_on: [],
            allow_parallel: true,
            schedule: { day: 1 }, // Запланировано на 1-е число, а сегодня 15-е
            status: 'PENDING',
          },
        },
        history: [],
      };
      fs.writeFileSync(testStateFile, JSON.stringify(stateContent));

      const mockFetch = jest.fn();
      const client = new ApiClient({}, mockFetch as unknown as typeof fetch);

      const tick = await runOrchestratorTick(
        { stateFilePath: testStateFile, forceRun: true },
        {
          apiClient: client,
          currentDate: new Date('2026-09-15T20:00:00'),
        }
      );

      expect(tick.skippedTasks).toContain('getEarved');
      expect(mockFetch).not.toHaveBeenCalled();

      const saved = JSON.parse(fs.readFileSync(testStateFile, 'utf8'));
      expect(saved.tasks.getEarved.status).toBe('SKIPPED');
      expect(saved.tasks.getEarved.error).toContain('Käivitamine on kavandatud kuupäevale 1');
    });

    it('runOrchestratorTick: по расписанию запускается getEarved, а задачи без расписания ждут 20:00', async () => {
      const defaultGraph = getDefaultTaskGraph();
      expect(defaultGraph.getEarved.schedule).toEqual({ time: '05:00' });

      // Запуск в 12:30 из статуса IDLE
      const mockFetch = jest.fn().mockImplementation(async (url: string) => {
        if (url.includes('/task/getEarved/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 9901,
              data: { action: 'Import FinBit arved', status: 'STARTED', log_id: 9901 },
            }),
          };
        }
        if (url.includes('/task/readMail/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 9902,
              data: { action: 'readMail', status: 'STARTED', log_id: 9902 },
            }),
          };
        }
        if (url.includes('/task/read_log/')) {
          return { ok: true, status: 200, json: async () => ({ result: 1, data: [] }) };
        }
        throw new Error(`Unexpected url called: ${url}`);
      });

      const client = new ApiClient({}, mockFetch as unknown as typeof fetch);

      // Тик в 07:15 утра (после read_mail 06:00 и getEarved 07:00, но до calc_arv_jaak 07:30 и saldoandmik 20:00, forceRun: false)
      const tickAtNoon = await runOrchestratorTick(
        { stateFilePath: testStateFile, forceRun: false },
        {
          apiClient: client,
          currentDate: new Date('2026-09-15T07:15:00'),
          dailyStartHour: 20,
        }
      );

      // getEarved (07:00) и read_mail (06:00) должны стартовать, а saldoandmik и calc_arv_jaak должны остаться в PENDING
      expect(tickAtNoon.activeTasks).toEqual(expect.arrayContaining(['getEarved', 'read_mail']));
      expect(tickAtNoon.pendingTasks).toContain('saldoandmik');
      expect(tickAtNoon.pendingTasks).toContain('calc_arv_jaak');
      const dispatchCalls = mockFetch.mock.calls.filter(
        (c: unknown[]) => !String(c[0]).includes('/task/read_log/')
      );
      expect(dispatchCalls.some((c: unknown[]) => String(c[0]).includes('/task/getEarved/'))).toBe(true);

      const stateAfterNoon = JSON.parse(fs.readFileSync(testStateFile, 'utf8'));
      expect(stateAfterNoon.tasks.getEarved.status).toBe('RUNNING');
      expect(stateAfterNoon.tasks.getEarved.log_id).toBe(9901);
      expect(stateAfterNoon.tasks.saldoandmik.status).toBe('PENDING');
      expect(stateAfterNoon.tasks.calc_arv_jaak.status).toBe('PENDING');
    });

    it('runOrchestratorTick: если статус COMPLETED с прошлого дня, но наступило 12:30 и getEarved не выполнялся, цикл возобновляется и getEarved запускается', async () => {
      const stateContent = {
        version: 1,
        cycle_date: '2026-09-16',
        status: 'COMPLETED',
        next_scheduled_run: '2026-09-17T17:00:00.000Z',
        last_tick_at: '2026-09-16T18:00:00.000Z',
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: {
          saldoandmik: { flow: TASK_FLOW_SALDOANDMIK, depends_on: [], status: 'SUCCESS' },
          calc_arv_jaak: { flow: TASK_FLOW_CALC_ARV_JAAK, depends_on: [], status: 'SUCCESS' },
          getEarved: { flow: TASK_FLOW_GET_EARVED, depends_on: [], schedule: { time: '12:30' }, status: 'SUCCESS' },
          lisa1_lisa5: { flow: TASK_FLOW_LISA1_LISA5, depends_on: ['saldoandmik'], status: 'SUCCESS' },
          reporter: { flow: 'email_report', depends_on: ['saldoandmik', 'calc_arv_jaak', 'getEarved', 'lisa1_lisa5'], status: 'SUCCESS' },
        },
        history: [],
      };
      fs.writeFileSync(testStateFile, JSON.stringify(stateContent));

      const mockFetch = jest.fn().mockImplementation(async (url: string) => {
        if (url.includes('/task/read_log/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({ status: 200, result: 1, data: [] }),
          };
        }
        if (url.includes('/task/getEarved/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 8480100,
              data: { action: 'Import FinBit arved', status: 'STARTED', log_id: 8480100 },
            }),
          };
        }
        if (url.includes('/task/calcArvJaak/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 8480101,
              data: { action: 'calcArvJaak', status: 'STARTED', log_id: 8480101 },
            }),
          };
        }
        if (url.includes('/task/readMail/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 8480102,
              data: { action: 'readMail', status: 'STARTED', log_id: 8480102 },
            }),
          };
        }
        throw new Error(`Unexpected url: ${url}`);
      });

      const client = new ApiClient({}, mockFetch as unknown as typeof fetch);

      const tick = await runOrchestratorTick(
        { stateFilePath: testStateFile, forceRun: false },
        {
          apiClient: client,
          currentDate: new Date('2026-09-17T13:00:00'),
          dailyStartHour: 17,
        }
      );

      expect(tick.activeTasks).toContain('getEarved');
      expect(tick.cycleDate).toBe('2026-09-17');
      expect(tick.cycleStatus).toBe('IN_PROGRESS');

      const saved = JSON.parse(fs.readFileSync(testStateFile, 'utf8'));
      expect(saved.cycle_date).toBe('2026-09-17');
      expect(saved.tasks.getEarved.status).toBe('RUNNING');
      expect(saved.tasks.getEarved.log_id).toBe(8480100);
      expect(saved.tasks.saldoandmik.status).toBe('PENDING');
    });

    it('runOrchestratorTick: если статус COMPLETED, и getEarved уже выполнился сегодня после 12:30 согласно ou.logs, статус синхронизируется в SUCCESS и оркестратор ожидает вечернего окна', async () => {
      const stateContent = {
        version: 1,
        cycle_date: '2026-09-16',
        status: 'COMPLETED',
        next_scheduled_run: '2026-09-17T17:00:00.000Z',
        last_tick_at: '2026-09-16T18:00:00.000Z',
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: {
          saldoandmik: { flow: TASK_FLOW_SALDOANDMIK, depends_on: [], status: 'SUCCESS' },
          calc_arv_jaak: { flow: TASK_FLOW_CALC_ARV_JAAK, depends_on: [], status: 'SUCCESS' },
          getEarved: { flow: TASK_FLOW_GET_EARVED, depends_on: [], schedule: { time: '12:30' }, status: 'PENDING' },
          lisa1_lisa5: { flow: TASK_FLOW_LISA1_LISA5, depends_on: ['saldoandmik'], status: 'SUCCESS' },
          reporter: { flow: 'email_report', depends_on: ['saldoandmik', 'calc_arv_jaak', 'getEarved', 'lisa1_lisa5'], status: 'SUCCESS' },
        },
        history: [],
      };
      fs.writeFileSync(testStateFile, JSON.stringify(stateContent));

      const mockFetch = jest.fn().mockImplementation(async (url: string) => {
        if (url.includes('/task/read_log/11770/getEarved')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              data: [
                {
                  id: 8480055,
                  flow: TASK_FLOW_GET_EARVED,
                  status: 'success',
                  exec_start: '2026-09-17 12:35:00',
                  exec_end: '2026-09-17 12:36:15',
                },
              ],
            }),
          };
        }
        throw new Error(`Unexpected url: ${url}`);
      });

      const client = new ApiClient({}, mockFetch as unknown as typeof fetch);

      const tick = await runOrchestratorTick(
        { stateFilePath: testStateFile, forceRun: false },
        {
          apiClient: client,
          currentDate: new Date('2026-09-17T13:00:00'),
          dailyStartHour: 17,
        }
      );

      expect(tick.activeTasks).not.toContain('getEarved');
      expect(mockFetch).toHaveBeenCalledWith(
        expect.stringContaining('/task/read_log/11770/getEarved'),
        expect.anything()
      );

      const saved = JSON.parse(fs.readFileSync(testStateFile, 'utf8'));
      expect(saved.cycle_date).toBe('2026-09-17');
      expect(saved.tasks.getEarved.status).toBe('SUCCESS');
      expect(saved.tasks.getEarved.log_id).toBe(8480055);
    });

    it('runOrchestratorTick: если в ou.logs есть запуск getEarved ДО 12:30 (например, в 08:00), он не засчитывается и getEarved запускается в 12:30', async () => {
      const stateContent = {
        version: 1,
        cycle_date: '2026-09-17',
        status: 'COMPLETED',
        next_scheduled_run: '2026-09-17T17:00:00.000Z',
        last_tick_at: '2026-09-17T08:15:00.000Z',
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: {
          saldoandmik: { flow: TASK_FLOW_SALDOANDMIK, depends_on: [], status: 'SUCCESS' },
          calc_arv_jaak: { flow: TASK_FLOW_CALC_ARV_JAAK, depends_on: [], status: 'SUCCESS' },
          getEarved: { flow: TASK_FLOW_GET_EARVED, depends_on: [], schedule: { time: '12:30' }, status: 'PENDING' },
          lisa1_lisa5: { flow: TASK_FLOW_LISA1_LISA5, depends_on: ['saldoandmik'], status: 'SUCCESS' },
          reporter: { flow: 'email_report', depends_on: ['saldoandmik', 'calc_arv_jaak', 'getEarved', 'lisa1_lisa5'], status: 'SUCCESS' },
        },
        history: [],
      };
      fs.writeFileSync(testStateFile, JSON.stringify(stateContent));

      const mockFetch = jest.fn().mockImplementation(async (url: string) => {
        if (url.includes('/task/read_log/11770/getEarved')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              data: [
                {
                  id: 8480010,
                  flow: TASK_FLOW_GET_EARVED,
                  status: 'success',
                  exec_start: '2026-09-17 08:00:00',
                  exec_end: '2026-09-17 08:01:00',
                },
              ],
            }),
          };
        }
        if (url.includes('/task/getEarved/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 8480200,
              data: { action: 'Import FinBit arved', status: 'STARTED', log_id: 8480200 },
            }),
          };
        }
        throw new Error(`Unexpected url: ${url}`);
      });

      const client = new ApiClient({}, mockFetch as unknown as typeof fetch);

      const tick = await runOrchestratorTick(
        { stateFilePath: testStateFile, forceRun: false },
        {
          apiClient: client,
          currentDate: new Date('2026-09-17T12:30:00'),
          dailyStartHour: 17,
        }
      );

      expect(tick.activeTasks).toContain('getEarved');
      const saved = JSON.parse(fs.readFileSync(testStateFile, 'utf8'));
      expect(saved.tasks.getEarved.status).toBe('RUNNING');
      expect(saved.tasks.getEarved.log_id).toBe(8480200);
    });
  });

  describe('Динамическая конфигурация (<agent>/config.json) и гибридное AI-принятие решений', () => {
    it('loadAllAgentConfigs должен успешно загружать конфигурации всех 6 агентов из файловой системы', () => {
      const configs = loadAllAgentConfigs();
      expect(Object.keys(configs)).toEqual(
        expect.arrayContaining(['saldoandmik', 'calc_arv_jaak', 'getEarved', 'sendFinBitReport', 'lisa1_lisa5', 'reporter'])
      );

      // Проверка структуры конкретных агентов
      expect(configs.getEarved.schedule).toEqual({ time: '05:00' });
      expect(configs.getEarved.flow).toBe('getEarved');
      expect(configs.getEarved.params).toMatchObject({ is_agent: true });

      expect(configs.calc_arv_jaak.flow).toBe('docs.check_arv_jaak');
      expect(configs.calc_arv_jaak.schedule).toEqual({ time: '07:30' });

      expect(configs.sendFinBitReport.flow).toBe('sendFinBitReport');
      expect(configs.sendFinBitReport.depends_on).toEqual(['import_earved']);

      expect(configs.lisa1_lisa5.depends_on).toEqual(['saldoandmik']);
      expect(configs.reporter.allow_parallel).toBe(false);
      expect(configs.reporter.depends_on).toEqual(['sendFinBitReport', 'calc_arv_jaak', 'read_mail']);
      expect(configs.reporter.max_wait_time).toBe('09:00');
      expect(configs.reporter.schedule).toEqual({ time: '08:00' });
    });

    it('getDefaultTaskGraph должен формировать валидный граф задач на базе config.json', () => {
      const graph = getDefaultTaskGraph();
      expect(graph.saldoandmik.status).toBe('PENDING');
      expect(graph.getEarved.schedule).toEqual({ time: '05:00' });
      expect(graph.sendFinBitReport.status).toBe('PENDING');
      expect(graph.sendFinBitReport.depends_on).toEqual(['import_earved']);
      expect(graph.reporter.depends_on).toEqual(['sendFinBitReport', 'calc_arv_jaak', 'read_mail']);
      expect(graph.reporter.max_wait_time).toBe('09:00');
      expect(graph.reporter.schedule).toEqual({ time: '08:00' });
    });

    it('reconcileTasksWithConfigs должен обновлять декларативные поля, сохраняя runtime-состояние задачи', () => {
      const existingTasks = {
        getEarved: {
          flow: 'getEarved',
          depends_on: [],
          allow_parallel: true,
          schedule: { time: '10:00' }, // Устаревшее расписание в файле состояния
          prompt: null,
          params: { customRuntimeFlag: true },
          status: 'RUNNING' as const,
          attempts: 2,
          max_attempts: 3,
          log_id: 998877,
          started_at: '2026-09-18T10:00:00.000Z',
          finished_at: null,
          duration_ms: null,
          error: null,
        },
      };

      const configs = {
        getEarved: {
          name: 'getEarved',
          flow: 'getEarved_updated',
          allow_parallel: true,
          depends_on: [],
          schedule: { time: '12:30' },
          prompt: 'Execute after 12:30',
          max_attempts: 5,
          params: { defaultParam: 123 },
        },
      };

      reconcileTasksWithConfigs(existingTasks, configs, true);

      // Декларативные поля обновлены из config.json
      expect(existingTasks.getEarved.flow).toBe('getEarved_updated');
      expect(existingTasks.getEarved.schedule).toEqual({ time: '12:30' });
      expect(existingTasks.getEarved.prompt).toBe('Execute after 12:30');
      expect(existingTasks.getEarved.max_attempts).toBe(5);
      expect(existingTasks.getEarved.params).toEqual({
        defaultParam: 123,
        customRuntimeFlag: true,
        userId: 11770,
        rekvId: 63,
      });

      // Рантайм-поля сохранены
      expect(existingTasks.getEarved.status).toBe('RUNNING');
      expect(existingTasks.getEarved.attempts).toBe(2);
      expect(existingTasks.getEarved.log_id).toBe(998877);
      expect(existingTasks.getEarved.started_at).toBe('2026-09-18T10:00:00.000Z');
    });

    it('evaluateTaskLaunchDecision с prompt вызывает aiGenerateFn и возвращает structured output с dynamic_params', async () => {
      const taskState: TaskState = {
        flow: 'getEarved',
        depends_on: [],
        allow_parallel: true,
        schedule: { time: '12:30' },
        prompt: 'Если сегодня пятница, передать dateQueryFrom за последние 3 дня',
        params: { userId: 2477, rekvId: 63 },
        status: 'PENDING',
        attempts: 0,
        max_attempts: 3,
        log_id: null,
        started_at: null,
        finished_at: null,
        duration_ms: null,
        error: null,
      };

      const state: OrchestratorState = {
        version: 1,
        cycle_date: '2026-09-18',
        status: 'IN_PROGRESS',
        last_tick_at: null,
        next_scheduled_run: null,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: { getEarved: taskState },
        history: [],
      };

      const mockAiGenerateFn = jest.fn().mockResolvedValue({
        should_run: true,
        action: 'RUN',
        reason: 'Сегодня пятница, запускаем импорт с расширенным окном дат',
        dynamic_params: { dateQueryFrom: '2026-09-15' },
      });

      const decision = await evaluateTaskLaunchDecision(
        'getEarved',
        taskState,
        state,
        new Date('2026-09-18T12:30:00'),
        20,
        false,
        mockAiGenerateFn
      );

      expect(mockAiGenerateFn).toHaveBeenCalledTimes(1);
      const callArgs = mockAiGenerateFn.mock.calls[0];
      expect(callArgs[0]).toContain('Если сегодня пятница');
      expect(callArgs[1].agentName).toBe('getEarved');

      expect(decision.should_run).toBe(true);
      expect(decision.action).toBe('RUN');
      expect(decision.dynamic_params).toEqual({ dateQueryFrom: '2026-09-15' });
    });

    it('evaluateTaskLaunchDecision с prompt корректно делает fallback на FSM при сбое LLM', async () => {
      const taskState: TaskState = {
        flow: 'getEarved',
        depends_on: [],
        allow_parallel: true,
        schedule: { time: '12:30' },
        prompt: 'Кастомный промпт',
        params: {},
        status: 'PENDING',
        attempts: 0,
        max_attempts: 3,
        log_id: null,
        started_at: null,
        finished_at: null,
        duration_ms: null,
        error: null,
      };

      const state: OrchestratorState = {
        version: 1,
        cycle_date: '2026-09-18',
        status: 'IN_PROGRESS',
        last_tick_at: null,
        next_scheduled_run: null,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: { getEarved: taskState },
        history: [],
      };

      // aiGenerateFn выбрасывает ошибку (например, таймаут или квота Gemini)
      const mockFailingAi = jest.fn().mockRejectedValue(new Error('Quota exceeded'));

      // Время 12:30 наступило -> FSM решает RUN
      const decisionReady = await evaluateTaskLaunchDecision(
        'getEarved',
        taskState,
        state,
        new Date('2026-09-18T12:30:00'),
        20,
        false,
        mockFailingAi
      );
      expect(decisionReady.should_run).toBe(true);
      expect(decisionReady.action).toBe('RUN');

      // Время 11:00 еще не наступило -> FSM решает WAIT
      const decisionWait = await evaluateTaskLaunchDecision(
        'getEarved',
        taskState,
        state,
        new Date('2026-09-18T11:00:00'),
        20,
        false,
        mockFailingAi
      );
      expect(decisionWait.should_run).toBe(false);
      expect(decisionWait.action).toBe('WAIT');
    });

    it('evaluateTaskLaunchDecision без prompt использует детерминированный FSM анализ', async () => {
      const taskState: TaskState = {
        flow: 'eelarve.salvesta_lisa_1_5_kontrol',
        depends_on: ['saldoandmik'],
        allow_parallel: true,
        schedule: null,
        prompt: null,
        params: {},
        status: 'PENDING',
        attempts: 0,
        max_attempts: 3,
        log_id: null,
        started_at: null,
        finished_at: null,
        duration_ms: null,
        error: null,
      };

      const saldoTask: TaskState = {
        flow: 'eelarve.sp_koosta_saldoandmik',
        depends_on: [],
        allow_parallel: true,
        schedule: null,
        prompt: null,
        params: {},
        status: 'PENDING',
        attempts: 0,
        max_attempts: 3,
        log_id: null,
        started_at: null,
        finished_at: null,
        duration_ms: null,
        error: null,
      };

      const state: OrchestratorState = {
        version: 1,
        cycle_date: '2026-09-18',
        status: 'IN_PROGRESS',
        last_tick_at: null,
        next_scheduled_run: null,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: {
          saldoandmik: saldoTask,
          lisa1_lisa5: taskState,
        },
        history: [],
      };

      // saldoandmik еще PENDING -> lisa1_lisa5 должна ждать (WAIT)
      const decision1 = await evaluateTaskLaunchDecision(
        'lisa1_lisa5',
        taskState,
        state,
        new Date('2026-09-18T20:00:00'),
        20,
        false
      );
      expect(decision1.should_run).toBe(false);
      expect(decision1.action).toBe('WAIT');

      // saldoandmik стал SUCCESS -> lisa1_lisa5 готова к запуску (RUN)
      state.tasks.saldoandmik.status = 'SUCCESS';
      const decision2 = await evaluateTaskLaunchDecision(
        'lisa1_lisa5',
        taskState,
        state,
        new Date('2026-09-18T20:00:00'),
        20,
        false
      );
      expect(decision2.should_run).toBe(true);
      expect(decision2.action).toBe('RUN');
    });

    it('evaluateTaskLaunchDecision для calc_arv_jaak передает apiBaseUrl и taskStatus в LLM для проверки режима тестирования (localhost)', async () => {
      const calcTask: TaskState = {
        flow: 'docs.check_arv_jaak',
        depends_on: [],
        allow_parallel: true,
        schedule: null,
        prompt: 'Запускать агента на период тестирования каждый раз, когда статус выполнения = success. Режим тестирования определяется адресом апи вызова. Если там фигурирует localhost, то считаем что это режим теста',
        params: { userId: 2477, rekvId: 63 },
        status: 'SUCCESS',
        attempts: 1,
        max_attempts: 3,
        log_id: 1234,
        started_at: '2026-09-18T10:00:00.000Z',
        finished_at: '2026-09-18T10:05:00.000Z',
        duration_ms: 300000,
        error: null,
      };

      const state: OrchestratorState = {
        version: 1,
        cycle_date: '2026-09-18',
        status: 'IN_PROGRESS',
        last_tick_at: null,
        next_scheduled_run: null,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: { calc_arv_jaak: calcTask },
        history: [],
      };

      const localhostClient = new ApiClient({ buh70ApiBaseUrl: 'http://localhost:3000' });
      const mockAiGenerateFn = jest.fn().mockImplementation(async (_promptText: string, context: DecisionContext) => {
        const isLocalhost = context.apiBaseUrl?.includes('localhost');
        const isSuccess = context.taskStatus === 'SUCCESS';
        if (isLocalhost && isSuccess) {
          return {
            should_run: true,
            action: 'RUN',
            reason: 'Режим тестирования (localhost обнаружен в apiBaseUrl) и статус выполнения равен success',
          };
        }
        return {
          should_run: false,
          action: 'WAIT',
          reason: 'Не тестовый режим или задача еще не завершена',
        };
      });

      // 1. Тест с localhost: должен вернуть RUN
      const decisionLocalhost = await evaluateTaskLaunchDecision(
        'calc_arv_jaak',
        calcTask,
        state,
        new Date('2026-09-18T11:00:00'),
        20,
        false,
        mockAiGenerateFn,
        localhostClient
      );

      expect(mockAiGenerateFn).toHaveBeenCalled();
      const contextPassed = mockAiGenerateFn.mock.calls[0][1];
      expect(contextPassed.apiBaseUrl).toBe('http://localhost:3000');
      expect(contextPassed.taskStatus).toBe('SUCCESS');
      expect(decisionLocalhost.should_run).toBe(true);
      expect(decisionLocalhost.action).toBe('RUN');

      // 2. Тест с production URL (не localhost): должен вернуть WAIT
      const prodClient = new ApiClient({ buh70ApiBaseUrl: 'https://buh70.domain.ee' });
      const decisionProd = await evaluateTaskLaunchDecision(
        'calc_arv_jaak',
        calcTask,
        state,
        new Date('2026-09-18T11:00:00'),
        20,
        false,
        mockAiGenerateFn,
        prodClient
      );

      expect(decisionProd.should_run).toBe(false);
      expect(decisionProd.action).toBe('WAIT');
    });
  });

  describe('Субагент sendFinBitReport и Parent Context Forwarding (logId)', () => {
    it('runOrchestratorTick должен передавать logId от завершившегося getEarved в sendFinBitReport при запуске', async () => {
      // Инициализируем файл состояния, где getEarved уже SUCCESS с log_id: 7777, а sendFinBitReport в PENDING
      const initialState: OrchestratorState = {
        version: 1,
        cycle_date: '2026-09-18',
        status: 'IN_PROGRESS',
        last_tick_at: '2026-09-18T12:35:00.000Z',
        next_scheduled_run: null,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: {
          import_earved: {
            flow: 'docs.sp_loe_earved',
            depends_on: [],
            allow_parallel: true,
            schedule: { time: '12:30' },
            prompt: null,
            params: {},
            status: 'SUCCESS',
            attempts: 1,
            max_attempts: 3,
            log_id: 7777,
            started_at: '2026-09-18T12:30:00.000Z',
            finished_at: '2026-09-18T12:31:00.000Z',
            duration_ms: 60000,
            error: null,
          },
          sendFinBitReport: {
            flow: 'sendFinBitReport',
            depends_on: ['import_earved'],
            allow_parallel: true,
            schedule: null,
            prompt: null,
            params: {},
            status: 'PENDING',
            attempts: 0,
            max_attempts: 3,
            log_id: null,
            started_at: null,
            finished_at: null,
            duration_ms: null,
            error: null,
          },
        },
        history: [],
      };
      fs.writeFileSync(testStateFile, JSON.stringify(initialState, null, 2), 'utf8');

      let capturedPayload: Record<string, unknown> = {};
      const mockFetch = jest.fn().mockImplementation(async (url: string, init?: RequestInit) => {
        if (url.includes('/task/sendFinBitReport/')) {
          if (init?.body) {
            capturedPayload = JSON.parse(init.body as string);
          }
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 9999,
              data: { action: 'sendFinBitReport', status: 'STARTED', log_id: 9999 },
              error_message: null,
            }),
          };
        }
        return { ok: true, status: 200, json: async () => ({ result: 1, data: [] }) };
      });

      const client = new ApiClient({}, mockFetch as unknown as typeof fetch);

      const tick = await runOrchestratorTick(
        { stateFilePath: testStateFile },
        {
          apiClient: client,
          currentDate: new Date('2026-09-18T12:35:00'),
          dailyStartHour: 20,
        }
      );

      expect(tick.activeTasks).toContain('sendFinBitReport');
      expect(capturedPayload.logId).toBe(7777);
      expect(capturedPayload.user_id).toBe(11770);
      expect(capturedPayload.rekv_id).toBe(63);

      const saved = JSON.parse(fs.readFileSync(testStateFile, 'utf8'));
      expect(saved.tasks.sendFinBitReport.status).toBe('RUNNING');
      expect(saved.tasks.sendFinBitReport.log_id).toBe(9999);
      expect(saved.tasks.sendFinBitReport.params.logId).toBe(7777);
    });

    it('runOrchestratorTick должен каскадно пропускать sendFinBitReport (SKIPPED), если родитель getEarved упал с ошибкой', async () => {
      const initialState: OrchestratorState = {
        version: 1,
        cycle_date: '2026-09-18',
        status: 'IN_PROGRESS',
        last_tick_at: '2026-09-18T12:35:00.000Z',
        next_scheduled_run: null,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: {
          import_earved: {
            flow: 'docs.sp_loe_earved',
            depends_on: [],
            allow_parallel: true,
            schedule: { time: '12:30' },
            prompt: null,
            params: {},
            status: 'FAILED',
            attempts: 3,
            max_attempts: 3,
            log_id: 7777,
            started_at: '2026-09-18T12:30:00.000Z',
            finished_at: '2026-09-18T12:31:00.000Z',
            duration_ms: 60000,
            error: 'Connection timeout to FinBit',
          },
          sendFinBitReport: {
            flow: 'sendFinBitReport',
            depends_on: ['import_earved'],
            allow_parallel: true,
            schedule: null,
            prompt: null,
            params: {},
            status: 'PENDING',
            attempts: 0,
            max_attempts: 3,
            log_id: null,
            started_at: null,
            finished_at: null,
            duration_ms: null,
            error: null,
          },
        },
        history: [],
      };
      fs.writeFileSync(testStateFile, JSON.stringify(initialState, null, 2), 'utf8');

      const mockFetch = jest.fn();
      const client = new ApiClient({}, mockFetch as unknown as typeof fetch);

      await runOrchestratorTick(
        { stateFilePath: testStateFile },
        {
          apiClient: client,
          currentDate: new Date('2026-09-18T12:35:00'),
          dailyStartHour: 20,
        }
      );

      const saved = JSON.parse(fs.readFileSync(testStateFile, 'utf8'));
      expect(saved.tasks.sendFinBitReport.status).toBe('SKIPPED');
      expect(mockFetch).not.toHaveBeenCalled();
    });

    it('evaluateTaskLaunchDecision должен пропускать (SKIP) sendFinBitReport, если у getEarved отсутствует log_id', async () => {
      const taskState: TaskState = {
        flow: 'sendFinBitReport',
        depends_on: ['import_earved'],
        allow_parallel: true,
        schedule: null,
        prompt: null,
        params: {},
        status: 'PENDING',
        attempts: 0,
        max_attempts: 3,
        log_id: null,
        started_at: null,
        finished_at: null,
        duration_ms: null,
        error: null,
      };

      const getEarvedTask: TaskState = {
        flow: 'docs.sp_loe_earved',
        depends_on: [],
        allow_parallel: true,
        schedule: { time: '12:30' },
        prompt: null,
        params: {},
        status: 'SUCCESS',
        attempts: 1,
        max_attempts: 3,
        log_id: null, // Нет log_id
        started_at: '2026-09-18T12:30:00.000Z',
        finished_at: '2026-09-18T12:31:00.000Z',
        duration_ms: 60000,
        error: null,
      };

      const state: OrchestratorState = {
        version: 1,
        cycle_date: '2026-09-18',
        status: 'IN_PROGRESS',
        last_tick_at: null,
        next_scheduled_run: null,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: {
          import_earved: getEarvedTask,
          sendFinBitReport: taskState,
        },
        history: [],
      };

      const decision = await evaluateTaskLaunchDecision(
        'sendFinBitReport',
        taskState,
        state,
        new Date('2026-09-18T12:35:00'),
        20,
        false
      );

      expect(decision.should_run).toBe(false);
      expect(decision.action).toBe('SKIP');
      expect(decision.reason).toContain('log_id puudub');
    });
  });

  describe('Конфигурация оркестратора (orchestrator/config.json) и Meta-Orchestrator AI решение', () => {
    const mockCycleState: OrchestratorState = {
      version: 1,
      cycle_date: '2026-09-18',
      status: 'IDLE',
      last_tick_at: null,
      next_scheduled_run: null,
      params: { userId: 2477, rekvId: 63, kond: 1 },
      tasks: {},
      history: [],
    };

    it('loadOrchestratorConfig должен успешно загружать orchestrator/config.json', () => {
      const config = loadOrchestratorConfig();
      expect(config.name).toBe('orchestrator');
      expect(config.daily_start_time).toBe('20:00');
      expect(config.timezone).toBe('Europe/Tallinn');
      expect(config.max_task_attempts).toBe(3);
      expect(config.params).toEqual(expect.objectContaining({ userId: 11770, rekvId: 63, kond: 1 }));
      expect(typeof config.prompt).toBe('string');
    });

    it('isDailyExecutionWindowOpen корректно проверяет наступление времени с учетом таймзоны', () => {
      // 10:00 UTC = 13:00 Tallinn (EEST = UTC+3)
      const dayDate = new Date('2026-09-18T10:00:00.000Z');
      expect(isDailyExecutionWindowOpen(dayDate, '20:00', 'Europe/Tallinn')).toBe(false);
      expect(isDailyExecutionWindowOpen(dayDate, '12:00', 'Europe/Tallinn')).toBe(true);

      // 18:00 UTC = 21:00 Tallinn (EEST = UTC+3)
      const eveningDate = new Date('2026-09-18T18:00:00.000Z');
      expect(isDailyExecutionWindowOpen(eveningDate, '20:00', 'Europe/Tallinn')).toBe(true);
    });

    it('evaluateCycleDecision без prompt использует детерминированное окно времени', async () => {
      const orchConfig: OrchestratorConfig = {
        name: 'orchestrator',
        daily_start_time: '20:00',
        timezone: 'Europe/Tallinn',
        max_task_attempts: 3,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        prompt: null,
      };

      const dayDate = new Date('2026-09-18T09:00:00.000Z'); // 12:00 Tallinn
      const decisionDay = await evaluateCycleDecision(orchConfig, mockCycleState, dayDate, false);
      expect(decisionDay.action).toBe('WAIT_SCHEDULE');
      expect(decisionDay.force_run).toBe(false);

      const eveningDate = new Date('2026-09-18T18:00:00.000Z'); // 21:00 Tallinn
      const decisionEvening = await evaluateCycleDecision(orchConfig, mockCycleState, eveningDate, false);
      expect(decisionEvening.action).toBe('RUN_CYCLE');
    });

    it('evaluateCycleDecision с prompt вызывает aiCycleGenerateFn и возвращает решение LLM', async () => {
      const orchConfig: OrchestratorConfig = {
        name: 'orchestrator',
        daily_start_time: '20:00',
        timezone: 'Europe/Tallinn',
        max_task_attempts: 3,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        prompt: 'Если в apiBaseUrl обнаружен localhost, разрешай запуск цикла (force_run=true)',
      };

      const mockAiCycleFn = jest.fn().mockResolvedValue({
        action: 'RUN_CYCLE',
        force_run: true,
        reason: 'Режим тестирования localhost подтвержден, открываем цикл до 20:00',
      });

      const dayDate = new Date('2026-09-18T09:00:00.000Z');
      const decision = await evaluateCycleDecision(
        orchConfig,
        mockCycleState,
        dayDate,
        false,
        undefined,
        mockAiCycleFn
      );

      expect(mockAiCycleFn).toHaveBeenCalledTimes(1);
      const callArgs = mockAiCycleFn.mock.calls[0];
      expect(callArgs[0]).toContain('Если в apiBaseUrl обнаружен localhost');
      expect(callArgs[1].dailyStartTime).toBe('20:00');
      expect(callArgs[1].isTestMode).toBe(true);

      expect(decision.action).toBe('RUN_CYCLE');
      expect(decision.force_run).toBe(true);
      expect(decision.reason).toContain('Режим тестирования localhost');
    });

    it('evaluateCycleDecision с prompt при ошибке LLM корректно делает fallback на стандартные правила', async () => {
      const orchConfig: OrchestratorConfig = {
        name: 'orchestrator',
        daily_start_time: '20:00',
        timezone: 'Europe/Tallinn',
        max_task_attempts: 3,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        prompt: 'Промпт, приводящий к ошибке',
      };

      const mockFailingAiFn = jest.fn().mockRejectedValue(new Error('Network error calling Gemini API'));
      const dayDate = new Date('2026-09-18T09:00:00.000Z');

      const decision = await evaluateCycleDecision(
        orchConfig,
        mockCycleState,
        dayDate,
        false,
        undefined,
        mockFailingAiFn
      );

      expect(decision.action).toBe('WAIT_SCHEDULE');
      expect(decision.force_run).toBe(false);
    });

    it('parseTaskFlag: --task без значения или со следующим флагом вместо значения — ошибка использования', () => {
      // Флаг не задан — ни ключа, ни ошибки
      expect(parseTaskFlag(['--force'])).toEqual({});
      // Корректное значение
      expect(parseTaskFlag(['--task', 'getEarved', '--force'])).toEqual({ taskKey: 'getEarved' });

      // Значение отсутствует
      const missing = parseTaskFlag(['--force', '--task']);
      expect(missing.taskKey).toBeUndefined();
      expect(missing.error).toContain('--task');

      // Вместо значения идёт следующий флаг — он не должен приниматься за ключ задачи
      const nextFlag = parseTaskFlag(['--task', '--force']);
      expect(nextFlag.taskKey).toBeUndefined();
      expect(nextFlag.error).toContain('--force');
    });

    it('resolveModelName нормализует имя модели для Genkit', () => {
      expect(resolveModelName('gemini-1.5-flash')).toBe('googleai/gemini-1.5-flash');
      expect(resolveModelName('googleai/gemini-2.0-flash')).toBe('googleai/gemini-2.0-flash');
      expect(resolveModelName('gemini-2.5-flash')).toBe('googleai/gemini-2.5-flash');
      expect(resolveModelName()).toBe('googleai/gemini-1.5-flash');
    });

    it('getConfig считывает geminiModel из process.env', () => {
      const oldModel = process.env.GEMINI_MODEL;
      try {
        process.env.GEMINI_MODEL = 'gemini-2.0-flash-exp';
        const cfg = getConfig();
        expect(cfg.geminiModel).toBe('gemini-2.0-flash-exp');
      } finally {
        if (oldModel !== undefined) {
          process.env.GEMINI_MODEL = oldModel;
        } else {
          delete process.env.GEMINI_MODEL;
        }
      }
    });
  });

  describe('Контроль результатов выполнения задач (ou.logs) и семантическая оценка через LLM', () => {
    const mockTask: TaskState = {
      flow: 'sendFinBitReport',
      depends_on: ['import_earved'],
      allow_parallel: true,
      schedule: null,
      prompt: 'Проверяй массив result на ошибки ETIMEDOUT',
      params: { userId: 2477, rekvId: 63, logId: 10429 },
      status: 'RUNNING',
      attempts: 1,
      max_attempts: 3,
      log_id: 10430,
      started_at: '2026-09-18T12:12:40.000Z',
      finished_at: null,
      duration_ms: null,
      error: null,
    };

    const failedLogResult = {
      status: 'failed' as const,
      rawStatus: 'success',
      execStart: '2026-09-18T12:12:40.000Z',
      execEnd: '2026-09-18T12:16:00.000Z',
      durationMs: 200000,
      error: 'vladislav.gordin@gmail.com: connect ETIMEDOUT 213.184.47.202:25',
      hasErrors: true,
      errorDetails: 'vladislav.gordin@gmail.com: connect ETIMEDOUT 213.184.47.202:25',
      resultSummary: 'Kokku: 1, õnnestus: 0, vigu: 1 (vladislav.gordin@gmail.com: connect ETIMEDOUT 213.184.47.202:25)',
      result: [
        {
          email: 'vladislav.gordin@gmail.com',
          error: 'connect ETIMEDOUT 213.184.47.202:25',
          success: false,
        },
      ],
    };

    it('evaluateTaskResultDecision с prompt вызывает aiTaskResultGenerateFn и возвращает решение модели', async () => {
      const mockAiFn = jest.fn().mockResolvedValue({
        is_success: false,
        status: 'FAILED',
        summary: 'Kokku: 1, õnnestus: 0, vigu: 1',
        error: 'vladislav.gordin@gmail.com: connect ETIMEDOUT 213.184.47.202:25',
      });

      const decision = await evaluateTaskResultDecision(
        'sendFinBitReport',
        mockTask,
        failedLogResult,
        new Date('2026-09-18T12:16:01.000Z'),
        mockAiFn
      );

      expect(mockAiFn).toHaveBeenCalledTimes(1);
      const passedContext = mockAiFn.mock.calls[0][1] as TaskResultContext;
      expect(passedContext.agentName).toBe('sendFinBitReport');
      expect(passedContext.hasErrors).toBe(true);
      expect(passedContext.errorDetails).toContain('connect ETIMEDOUT');
      expect(decision.status).toBe('FAILED');
      expect(decision.is_success).toBe(false);
      expect(decision.error).toContain('connect ETIMEDOUT');
    });

    it('evaluateTaskResultDecision с prompt при ошибке LLM делает корректный fallback на детерминированный анализ', async () => {
      const mockFailingAiFn = jest.fn().mockRejectedValue(new Error('LLM rate limit'));

      const decision = await evaluateTaskResultDecision(
        'sendFinBitReport',
        mockTask,
        failedLogResult,
        new Date('2026-09-18T12:16:01.000Z'),
        mockFailingAiFn
      );

      expect(decision.status).toBe('FAILED');
      expect(decision.is_success).toBe(false);
      expect(decision.error).toContain('connect ETIMEDOUT');
    });

    it('evaluateTaskResultDecision без prompt детерминированно фиксирует FAILED при наличии hasErrors', async () => {
      const taskWithoutPrompt = { ...mockTask, prompt: null };

      const decision = await evaluateTaskResultDecision(
        'sendFinBitReport',
        taskWithoutPrompt,
        failedLogResult,
        new Date('2026-09-18T12:16:01.000Z')
      );

      expect(decision.status).toBe('FAILED');
      expect(decision.is_success).toBe(false);
      expect(decision.error).toContain('connect ETIMEDOUT');
    });

    it('evaluateTaskResultDecision без prompt возвращает SUCCESS, если в result ошибок нет', async () => {
      const taskWithoutPrompt = { ...mockTask, prompt: null };
      const successLogResult = {
        status: 'success' as const,
        rawStatus: 'success',
        execStart: '2026-09-18T12:12:40.000Z',
        execEnd: '2026-09-18T12:13:00.000Z',
        durationMs: 20000,
        hasErrors: false,
        resultSummary: 'Kokku: 1, õnnestus: 1, vigu: 0',
        result: [{ email: 'test@narva.ee', success: true }],
      };

      const decision = await evaluateTaskResultDecision(
        'sendFinBitReport',
        taskWithoutPrompt,
        successLogResult,
        new Date('2026-09-18T12:13:01.000Z')
      );

      expect(decision.status).toBe('SUCCESS');
      expect(decision.is_success).toBe(true);
      expect(decision.error).toBeNull();
    });

    it('runOrchestratorTick: если в ou.logs задача имеет скрытую ошибку ETIMEDOUT при status: success, она отправляется на retry', async () => {
      const testStateFile = testStatePath('state_retry_test.json');
      const initialDate = '2026-09-18';
      const afternoonTime = new Date(`${initialDate}T12:35:00.000Z`);

      const mockFetch = jest.fn().mockImplementation(async (url: string) => {
        if (url.includes('/task/read_log/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              result: 1,
              error_code: 0,
              data: [
                {
                  flow: 'sendFinBitReport',
                  status: 'success', // В СУБД заголовок success!
                  exec_start: `${initialDate}T12:30:00.000Z`,
                  exec_end: `${initialDate}T12:34:00.000Z`,
                  result: [
                    {
                      email: 'vladislav.gordin@gmail.com',
                      error: 'connect ETIMEDOUT 213.184.47.202:25',
                      success: false,
                    },
                  ],
                  response: 'vladislav.gordin@gmail.com: connect ETIMEDOUT 213.184.47.202:25',
                },
              ],
            }),
          };
        }
        if (url.includes('/task/sendFinBitReport/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 10999,
              data: { action: 'sendFinBitReport', status: 'STARTED', log_id: 10999 },
            }),
          };
        }
        return { ok: true, status: 200, json: async () => ({ result: 1, data: [] }) };
      });

      const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);

      // Создаем начальное состояние, где sendFinBitReport в статусе RUNNING с 1 попыткой
      const baseGraph = getDefaultTaskGraph();
      baseGraph.import_earved.status = 'SUCCESS';
      baseGraph.import_earved.log_id = 10429;
      baseGraph.sendFinBitReport.status = 'RUNNING';
      baseGraph.sendFinBitReport.attempts = 1;
      baseGraph.sendFinBitReport.log_id = 10430;
      baseGraph.sendFinBitReport.started_at = `${initialDate}T12:30:00.000Z`;

      const initState: OrchestratorState = {
        version: 1,
        cycle_date: initialDate,
        status: 'IN_PROGRESS',
        last_tick_at: null,
        next_scheduled_run: null,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: baseGraph,
        history: [],
      };
      fs.writeFileSync(testStateFile, JSON.stringify(initState, null, 2), 'utf-8');

      try {
        // Запускаем тик
        await runOrchestratorTick(
          { stateFilePath: testStateFile },
          {
            apiClient: client,
            currentDate: afternoonTime,
            targetDateStr: initialDate,
          }
        );

        // Проверяем сохраненное состояние
        const savedState: OrchestratorState = JSON.parse(fs.readFileSync(testStateFile, 'utf-8'));
        // sendFinBitReport должен быть отправлен на повторный запуск (attempts: 2, status: RUNNING)
        expect(savedState.tasks.sendFinBitReport.status).toBe('RUNNING');
        expect(savedState.tasks.sendFinBitReport.attempts).toBe(2);
        expect(savedState.tasks.sendFinBitReport.log_id).toBe(10999);
        expect(savedState.history.some((h) => h.event === 'TASK_RETRY')).toBe(true);
      } finally {
        if (fs.existsSync(testStateFile)) {
          try {
            fs.unlinkSync(testStateFile);
          } catch {}
        }
      }
    });

    it('runOrchestratorTick: при исключении в dispatchTaskByKey задача отправляется на retry (PENDING) до исчерпания max_attempts', async () => {
      const testStateFile = testStatePath('state_dispatch_retry_test.json');
      const initialDate = '2026-09-18';
      const eveningTime = new Date(`${initialDate}T20:05:00.000Z`);

      const mockFetch = jest.fn().mockImplementation(async (url: string) => {
        if (url.includes('/task/read_log/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({ result: 1, error_code: 0, data: [] }),
          };
        }
        if (url.includes('/task/calcKondSaldoandmik/')) {
          throw new Error('Connection refused to buh70 backend');
        }
        return { ok: true, status: 200, json: async () => ({ result: 1, data: [] }) };
      });

      const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);

      const baseGraph = getDefaultTaskGraph();
      baseGraph.saldoandmik.status = 'PENDING';
      baseGraph.saldoandmik.attempts = 0;
      baseGraph.saldoandmik.max_attempts = 3;

      const initState: OrchestratorState = {
        version: 1,
        cycle_date: initialDate,
        status: 'IN_PROGRESS',
        last_tick_at: null,
        next_scheduled_run: null,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: baseGraph,
        history: [],
      };
      fs.writeFileSync(testStateFile, JSON.stringify(initState, null, 2), 'utf-8');

      try {
        // Попытка 1 (attempts: 0 -> 1)
        await runOrchestratorTick(
          { stateFilePath: testStateFile },
          {
            apiClient: client,
            currentDate: eveningTime,
            targetDateStr: initialDate,
            forceRun: true,
          }
        );

        const savedState: OrchestratorState = JSON.parse(fs.readFileSync(testStateFile, 'utf-8'));
        expect(savedState.tasks.saldoandmik.status).toBe('PENDING');
        expect(savedState.tasks.saldoandmik.attempts).toBe(1);
        expect(savedState.tasks.saldoandmik.error).toBe('Connection refused to buh70 backend');
        expect(
          savedState.history.some(
            (h) => h.event === 'TASK_START_RETRY' && h.details?.includes('katse 1/3')
          )
        ).toBe(true);

        // Симулируем, что уже было 2 попытки, следующая (3-я) исчерпает max_attempts
        savedState.tasks.saldoandmik.attempts = 2;
        fs.writeFileSync(testStateFile, JSON.stringify(savedState, null, 2), 'utf-8');

        await runOrchestratorTick(
          { stateFilePath: testStateFile },
          {
            apiClient: client,
            currentDate: eveningTime,
            targetDateStr: initialDate,
            forceRun: true,
          }
        );

        const finalState: OrchestratorState = JSON.parse(fs.readFileSync(testStateFile, 'utf-8'));
        expect(finalState.tasks.saldoandmik.status).toBe('FAILED');
        expect(finalState.tasks.saldoandmik.attempts).toBe(3);
        expect(finalState.tasks.saldoandmik.error).toBe('Connection refused to buh70 backend');
        expect(
          finalState.history.some(
            (h) => h.event === 'TASK_START_FAILED' && h.details?.includes('ammendatud')
          )
        ).toBe(true);
      } finally {
        if (fs.existsSync(testStateFile)) {
          try {
            fs.unlinkSync(testStateFile);
          } catch {}
        }
      }
    }, 15000);

    it('runOrchestratorTick: Watchdog TASK_TIMEOUT срабатывает при превышении timeout_hours', async () => {
      const testStateFile = testStatePath('test_timeout_state.json');
      try {
        const stateManager = new StateManager(testStateFile);
        const state = await stateManager.loadState({ userId: 2477, rekvId: 63, kond: 1 }, '2026-10-08');

        // Задача lisa1_lisa5 запущена 13 часов назад (дефолтный лимит 12ч)
        state.status = 'IN_PROGRESS';
        state.tasks.lisa1_lisa5.status = 'RUNNING';
        state.tasks.lisa1_lisa5.attempts = 1;
        state.tasks.lisa1_lisa5.timeout_hours = 12;
        state.tasks.lisa1_lisa5.started_at = '2026-10-08T10:00:00.000Z';
        state.tasks.lisa1_lisa5.log_id = 991122;

        fs.writeFileSync(testStateFile, JSON.stringify(state, null, 2), 'utf-8');

        const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, jest.fn().mockImplementation(async (url: string) => {
          if (url.includes('/task/read_log/')) {
            return {
              ok: true,
              status: 200,
              json: async () => ({
                status: 200,
                result: 1,
                data: [{
                  id: 991122,
                  flow: 'eelarve.salvesta_lisa_1_5_kontrol',
                  status: null,
                  exec_start: '2026-10-08T10:00:00.000Z',
                }],
              }),
            };
          }
          if (url.includes('/task/calcLisa1Lisa5/')) {
            return {
              ok: true,
              status: 200,
              json: async () => ({ status: 200, result: 1, log_id: 991123, data: { status: 'STARTED' } }),
            };
          }
          return { ok: true, status: 200, json: async () => ({ status: 200 }) };
        }) as unknown as typeof fetch);

        // Проверяем в момент времени через 13 часов (23:00)
        const tickTime = new Date('2026-10-08T23:00:00.000Z');
        await runOrchestratorTick(
          { stateFilePath: testStateFile },
          {
            apiClient: client,
            currentDate: tickTime,
            targetDateStr: '2026-10-08',
            forceRun: true,
          }
        );

        const updated: OrchestratorState = JSON.parse(fs.readFileSync(testStateFile, 'utf-8'));
        expect(updated.tasks.lisa1_lisa5.attempts).toBe(2);
        expect(
          updated.history.some((h) => h.event === 'TASK_TIMEOUT' && h.details?.includes('ületatud 12 h'))
        ).toBe(true);
      } finally {
        if (fs.existsSync(testStateFile)) {
          try {
            fs.unlinkSync(testStateFile);
          } catch {}
        }
      }
    });

    it('runOrchestratorTick: задачи со schedule посуточно перевооружаются в PENDING при смене даты', async () => {
      const testStateFile = testStatePath('test_rearm_state.json');
      try {
        const stateManager = new StateManager(testStateFile);
        const state = await stateManager.loadState({ userId: 2477, rekvId: 63, kond: 1 }, '2026-10-08');

        state.status = 'IN_PROGRESS';
        state.cycle_date = '2026-10-08';
        state.tasks.getEarved.status = 'SUCCESS';
        state.tasks.getEarved.finished_at = '2026-10-08T08:00:00.000Z';
        state.tasks.getEarved.schedule = { time: '05:00' };

        fs.writeFileSync(testStateFile, JSON.stringify(state, null, 2), 'utf-8');

        const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, jest.fn().mockImplementation(async () => {
          return { ok: true, status: 200, json: async () => ({ status: 200, result: 1 }) };
        }) as unknown as typeof fetch);

        // Наступает следующий день: 2026-10-09 в 04:00 по Таллину (до наступления 05:00)
        const nextDayEarly = new Date('2026-10-09T01:00:00.000Z');
        await runOrchestratorTick(
          { stateFilePath: testStateFile },
          {
            apiClient: client,
            currentDate: nextDayEarly,
            targetDateStr: '2026-10-09',
            forceRun: false,
          }
        );

        const updated: OrchestratorState = JSON.parse(fs.readFileSync(testStateFile, 'utf-8'));
        expect(updated.tasks.getEarved.status).toBe('PENDING');
        expect(updated.tasks.getEarved.attempts).toBe(0);
        expect(updated.history.some((h) => h.event === 'TASK_REARMED')).toBe(true);
      } finally {
        if (fs.existsSync(testStateFile)) {
          try {
            fs.unlinkSync(testStateFile);
          } catch {}
        }
      }
    });

    it('runOrchestratorTick: вызывает /task/logAgentSchedule/ на каждом тике', async () => {
      const testStateFile = testStatePath('test_schedule_monitor_state.json');
      try {
        const { runScheduleMonitor: actualRunScheduleMonitor } = jest.requireActual('../schedule_monitor/agent');
        (runScheduleMonitor as jest.Mock).mockImplementation(actualRunScheduleMonitor);

        const stateManager = new StateManager(testStateFile);
        const state = await stateManager.loadState({ userId: 2477, rekvId: 63, kond: 1 }, '2026-10-09');
        fs.writeFileSync(testStateFile, JSON.stringify(state, null, 2), 'utf-8');

        let scheduleLogged = false;
        let loggedPayload: any = null;

        const client = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server' },
          jest.fn().mockImplementation(async (url: string, opts?: any) => {
            if (url.includes('/task/logAgentSchedule/')) {
              scheduleLogged = true;
              loggedPayload = JSON.parse(opts?.body || '{}');
              return {
                ok: true,
                status: 200,
                json: async () => ({ status: 200, result: 1, log_id: 998877 }),
              };
            }
            return { ok: true, status: 200, json: async () => ({ status: 200, result: 1 }) };
          }) as unknown as typeof fetch
        );

        await runOrchestratorTick(
          { stateFilePath: testStateFile },
          {
            apiClient: client,
            currentDate: new Date('2026-10-09T03:00:00.000Z'),
            targetDateStr: '2026-10-09',
            forceRun: true,
          }
        );

        expect(scheduleLogged).toBe(true);
        expect(loggedPayload?.snapshot?.agents?.length).toBeGreaterThan(0);
        expect(loggedPayload?.snapshot?.cycle_date).toBe('2026-10-09');
      } finally {
        (runScheduleMonitor as jest.Mock).mockResolvedValue(12345);
        if (fs.existsSync(testStateFile)) {
          try {
            fs.unlinkSync(testStateFile);
          } catch {}
        }
      }
    });

    it('runOrchestratorTick: вызывает /task/logAgentSchedule/ даже при раннем выходе IDLE_WAIT_NEXT_SCHEDULE', async () => {
      const testStateFile = testStatePath('test_schedule_monitor_early_exit.json');
      try {
        const { runScheduleMonitor: actualRunScheduleMonitor } = jest.requireActual('../schedule_monitor/agent');
        (runScheduleMonitor as jest.Mock).mockImplementation(actualRunScheduleMonitor);

        const stateManager = new StateManager(testStateFile);
        const state = await stateManager.loadState({ userId: 2477, rekvId: 63, kond: 1 }, '2026-10-09');
        state.status = 'COMPLETED';
        state.next_scheduled_run = '2026-10-10T17:00:00.000Z';
        for (const task of Object.values(state.tasks)) {
          task.status = 'SUCCESS';
        }
        fs.writeFileSync(testStateFile, JSON.stringify(state, null, 2), 'utf-8');

        let scheduleLogged = false;

        const client = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server' },
          jest.fn().mockImplementation(async (url: string) => {
            if (url.includes('/task/logAgentSchedule/')) {
              scheduleLogged = true;
              return {
                ok: true,
                status: 200,
                json: async () => ({ status: 200, result: 1, log_id: 112233 }),
              };
            }
            return { ok: true, status: 200, json: async () => ({ status: 200, result: 1 }) };
          }) as unknown as typeof fetch
        );

        const res = await runOrchestratorTick(
          { stateFilePath: testStateFile },
          {
            apiClient: client,
            currentDate: new Date('2026-10-10T10:00:00.000Z'),
            targetDateStr: '2026-10-09',
            forceRun: false,
          }
        );

        expect(res.action).toBe('IDLE_WAIT_NEXT_SCHEDULE');
        expect(scheduleLogged).toBe(true);
      } finally {
        (runScheduleMonitor as jest.Mock).mockResolvedValue(12345);
        if (fs.existsSync(testStateFile)) {
          try {
            fs.unlinkSync(testStateFile);
          } catch {}
        }
      }
    });

    it('runOrchestratorTick: не вызывает schedule_monitor, если в конфиге enabled = false', async () => {
      const testStateFile = testStatePath('test_schedule_monitor_disabled.json');
      try {
        const stateManager = new StateManager(testStateFile);
        const state = await stateManager.loadState({ userId: 2477, rekvId: 63, kond: 1 }, '2026-10-09');
        fs.writeFileSync(testStateFile, JSON.stringify(state, null, 2), 'utf-8');

        (runScheduleMonitor as jest.Mock).mockClear();

        const client = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server' },
          jest.fn().mockImplementation(async () => {
            return { ok: true, status: 200, json: async () => ({ status: 200, result: 1 }) };
          }) as unknown as typeof fetch
        );

        const mockConfig: OrchestratorConfig = {
          name: 'orchestrator',
          daily_start_time: '20:00',
          timezone: 'Europe/Tallinn',
          max_task_attempts: 3,
          params: { userId: 2477, rekvId: 63, kond: 1 },
          prompt: null,
          schedule_monitor: { enabled: false },
        };
        const spyLoadConfig = jest.spyOn(require('./state.manager'), 'loadOrchestratorConfig').mockReturnValue(mockConfig);

        await runOrchestratorTick(
          { stateFilePath: testStateFile },
          {
            apiClient: client,
            currentDate: new Date('2026-10-09T03:00:00.000Z'),
            targetDateStr: '2026-10-09',
            forceRun: true,
          }
        );

        expect(runScheduleMonitor).not.toHaveBeenCalled();
        spyLoadConfig.mockRestore();
      } finally {
        if (fs.existsSync(testStateFile)) {
          try {
            fs.unlinkSync(testStateFile);
          } catch {}
        }
      }
    });

    it('runOrchestratorTick: флаг taskKey точечно сбрасывает статус задачи в PENDING и запускает ее', async () => {
      const testStateFile = testStatePath('test_task_key_reset.json');
      try {
        const stateManager = new StateManager(testStateFile);
        const state = await stateManager.loadState({ userId: 2477, rekvId: 63, kond: 1 }, '2026-10-09');
        for (const task of Object.values(state.tasks)) {
          task.status = 'SUCCESS';
        }
        state.tasks.getEarved.status = 'FAILED';
        state.tasks.getEarved.attempts = 3;
        state.tasks.getEarved.error = 'Previous run failed';
        fs.writeFileSync(testStateFile, JSON.stringify(state, null, 2), 'utf-8');

        let dispatchedKey: string | null = null;
        const testRegistry = {
          getEarved: {
            dispatch: jest.fn().mockImplementation(async (ctx) => {
              dispatchedKey = ctx.key;
              return 999111;
            }),
          },
        };

        const client = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server' },
          jest.fn().mockImplementation(async () => {
            return { ok: true, status: 200, json: async () => ({ status: 200, result: 1 }) };
          }) as unknown as typeof fetch
        );

        const res = await runOrchestratorTick(
          { stateFilePath: testStateFile, taskKey: 'getEarved' },
          {
            apiClient: client,
            currentDate: new Date('2026-10-09T08:00:00.000Z'),
            targetDateStr: '2026-10-09',
            registry: testRegistry,
          }
        );

        expect(dispatchedKey).toBe('getEarved');
        expect(res.activeTasks).toContain('getEarved');

        const reloaded = await stateManager.loadState({}, '2026-10-09');
        expect(reloaded.tasks.getEarved.status).toBe('RUNNING');
        expect(reloaded.tasks.getEarved.attempts).toBe(1);
        expect(reloaded.tasks.getEarved.log_id).toBe(999111);
        const resetEvent = reloaded.history.find((h) => h.event === 'TASK_RESET_MANUAL');
        expect(resetEvent).toBeDefined();
        expect(resetEvent?.task).toBe('getEarved');
      } finally {
        if (fs.existsSync(testStateFile)) {
          try {
            fs.unlinkSync(testStateFile);
          } catch {}
        }
      }
    });

    it('runOrchestratorTick: неизвестный taskKey даёт предупреждение и событие TASK_RESET_UNKNOWN, тик не прерывается', async () => {
      const testStateFile = testStatePath('test_task_key_unknown.json');
      const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});
      try {
        const stateManager = new StateManager(testStateFile);
        const state = await stateManager.loadState({ userId: 2477, rekvId: 63, kond: 1 }, '2026-10-09');
        for (const task of Object.values(state.tasks)) {
          task.status = 'SUCCESS';
        }
        state.tasks.getEarved.status = 'FAILED';
        state.tasks.getEarved.attempts = 3;
        state.tasks.getEarved.error = 'Previous run failed';
        fs.writeFileSync(testStateFile, JSON.stringify(state, null, 2), 'utf-8');

        const testRegistry = {
          getEarved: {
            dispatch: jest.fn().mockResolvedValue(999222),
          },
        };

        const client = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server' },
          jest.fn().mockImplementation(async () => {
            return { ok: true, status: 200, json: async () => ({ status: 200, result: 1 }) };
          }) as unknown as typeof fetch
        );

        // Тик не должен падать на неизвестном ключе
        await expect(
          runOrchestratorTick(
            { stateFilePath: testStateFile, taskKey: 'noSuchTask' },
            {
              apiClient: client,
              currentDate: new Date('2026-10-09T08:00:00.000Z'),
              targetDateStr: '2026-10-09',
              registry: testRegistry,
            }
          )
        ).resolves.toBeDefined();

        // Предупреждение содержит неизвестный ключ и список допустимых ключей
        const warnMessages = warnSpy.mock.calls.map((c) => String(c[0]));
        const unknownWarn = warnMessages.find((m) => m.includes('noSuchTask'));
        expect(unknownWarn).toBeDefined();
        expect(unknownWarn).toContain('getEarved');

        const reloaded = await stateManager.loadState({}, '2026-10-09');
        const unknownEvent = reloaded.history.find((h) => h.event === 'TASK_RESET_UNKNOWN');
        expect(unknownEvent).toBeDefined();
        expect(unknownEvent?.task).toBe('noSuchTask');
        expect(reloaded.history.find((h) => h.event === 'TASK_RESET_MANUAL')).toBeUndefined();

        // Ни одна задача не была сброшена вручную: упавшая задача остаётся FAILED с прежними попытками
        expect(testRegistry.getEarved.dispatch).not.toHaveBeenCalled();
        expect(reloaded.tasks.getEarved.status).toBe('FAILED');
        expect(reloaded.tasks.getEarved.attempts).toBe(3);
        expect(reloaded.tasks.noSuchTask).toBeUndefined();
      } finally {
        warnSpy.mockRestore();
        if (fs.existsSync(testStateFile)) {
          try {
            fs.unlinkSync(testStateFile);
          } catch {}
        }
      }
    });

    it('runOrchestratorTick: при неизвестном taskKey готовая PENDING-задача не запускается, без taskKey то же состояние её запускает', async () => {
      const testStateFile = testStatePath('test_task_key_unknown_pending.json');
      const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});
      try {
        const stateManager = new StateManager(testStateFile);

        // Одинаковое исходное состояние для обоих тиков: getEarved в PENDING и готова к запуску
        const writeInitialState = async () => {
          if (fs.existsSync(testStateFile)) {
            fs.unlinkSync(testStateFile);
          }
          const state = await stateManager.loadState({ userId: 2477, rekvId: 63, kond: 1 }, '2026-10-09');
          for (const task of Object.values(state.tasks)) {
            task.status = 'SUCCESS';
          }
          state.tasks.getEarved.status = 'PENDING';
          state.tasks.getEarved.attempts = 0;
          fs.writeFileSync(testStateFile, JSON.stringify(state, null, 2), 'utf-8');
        };

        const makeClient = () =>
          new ApiClient(
            { buh70ApiBaseUrl: 'http://test-server' },
            jest.fn().mockImplementation(async () => {
              return { ok: true, status: 200, json: async () => ({ status: 200, result: 1 }) };
            }) as unknown as typeof fetch
          );

        const tickOptions = () => ({
          apiClient: makeClient(),
          currentDate: new Date('2026-10-09T08:00:00.000Z'),
          targetDateStr: '2026-10-09',
        });

        // Тик 1: неизвестный ключ — запуски задач пропускаются
        await writeInitialState();
        const dispatchUnknown = jest.fn().mockResolvedValue(999333);
        const resUnknown = await runOrchestratorTick(
          { stateFilePath: testStateFile, taskKey: 'noSuchTask' },
          { ...tickOptions(), registry: { getEarved: { dispatch: dispatchUnknown } } }
        );

        expect(dispatchUnknown).not.toHaveBeenCalled();
        expect(resUnknown.activeTasks).not.toContain('getEarved');
        const afterUnknown = await stateManager.loadState({}, '2026-10-09');
        expect(afterUnknown.tasks.getEarved.status).toBe('PENDING');
        const unknownEvent = afterUnknown.history.find((h) => h.event === 'TASK_RESET_UNKNOWN');
        expect(unknownEvent?.details).toContain('no tasks are launched in this tick');
        const unknownWarn = warnSpy.mock.calls.map((c) => String(c[0])).find((m) => m.includes('noSuchTask'));
        expect(unknownWarn).toContain('ühtegi ülesannet ei käivitata');

        // Тик 2: то же состояние без taskKey — задача запускается (тест не проходит вхолостую)
        await writeInitialState();
        const dispatchNormal = jest.fn().mockResolvedValue(999444);
        const resNormal = await runOrchestratorTick(
          { stateFilePath: testStateFile },
          { ...tickOptions(), registry: { getEarved: { dispatch: dispatchNormal } } }
        );

        expect(dispatchNormal).toHaveBeenCalledTimes(1);
        expect(resNormal.activeTasks).toContain('getEarved');
        const afterNormal = await stateManager.loadState({}, '2026-10-09');
        expect(afterNormal.tasks.getEarved.status).toBe('RUNNING');
        expect(afterNormal.tasks.getEarved.log_id).toBe(999444);
      } finally {
        warnSpy.mockRestore();
        if (fs.existsSync(testStateFile)) {
          try {
            fs.unlinkSync(testStateFile);
          } catch {}
        }
      }
    });

    it('runOrchestratorTick: каскадно перевооружает зависимые задачи (depends_on) при смене календарных суток', async () => {
      const testStateFile = testStatePath('test_cascade_rearm.json');
      try {
        const stateManager = new StateManager(testStateFile);
        const state = await stateManager.loadState({ userId: 2477, rekvId: 63, kond: 1 }, '2026-10-08');
        state.tasks.getEarved.status = 'SUCCESS';
        state.tasks.getEarved.finished_at = '2026-10-08T07:15:00.000Z';
        state.tasks.getEarved.log_id = 10101;
        state.tasks.sendFinBitReport.status = 'SUCCESS';
        state.tasks.sendFinBitReport.finished_at = '2026-10-08T07:20:00.000Z';
        state.tasks.sendFinBitReport.log_id = 10102;
        state.cycle_date = '2026-10-08';
        state.status = 'COMPLETED';

        fs.writeFileSync(testStateFile, JSON.stringify(state, null, 2), 'utf-8');

        const client = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server' },
          jest.fn().mockImplementation(async () => {
            return { ok: true, status: 200, json: async () => ({ status: 200, result: 1 }) };
          }) as unknown as typeof fetch
        );

        await runOrchestratorTick(
          { stateFilePath: testStateFile },
          {
            apiClient: client,
            currentDate: new Date('2026-10-09T03:00:00.000Z'),
            targetDateStr: '2026-10-09',
            forceRun: false,
          }
        );

        const reloaded = await stateManager.loadState({}, '2026-10-09');
        expect(reloaded.tasks.getEarved.status).toBe('PENDING');
        expect(reloaded.tasks.getEarved.log_id).toBeNull();
        expect(reloaded.tasks.sendFinBitReport.status).toBe('PENDING');
        expect(reloaded.tasks.sendFinBitReport.log_id).toBeNull();

        const rearmEvents = reloaded.history.filter((h) => h.event === 'TASK_REARMED');
        expect(rearmEvents.some((e) => e.task === 'getEarved')).toBe(true);
        expect(rearmEvents.some((e) => e.task === 'sendFinBitReport')).toBe(true);
      } finally {
        if (fs.existsSync(testStateFile)) {
          try {
            fs.unlinkSync(testStateFile);
          } catch {}
        }
      }
    });

    it('runOrchestratorTick: parentParams (logId родителя) приоритетнее закешированного task.params.logId', async () => {
      const testStateFile = testStatePath('test_param_priority.json');
      try {
        const stateManager = new StateManager(testStateFile);
        const state = await stateManager.loadState({ userId: 2477, rekvId: 63, kond: 1 }, '2026-10-09');

        state.tasks.import_earved.status = 'SUCCESS';
        state.tasks.import_earved.log_id = 777;

        state.tasks.sendFinBitReport.status = 'PENDING';
        state.tasks.sendFinBitReport.params = { logId: 999 };

        fs.writeFileSync(testStateFile, JSON.stringify(state, null, 2), 'utf-8');

        let dispatchedParams: Record<string, unknown> | null = null;
        const testRegistry = {
          sendFinBitReport: {
            dispatch: jest.fn().mockImplementation(async (ctx) => {
              dispatchedParams = ctx.params;
              return 888111;
            }),
            resolveParentParams: (s: any) => ({ logId: s.tasks.import_earved.log_id }),
          },
        };

        const client = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server' },
          jest.fn().mockImplementation(async () => {
            return { ok: true, status: 200, json: async () => ({ status: 200, result: 1 }) };
          }) as unknown as typeof fetch
        );

        await runOrchestratorTick(
          { stateFilePath: testStateFile, taskKey: 'sendFinBitReport' },
          {
            apiClient: client,
            currentDate: new Date('2026-10-09T08:00:00.000Z'),
            targetDateStr: '2026-10-09',
            registry: testRegistry,
          }
        );

        expect(dispatchedParams).toBeDefined();
        // logId родительского import_earved (777) приоритетнее закешированного значения (999)
        expect((dispatchedParams as Record<string, unknown> | null)?.logId).toBe(777);
      } finally {
        if (fs.existsSync(testStateFile)) {
          try {
            fs.unlinkSync(testStateFile);
          } catch {}
        }
      }
    });

    it('evaluateTaskLaunchDecision: возвращает WAIT (Downstream Lock), если зависимая задача в RUNNING', async () => {
      const stateManager = new StateManager(testStatePath('test_downstream_lock_decision.json'));
      const state = await stateManager.loadState({ userId: 2477, rekvId: 63, kond: 1 }, '2026-10-12');
      state.tasks.saldoandmik.status = 'PENDING';
      state.tasks.lisa1_lisa5.status = 'RUNNING';

      const decision = await evaluateTaskLaunchDecision(
        'saldoandmik',
        state.tasks.saldoandmik,
        state,
        new Date('2026-10-12T20:30:00.000Z'),
        20,
        false
      );

      expect(decision.action).toBe('WAIT');
      expect(decision.should_run).toBe(false);
      expect(decision.reason).toContain('lisa1_lisa5');
    });

    it('runOrchestratorTick: Downstream Lock защищает родительскую задачу от перевооружения и перезапуска, пока потомок в RUNNING', async () => {
      const testStateFile = testStatePath('test_downstream_lock.json');
      try {
        const stateManager = new StateManager(testStateFile);
        const state = await stateManager.loadState({ userId: 2477, rekvId: 63, kond: 1 }, '2026-10-09');
        state.cycle_date = '2026-10-09';
        state.status = 'IN_PROGRESS';
        state.tasks.saldoandmik.status = 'SUCCESS';
        state.tasks.saldoandmik.started_at = '2026-10-12T17:00:00.000Z';
        state.tasks.saldoandmik.finished_at = '2026-10-12T17:10:00.000Z';
        state.tasks.saldoandmik.schedule = { time: '20:00' };

        // Дочерняя задача lisa1_lisa5 исполняется
        state.tasks.lisa1_lisa5.status = 'RUNNING';
        state.tasks.lisa1_lisa5.started_at = '2026-10-12T19:30:00.000Z';
        state.tasks.lisa1_lisa5.log_id = 8546972;

        fs.writeFileSync(testStateFile, JSON.stringify(state, null, 2), 'utf-8');

        let saldoandmikDispatched = false;
        const testRegistry = {
          saldoandmik: {
            flow: 'eelarve.sp_koosta_saldoandmik',
            dispatch: async () => {
              saldoandmikDispatched = true;
              return 99999;
            },
          },
          lisa1_lisa5: {
            flow: 'eelarve.salvesta_lisa_1_5_kontrol',
            dispatch: async () => 99998,
          },
        };

        const client = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server' },
          jest.fn().mockImplementation(async () => {
            return {
              ok: true,
              status: 200,
              json: async () => ({
                status: 200,
                result: [{ status: 'running', exec_start: '2026-10-12T19:30:00.000Z' }],
              }),
            };
          }) as unknown as typeof fetch
        );

        // Тик в 20:00:04 UTC (23:00 local)
        const tickTime = new Date('2026-10-12T20:00:04.100Z');
        await runOrchestratorTick(
          { stateFilePath: testStateFile },
          {
            apiClient: client,
            currentDate: tickTime,
            targetDateStr: '2026-10-12',
            registry: testRegistry,
            forceRun: false,
          }
        );

        const updated: OrchestratorState = JSON.parse(fs.readFileSync(testStateFile, 'utf-8'));

        // saldoandmik не должен быть перезапущен
        expect(saldoandmikDispatched).toBe(false);
        expect(updated.tasks.saldoandmik.status).toBe('SUCCESS');
        expect(updated.tasks.lisa1_lisa5.status).toBe('RUNNING');
      } finally {
        if (fs.existsSync(testStateFile)) {
          try {
            fs.unlinkSync(testStateFile);
          } catch {}
        }
      }
    });

    it('runOrchestratorTick: reporter запускается по расписанию 08:00 и собирает данные из ou.logs за последние 24 часа', async () => {
      const testStateFile = testStatePath('test_state_reporter_8am.json');
      const testState: OrchestratorState = {
        version: 1,
        cycle_date: '2026-10-14',
        status: 'IN_PROGRESS',
        last_tick_at: null,
        next_scheduled_run: null,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: {
          saldoandmik: {
            flow: 'eelarve.sp_koosta_saldoandmik',
            depends_on: [],
            allow_parallel: true,
            schedule: null,
            prompt: null,
            params: {},
            status: 'SUCCESS',
            attempts: 1,
            max_attempts: 3,
            log_id: 101,
            started_at: '2026-10-13T17:00:00.000Z',
            finished_at: '2026-10-13T17:01:00.000Z',
            duration_ms: 60000,
            error: null,
          },
          calc_arv_jaak: {
            flow: 'docs.check_arv_jaak',
            depends_on: [],
            allow_parallel: true,
            schedule: null,
            prompt: null,
            params: {},
            status: 'SUCCESS',
            attempts: 1,
            max_attempts: 3,
            log_id: 102,
            started_at: '2026-10-14T04:30:00.000Z',
            finished_at: '2026-10-14T04:30:10.000Z',
            duration_ms: 10000,
            error: null,
          },
          reporter: {
            flow: 'email_report',
            depends_on: [],
            allow_parallel: false,
            schedule: { time: '08:00' },
            prompt: null,
            params: {},
            status: 'PENDING',
            attempts: 0,
            max_attempts: 3,
            log_id: null,
            started_at: null,
            finished_at: null,
            duration_ms: null,
            error: null,
          },
        },
        history: [],
      };
      fs.writeFileSync(testStateFile, JSON.stringify(testState, null, 2), 'utf-8');

      try {
        const mockFetch = jest.fn().mockImplementation(async (url: string) => {
          if (url.includes('/task/read_log/')) {
            return {
              ok: true,
              status: 200,
              json: async () => ({
                error_code: 0,
                result: 1,
                error_message: null,
                data: [
                  {
                    id: 9988,
                    flow: 'docs.check_arv_jaak',
                    status: 'success',
                    exec_start: '2026-10-14T04:30:00.000Z',
                    exec_end: '2026-10-14T04:30:10.000Z',
                    result: null,
                    response: 'OK',
                    error: null,
                  },
                ],
              }),
            };
          }
          return {
            ok: true,
            status: 200,
            json: async () => ({ status: 200, result: 1 }),
          };
        });

        const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);

        // 1. До 08:00 (например, в 07:45 local / 04:45 UTC): reporter ожидает в PENDING
        const before8Am = new Date('2026-10-14T04:45:00.000Z');
        await runOrchestratorTick(
          { stateFilePath: testStateFile },
          {
            apiClient: client,
            currentDate: before8Am,
            targetDateStr: '2026-10-14',
            forceRun: false,
          }
        );

        let stateAfterEarlyTick: OrchestratorState = JSON.parse(fs.readFileSync(testStateFile, 'utf-8'));
        expect(stateAfterEarlyTick.tasks.reporter.status).toBe('PENDING');

        // 2. В 08:00 local (05:00 UTC): reporter срабатывает и завершается SUCCESS
        const at8Am = new Date('2026-10-14T05:00:00.000Z');
        await runOrchestratorTick(
          { stateFilePath: testStateFile },
          {
            apiClient: client,
            currentDate: at8Am,
            targetDateStr: '2026-10-14',
            forceRun: false,
          }
        );

        let stateAfter8Am: OrchestratorState = JSON.parse(fs.readFileSync(testStateFile, 'utf-8'));
        expect(stateAfter8Am.tasks.reporter.status).toBe('SUCCESS');
        expect(stateAfter8Am.tasks.reporter.finished_at).toBeTruthy();

        // 3. В 17:00 local (14:00 UTC): reporter НЕ перезапускается, статус остается SUCCESS
        const at5Pm = new Date('2026-10-14T14:00:00.000Z');
        await runOrchestratorTick(
          { stateFilePath: testStateFile },
          {
            apiClient: client,
            currentDate: at5Pm,
            targetDateStr: '2026-10-14',
            forceRun: false,
          }
        );

        let stateAfter5Pm: OrchestratorState = JSON.parse(fs.readFileSync(testStateFile, 'utf-8'));
        expect(stateAfter5Pm.tasks.reporter.status).toBe('SUCCESS');
        expect(stateAfter5Pm.tasks.reporter.finished_at).toBe(stateAfter8Am.tasks.reporter.finished_at);
      } finally {
        if (fs.existsSync(testStateFile)) {
          try {
            fs.unlinkSync(testStateFile);
          } catch {}
        }
      }
    });

    it('динамический реестр и reconcileTasksWithConfigs: обнаруживает read_mail (prompt: null, 06:00) и исключает schedule_monitor из state.tasks', () => {
      const configs = loadAllAgentConfigs();
      expect(configs.read_mail).toBeDefined();
      expect(configs.read_mail.flow).toBe('mail.read_mail_errors');
      expect(configs.read_mail.schedule).toEqual({ time: '06:00' });
      expect(configs.read_mail.prompt).toBeNull();
      expect(configs.schedule_monitor).toBeUndefined();

      const tasks: Record<string, any> = {
        schedule_monitor: {
          flow: 'ai_task.agent_schedule',
          depends_on: [],
          allow_parallel: true,
          schedule: null,
          prompt: null,
          params: {},
          status: 'PENDING',
          attempts: 0,
          max_attempts: 3,
          log_id: null,
          started_at: null,
          finished_at: null,
          duration_ms: null,
          error: null,
        },
      };

      reconcileTasksWithConfigs(tasks, configs, true);
      expect(tasks.schedule_monitor).toBeUndefined();
      expect(tasks.read_mail).toBeDefined();
      expect(tasks.read_mail.status).toBe('PENDING');
    });

    it('runOrchestratorTick: передает индивидуальный task.params.userId (11770) при проверке checkTaskStatus в RUNNING и обогащает отчет через manifest.enrichReportStep', async () => {
      const testState: OrchestratorState = {
        version: 1,
        cycle_date: '2026-10-18',
        status: 'IN_PROGRESS',
        last_tick_at: '2026-10-18T05:00:00.000Z',
        next_scheduled_run: null,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: {
          getEarved: {
            flow: 'getEarved',
            depends_on: [],
            allow_parallel: true,
            schedule: { time: '07:00' },
            prompt: null,
            params: { is_agent: true, userId: 11770 },
            status: 'RUNNING',
            attempts: 1,
            max_attempts: 3,
            log_id: 8548120,
            started_at: '2026-10-18T04:00:00.000Z',
            finished_at: null,
            duration_ms: null,
            error: null,
          },
          read_mail: {
            flow: 'mail.read_mail_errors',
            depends_on: [],
            allow_parallel: true,
            schedule: { time: '06:00' },
            prompt: null,
            params: { userId: 2477, rekvId: 63 },
            status: 'SUCCESS',
            attempts: 1,
            max_attempts: 3,
            log_id: 8548110,
            started_at: '2026-10-18T03:00:00.000Z',
            finished_at: '2026-10-18T03:01:00.000Z',
            duration_ms: 60000,
            error: null,
          },
          reporter: {
            flow: 'email_report',
            depends_on: [],
            allow_parallel: false,
            schedule: { time: '08:00' },
            prompt: null,
            params: {},
            status: 'PENDING',
            attempts: 0,
            max_attempts: 3,
            log_id: null,
            started_at: null,
            finished_at: null,
            duration_ms: null,
            error: null,
          },
        },
        history: [],
      };
      fs.writeFileSync(testStateFile, JSON.stringify(testState, null, 2), 'utf-8');

      const calledUrls: string[] = [];
      const mockFetch = jest.fn().mockImplementation(async (url: string) => {
        calledUrls.push(url);
        if (url.includes('/task/read_log/11770/getEarved')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              error_code: 0,
              result: 1,
              data: [
                {
                  id: 8548120,
                  flow: 'getEarved',
                  status: 'success',
                  exec_start: '2026-10-18T04:00:00.000Z',
                  exec_end: '2026-10-18T04:00:15.000Z',
                  result: 0,
                  response: 'OK',
                  error: null,
                },
              ],
            }),
          };
        }
        if (url.includes('/task/read_log/2477/mail.read_mail_errors')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              error_code: 0,
              result: 1,
              data: [
                {
                  id: 8548110,
                  flow: 'mail.read_mail_errors',
                  status: 'success',
                  exec_start: '2026-10-18T03:00:00.000Z',
                  exec_end: '2026-10-18T03:01:00.000Z',
                  result: [
                    {
                      status: 'Aadressi viga',
                      error_reason: 'User unknown',
                      doc_number: '101-10772',
                      recipient_email: 'invalid@example.com',
                    },
                  ],
                  response: 'OK',
                  error: null,
                },
              ],
            }),
          };
        }
        return {
          ok: true,
          status: 200,
          json: async () => ({ status: 200, result: 1, data: [] }),
        };
      });

      const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);

      // 1. В 04:00 local (01:00 UTC) даже при forceRun: true reporter НЕ должен запускаться до 08:00
      await runOrchestratorTick(
        { stateFilePath: testStateFile, forceRun: true },
        {
          apiClient: client,
          currentDate: new Date('2026-10-18T01:00:00.000Z'),
          targetDateStr: '2026-10-18',
          forceRun: true,
        }
      );

      const savedAfterEarly = JSON.parse(fs.readFileSync(testStateFile, 'utf-8'));
      expect(calledUrls.some((u) => u.includes('/task/read_log/11770/getEarved'))).toBe(true);
      expect(savedAfterEarly.tasks.getEarved.status).toBe('SUCCESS');
      expect(savedAfterEarly.tasks.reporter.status).toBe('PENDING');

      // 2. В 08:00 local (05:00 UTC) reporter запускается и обогащает шаг read_mail через manifest.enrichReportStep
      await runOrchestratorTick(
        { stateFilePath: testStateFile },
        {
          apiClient: client,
          currentDate: new Date('2026-10-18T05:00:00.000Z'),
          targetDateStr: '2026-10-18',
          forceRun: false,
        }
      );

      const savedAfter8Am = JSON.parse(fs.readFileSync(testStateFile, 'utf-8'));
      expect(savedAfter8Am.tasks.reporter.status).toBe('SUCCESS');
    });
  });

  describe('Надежность цепочки FinBit: retryable, статус по log_id, ожидание reporter', () => {
    const TEST_DATE = '2026-10-14';

    /** Записывает состояние, где все задачи уже завершены (SKIPPED), кроме тех, что настраивает mutate */
    function writeState(file: string, mutate: (tasks: Record<string, any>) => void): void {
      const tasks: Record<string, any> = getDefaultTaskGraph();
      for (const t of Object.values(tasks)) {
        t.status = 'SKIPPED';
        t.finished_at = `${TEST_DATE}T01:00:00.000Z`;
      }
      mutate(tasks);
      const initState: OrchestratorState = {
        version: 1,
        cycle_date: TEST_DATE,
        status: 'IN_PROGRESS',
        last_tick_at: null,
        next_scheduled_run: null,
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks,
        history: [],
      };
      fs.writeFileSync(file, JSON.stringify(initState, null, 2), 'utf-8');
    }

    function makeEntry(overrides: Record<string, unknown>) {
      return {
        id: 20001,
        flow: 'sendFinBitReport',
        status: null,
        exec_start: `${TEST_DATE}T05:00:00.000Z`,
        exec_end: null,
        result: null,
        response: null,
        error: null,
        ...overrides,
      };
    }

    function makeClient(
      byIdEntry: Record<string, unknown> | null,
      byFlowEntry: Record<string, unknown> | null,
      calls: string[]
    ) {
      const mockFetch = jest.fn().mockImplementation(async (url: string) => {
        calls.push(url);
        if (url.includes('/task/read_log/')) {
          const entry = url.includes('log_id=') ? byIdEntry : byFlowEntry;
          return {
            ok: true,
            status: 200,
            json: async () => ({ result: 1, error_code: 0, error_message: null, data: entry ? [entry] : [] }),
          };
        }
        if (url.includes('/task/sendFinBitReport/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: 1,
              log_id: 29999,
              data: { action: 'sendFinBitReport', status: 'STARTED', log_id: 29999 },
            }),
          };
        }
        return { ok: true, status: 200, json: async () => ({ status: 200, result: 1 }) };
      });
      return new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);
    }

    function cleanup(file: string) {
      if (fs.existsSync(file)) {
        try {
          fs.unlinkSync(file);
        } catch {}
      }
    }

    it('retryable=false в логе: задача сразу FAILED, повторный запуск не выполняется', async () => {
      const file = testStatePath('state_non_retryable_test.json');
      writeState(file, (tasks) => {
        tasks.import_earved.status = 'SUCCESS';
        tasks.import_earved.log_id = 20000;
        tasks.sendFinBitReport.status = 'RUNNING';
        tasks.sendFinBitReport.attempts = 1;
        tasks.sendFinBitReport.log_id = 20001;
        tasks.sendFinBitReport.started_at = `${TEST_DATE}T05:00:00.000Z`;
        tasks.sendFinBitReport.finished_at = null;
        tasks.reporter.status = 'SUCCESS';
        tasks.reporter.finished_at = `${TEST_DATE}T05:00:00.000Z`;
      });
      const calls: string[] = [];
      const failedEntry = makeEntry({
        status: 'failed',
        exec_end: `${TEST_DATE}T05:00:10.000Z`,
        result: [],
        error: 'Imporditud 3 arvet, kuid saajaid ei leitud',
        retryable: 'false',
      });
      const client = makeClient(failedEntry, failedEntry, calls);

      try {
        await runOrchestratorTick(
          { stateFilePath: file },
          { apiClient: client, currentDate: new Date(`${TEST_DATE}T06:00:00.000Z`), targetDateStr: TEST_DATE }
        );

        const saved: OrchestratorState = JSON.parse(fs.readFileSync(file, 'utf-8'));
        expect(saved.tasks.sendFinBitReport.status).toBe('FAILED');
        expect(saved.tasks.sendFinBitReport.attempts).toBe(1);
        expect(saved.history.some((h) => h.event === 'TASK_FAILED_NON_RETRYABLE')).toBe(true);
        expect(saved.history.some((h) => h.event === 'TASK_RETRY')).toBe(false);
        expect(calls.some((u) => u.includes('/task/sendFinBitReport/'))).toBe(false);
        // статус читался по log_id запуска
        expect(calls.some((u) => u.includes('/task/read_log/11770/sendFinBitReport') && u.includes('log_id=20001'))).toBe(true);
      } finally {
        cleanup(file);
      }
    });

    it('статус задачи берется по log_id: более поздний чужой успешный запуск flow не закрывает задачу', async () => {
      const file = testStatePath('state_by_log_id_test.json');
      writeState(file, (tasks) => {
        tasks.import_earved.status = 'SUCCESS';
        tasks.import_earved.log_id = 20000;
        tasks.sendFinBitReport.status = 'RUNNING';
        tasks.sendFinBitReport.attempts = 1;
        tasks.sendFinBitReport.log_id = 20001;
        tasks.sendFinBitReport.started_at = `${TEST_DATE}T05:00:00.000Z`;
        tasks.sendFinBitReport.finished_at = null;
        tasks.reporter.status = 'SUCCESS';
        tasks.reporter.finished_at = `${TEST_DATE}T05:00:00.000Z`;
      });
      const calls: string[] = [];
      // наша запись еще выполняется, а последняя запись flow - чужой (ручной) успешный запуск
      const ownRunning = makeEntry({ id: 20001, status: null });
      const foreignSuccess = makeEntry({
        id: 20050,
        status: 'success',
        exec_start: `${TEST_DATE}T05:20:00.000Z`,
        exec_end: `${TEST_DATE}T05:20:05.000Z`,
        result: [{ email: 'a@narva.ee', success: true }],
      });
      const client = makeClient(ownRunning, foreignSuccess, calls);

      try {
        await runOrchestratorTick(
          { stateFilePath: file },
          { apiClient: client, currentDate: new Date(`${TEST_DATE}T06:00:00.000Z`), targetDateStr: TEST_DATE }
        );

        const saved: OrchestratorState = JSON.parse(fs.readFileSync(file, 'utf-8'));
        expect(saved.tasks.sendFinBitReport.status).toBe('RUNNING');
        expect(saved.tasks.sendFinBitReport.log_id).toBe(20001);
      } finally {
        cleanup(file);
      }
    });

    it('перед повтором принимается более поздний успешный запуск flow за сегодня (ручной перезапуск)', async () => {
      const file = testStatePath('state_reconcile_later_run_test.json');
      writeState(file, (tasks) => {
        tasks.import_earved.status = 'SUCCESS';
        tasks.import_earved.log_id = 20000;
        tasks.sendFinBitReport.status = 'RUNNING';
        tasks.sendFinBitReport.attempts = 1;
        tasks.sendFinBitReport.log_id = 20001;
        tasks.sendFinBitReport.started_at = `${TEST_DATE}T05:00:00.000Z`;
        tasks.sendFinBitReport.finished_at = null;
        tasks.reporter.status = 'SUCCESS';
        tasks.reporter.finished_at = `${TEST_DATE}T05:00:00.000Z`;
      });
      const calls: string[] = [];
      const ownFailed = makeEntry({
        id: 20001,
        status: 'failed',
        exec_end: `${TEST_DATE}T05:00:10.000Z`,
        result: [{ email: 'a@narva.ee', success: false, error: 'connect ETIMEDOUT' }],
        error: 'Kõik teavituste saatmised ebaõnnestusid (vigu: 1)',
        retryable: 'true',
      });
      const laterSuccess = makeEntry({
        id: 20050,
        status: 'success',
        exec_start: `${TEST_DATE}T05:30:00.000Z`,
        exec_end: `${TEST_DATE}T05:30:05.000Z`,
        result: [{ email: 'a@narva.ee', success: true }],
      });
      const client = makeClient(ownFailed, laterSuccess, calls);

      try {
        await runOrchestratorTick(
          { stateFilePath: file },
          { apiClient: client, currentDate: new Date(`${TEST_DATE}T06:00:00.000Z`), targetDateStr: TEST_DATE }
        );

        const saved: OrchestratorState = JSON.parse(fs.readFileSync(file, 'utf-8'));
        expect(saved.tasks.sendFinBitReport.status).toBe('SUCCESS');
        expect(saved.tasks.sendFinBitReport.log_id).toBe(20050);
        expect(saved.history.some((h) => h.event === 'TASK_RECONCILED_LOGS')).toBe(true);
        expect(calls.some((u) => u.includes('/task/sendFinBitReport/'))).toBe(false);
      } finally {
        cleanup(file);
      }
    });

    it('reporter ждет зависимости до max_wait_time (09:00) и после него отправляет отчет без них', async () => {
      const file = testStatePath('state_reporter_wait_test.json');
      writeState(file, (tasks) => {
        tasks.import_earved.status = 'SUCCESS';
        tasks.import_earved.log_id = 20000;
        tasks.sendFinBitReport.status = 'RUNNING';
        tasks.sendFinBitReport.attempts = 1;
        tasks.sendFinBitReport.log_id = 20001;
        tasks.sendFinBitReport.started_at = `${TEST_DATE}T04:50:00.000Z`;
        tasks.sendFinBitReport.finished_at = null;
        tasks.reporter.status = 'PENDING';
        tasks.reporter.finished_at = null;
      });
      const calls: string[] = [];
      const running = makeEntry({ id: 20001, status: null, exec_start: `${TEST_DATE}T04:50:00.000Z` });
      const client = makeClient(running, running, calls);

      try {
        // 08:30 по Таллину (05:30Z): зависимость еще выполняется, max_wait_time (09:00) не наступило
        await runOrchestratorTick(
          { stateFilePath: file },
          { apiClient: client, currentDate: new Date(`${TEST_DATE}T05:30:00.000Z`), targetDateStr: TEST_DATE }
        );
        let saved: OrchestratorState = JSON.parse(fs.readFileSync(file, 'utf-8'));
        expect(saved.tasks.reporter.status).toBe('PENDING');

        // 09:30 по Таллину (06:30Z): предельное время ожидания истекло - отчет уходит с тем, что есть
        await runOrchestratorTick(
          { stateFilePath: file },
          { apiClient: client, currentDate: new Date(`${TEST_DATE}T06:30:00.000Z`), targetDateStr: TEST_DATE }
        );
        saved = JSON.parse(fs.readFileSync(file, 'utf-8'));
        expect(saved.tasks.reporter.status).toBe('SUCCESS');
        expect(saved.tasks.sendFinBitReport.status).toBe('RUNNING');
      } finally {
        cleanup(file);
      }
    });

    it('reporter не ждет max_wait_time, если все зависимости уже завершены', async () => {
      const file = testStatePath('state_reporter_deps_done_test.json');
      writeState(file, (tasks) => {
        tasks.sendFinBitReport.status = 'SUCCESS';
        tasks.calc_arv_jaak.status = 'SUCCESS';
        tasks.read_mail.status = 'SUCCESS';
        tasks.reporter.status = 'PENDING';
        tasks.reporter.finished_at = null;
      });
      const calls: string[] = [];
      const client = makeClient(null, null, calls);

      try {
        // 08:30 по Таллину: все зависимости завершены, ждать 09:00 не нужно
        await runOrchestratorTick(
          { stateFilePath: file },
          { apiClient: client, currentDate: new Date(`${TEST_DATE}T05:30:00.000Z`), targetDateStr: TEST_DATE }
        );
        const saved: OrchestratorState = JSON.parse(fs.readFileSync(file, 'utf-8'));
        expect(saved.tasks.reporter.status).toBe('SUCCESS');
      } finally {
        cleanup(file);
      }
    });
  });

  describe('Регрессионные тесты: TZ полночь и закрытие цикла при смене суток', () => {
    it('вычисляет targetDateStr как 00:30 Europe/Tallinn при UTC-предыдущем дне и перевооружает задачи', async () => {
      const file = testStatePath('state_tz_midnight_test.json');
      try {
        const stateManager = new StateManager(file);
        const state = await stateManager.loadState({ userId: 2477, rekvId: 63, kond: 1 }, '2026-10-09');
        state.status = 'COMPLETED';
        state.tasks.getEarved.status = 'SUCCESS';
        state.tasks.getEarved.started_at = '2026-10-09T02:00:00.000Z';
        state.tasks.getEarved.finished_at = '2026-10-09T02:05:00.000Z';
        state.tasks.sendFinBitReport.status = 'SUCCESS';
        state.tasks.sendFinBitReport.finished_at = '2026-10-09T02:10:00.000Z';
        fs.writeFileSync(file, JSON.stringify(state, null, 2), 'utf-8');

        const client = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server' },
          jest.fn().mockImplementation(async () => ({
            ok: true,
            status: 200,
            json: async () => ({ status: 200, result: 1, data: [] }),
          })) as unknown as typeof fetch
        );

        // 21:30 UTC 2026-10-09 = 00:30 2026-10-10 в Europe/Tallinn (UTC+3)
        // targetDateStr намеренно НЕ передаётся
        await runOrchestratorTick(
          { stateFilePath: file },
          {
            apiClient: client,
            currentDate: new Date('2026-10-09T21:30:00.000Z'),
            timezone: 'Europe/Tallinn',
            forceRun: false,
          }
        );

        const reloaded: OrchestratorState = JSON.parse(fs.readFileSync(file, 'utf-8'));
        expect(reloaded.tasks.getEarved.status).toBe('PENDING');
        expect(reloaded.tasks.sendFinBitReport.status).toBe('PENDING');
        const rearmEvent = reloaded.history.find(
          (h) => h.event === 'TASK_REARMED' && h.task === 'getEarved'
        );
        expect(rearmEvent?.details).toContain('2026-10-10');
      } finally {
        if (fs.existsSync(file)) {
          try {
            fs.unlinkSync(file);
          } catch {}
        }
      }
    });

    it('закрывает зависший вчерашний цикл IN_PROGRESS при смене суток (CYCLE_CLOSED_DAY_CHANGE)', async () => {
      const file = testStatePath('state_cycle_close_day_change_test.json');
      try {
        const stateManager = new StateManager(file);
        const state = await stateManager.loadState({ userId: 2477, rekvId: 63, kond: 1 }, '2026-10-08');
        state.cycle_date = '2026-10-08';
        state.status = 'IN_PROGRESS';
        state.next_scheduled_run = '2026-10-09T02:00:00.000Z';
        state.tasks.lisa1_lisa5.status = 'FAILED';
        state.tasks.lisa1_lisa5.error = 'TASK_TIMEOUT';
        state.tasks.getEarved.status = 'SUCCESS';
        state.tasks.getEarved.finished_at = '2026-10-08T04:05:00.000Z';
        fs.writeFileSync(file, JSON.stringify(state, null, 2), 'utf-8');

        const client = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server' },
          jest.fn().mockImplementation(async () => ({
            ok: true,
            status: 200,
            json: async () => ({ status: 200, result: 1, data: [] }),
          })) as unknown as typeof fetch
        );

        // 00:10 по Таллину 2026-10-09 (21:10 UTC 2026-10-08)
        await runOrchestratorTick(
          { stateFilePath: file },
          {
            apiClient: client,
            currentDate: new Date('2026-10-08T21:10:00.000Z'),
            timezone: 'Europe/Tallinn',
            forceRun: false,
          }
        );

        const reloaded: OrchestratorState = JSON.parse(fs.readFileSync(file, 'utf-8'));
        expect(reloaded.status).toBe('FAILED');
        const closeEvent = reloaded.history.find((h) => h.event === 'CYCLE_CLOSED_DAY_CHANGE');
        expect(closeEvent).toBeDefined();
        expect(closeEvent?.details).toContain('2026-10-08');
        expect(closeEvent?.details).toContain('2026-10-09');
      } finally {
        if (fs.existsSync(file)) {
          try {
            fs.unlinkSync(file);
          } catch {}
        }
      }
    });
  });

  describe('Каскадное перевооружение и транзитивный Downstream Lock (task_cascade_rearm_gaps)', () => {
    it('(А) зависимая задача, бывшая RUNNING в момент перевооружения родителя, перевооружается в следующем тике после завершения', async () => {
      const file = testStatePath('test_cascade_rearm_after_running.json');
      try {
        const stateManager = new StateManager(file);
        const state = await stateManager.loadState({ userId: 2477, rekvId: 63, kond: 1 }, '2026-10-09');
        state.cycle_date = '2026-10-09';
        state.status = 'IN_PROGRESS';

        // Родитель getEarved уже был выполнен вчера, а зависимая import_earved ещё RUNNING со вчерашнего запуска
        state.tasks.getEarved.status = 'SUCCESS';
        state.tasks.getEarved.started_at = '2026-10-08T23:50:00.000Z';
        state.tasks.getEarved.finished_at = '2026-10-08T23:52:00.000Z';
        state.tasks.getEarved.log_id = 5001;

        state.tasks.check_asutus.status = 'SUCCESS';
        state.tasks.check_asutus.started_at = '2026-10-08T23:52:30.000Z';
        state.tasks.check_asutus.finished_at = '2026-10-08T23:53:00.000Z';
        state.tasks.check_asutus.log_id = 5002;

        state.tasks.import_earved.status = 'RUNNING';
        state.tasks.import_earved.started_at = '2026-10-08T23:55:00.000Z';
        state.tasks.import_earved.log_id = 5003;

        fs.writeFileSync(file, JSON.stringify(state, null, 2), 'utf-8');

        let importRunning = true;
        const client = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server' },
          jest.fn().mockImplementation(async () => {
            return {
              ok: true,
              status: 200,
              json: async () => ({
                result: 1,
                data: [
                  importRunning
                    ? {
                        id: 5003,
                        flow: 'docs.sp_loe_earved',
                        status: null,
                        exec_start: '2026-10-08T23:55:00.000Z',
                        exec_end: null,
                      }
                    : {
                        id: 5003,
                        flow: 'docs.sp_loe_earved',
                        status: 'success',
                        exec_start: '2026-10-08T23:55:00.000Z',
                        exec_end: '2026-10-09T03:01:00.000Z',
                      },
                ],
              }),
            };
          }) as unknown as typeof fetch
        );

        const emptyRegistry = {
          getEarved: { flow: 'getEarved', dispatch: jest.fn().mockResolvedValue(6001) },
          check_asutus: { flow: 'checkAsutusAvailability', dispatch: jest.fn().mockResolvedValue(6002) },
          import_earved: { flow: 'docs.sp_loe_earved', dispatch: jest.fn().mockResolvedValue(6003) },
        };

        // Тик 1: ручной сброс getEarved, пока import_earved в RUNNING (должна пропуститься в тике 1)
        await runOrchestratorTick(
          { stateFilePath: file, taskKey: 'getEarved' },
          {
            apiClient: client,
            currentDate: new Date('2026-10-09T03:00:00.000Z'),
            targetDateStr: '2026-10-09',
            timezone: 'Europe/Tallinn',
            registry: emptyRegistry,
          }
        );

        const afterTick1: OrchestratorState = JSON.parse(fs.readFileSync(file, 'utf-8'));
        expect(afterTick1.tasks.import_earved.status).toBe('RUNNING');

        // Тик 2: import_earved завершается (становится SUCCESS от вчерашнего запуска)
        importRunning = false;
        await runOrchestratorTick(
          { stateFilePath: file },
          {
            apiClient: client,
            currentDate: new Date('2026-10-09T03:02:00.000Z'),
            targetDateStr: '2026-10-09',
            timezone: 'Europe/Tallinn',
            registry: emptyRegistry,
          }
        );

        // Тик 3: следующий тик — rearmedKeys из тика 1 уже нет, но import_earved должен перевооружиться каскадом
        await runOrchestratorTick(
          { stateFilePath: file },
          {
            apiClient: client,
            currentDate: new Date('2026-10-09T03:05:00.000Z'),
            targetDateStr: '2026-10-09',
            timezone: 'Europe/Tallinn',
            registry: emptyRegistry,
          }
        );

        const afterTick3: OrchestratorState = JSON.parse(fs.readFileSync(file, 'utf-8'));
        expect(afterTick3.tasks.import_earved.status).toBe('PENDING');
        expect(afterTick3.tasks.import_earved.log_id).toBeNull();
        expect(
          afterTick3.history.some((h) => h.event === 'TASK_REARMED' && h.task === 'import_earved')
        ).toBe(true);
      } finally {
        if (fs.existsSync(file)) {
          try {
            fs.unlinkSync(file);
          } catch {}
        }
      }
    });

    it('(Б) транзитивный Downstream Lock: родитель getEarved не запускается и не перевооружается, пока внук sendFinBitReport в RUNNING', async () => {
      const file = testStatePath('test_transitive_downstream_lock.json');
      try {
        const stateManager = new StateManager(file);
        const state = await stateManager.loadState({ userId: 2477, rekvId: 63, kond: 1 }, '2026-10-08');
        state.cycle_date = '2026-10-08';
        state.status = 'IN_PROGRESS';

        state.tasks.getEarved.status = 'PENDING';
        state.tasks.check_asutus.status = 'SUCCESS';
        state.tasks.import_earved.status = 'SUCCESS';
        state.tasks.sendFinBitReport.status = 'RUNNING';
        state.tasks.sendFinBitReport.started_at = '2026-10-08T23:55:00.000Z';
        state.tasks.sendFinBitReport.log_id = 7001;

        // 1) evaluateTaskLaunchDecision для getEarved должен вернуть WAIT из-за внука sendFinBitReport
        const decision = await evaluateTaskLaunchDecision(
          'getEarved',
          state.tasks.getEarved,
          state,
          new Date('2026-10-09T06:00:00.000Z'),
          5,
          false,
          undefined,
          undefined,
          '05:00',
          'Europe/Tallinn'
        );
        expect(decision.action).toBe('WAIT');
        expect(decision.should_run).toBe(false);
        expect(decision.reason).toContain('sendFinBitReport');

        // 2) runOrchestratorTick: если getEarved был SUCCESS вчера, он НЕ должен перевооружаться при смене суток, пока внук RUNNING
        state.tasks.getEarved.status = 'SUCCESS';
        state.tasks.getEarved.started_at = '2026-10-08T05:00:00.000Z';
        state.tasks.getEarved.finished_at = '2026-10-08T05:05:00.000Z';
        state.tasks.getEarved.schedule = { time: '05:00' };
        fs.writeFileSync(file, JSON.stringify(state, null, 2), 'utf-8');

        const client = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server' },
          jest.fn().mockImplementation(async () => ({
            ok: true,
            status: 200,
            json: async () => ({
              status: 200,
              result: [{ id: 7001, status: 'running', exec_start: '2026-10-08T23:55:00.000Z' }],
            }),
          })) as unknown as typeof fetch
        );

        await runOrchestratorTick(
          { stateFilePath: file },
          {
            apiClient: client,
            currentDate: new Date('2026-10-09T03:00:00.000Z'),
            targetDateStr: '2026-10-09',
            timezone: 'Europe/Tallinn',
          }
        );

        const reloaded: OrchestratorState = JSON.parse(fs.readFileSync(file, 'utf-8'));
        expect(reloaded.tasks.getEarved.status).toBe('SUCCESS');
        expect(reloaded.history.some((h) => h.event === 'TASK_REARMED' && h.task === 'getEarved')).toBe(false);
      } finally {
        if (fs.existsSync(file)) {
          try {
            fs.unlinkSync(file);
          } catch {}
        }
      }
    });

    it('(В) TASK_REARMED (по расписанию и каскадный) очищает закешированный params.logId', async () => {
      const file = testStatePath('test_rearm_clears_params_logid.json');
      try {
        const stateManager = new StateManager(file);
        const state = await stateManager.loadState({ userId: 2477, rekvId: 63, kond: 1 }, '2026-10-08');
        state.cycle_date = '2026-10-08';
        state.status = 'IN_PROGRESS';
        // Независимая задача RUNNING не даёт сработать resetCycleForNewDay, поэтому работает только TASK_REARMED
        state.tasks.saldoandmik.status = 'RUNNING';
        state.tasks.saldoandmik.started_at = '2026-10-09T01:00:00.000Z';

        state.tasks.getEarved.status = 'SUCCESS';
        state.tasks.getEarved.finished_at = '2026-10-08T07:15:00.000Z';
        state.tasks.getEarved.log_id = 10101;
        state.tasks.getEarved.params = { ...state.tasks.getEarved.params, logId: 88888 };

        state.tasks.sendFinBitReport.status = 'SUCCESS';
        state.tasks.sendFinBitReport.finished_at = '2026-10-08T07:20:00.000Z';
        state.tasks.sendFinBitReport.log_id = 10102;
        state.tasks.sendFinBitReport.params = { ...state.tasks.sendFinBitReport.params, logId: 99999 };

        fs.writeFileSync(file, JSON.stringify(state, null, 2), 'utf-8');

        const client = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server' },
          jest.fn().mockImplementation(async () => ({
            ok: true,
            status: 200,
            json: async () => ({ status: 200, result: 1 }),
          })) as unknown as typeof fetch
        );

        await runOrchestratorTick(
          { stateFilePath: file },
          {
            apiClient: client,
            // 04:30 по Таллину (до 05:00): срабатывает TASK_REARMED без resetCycleForNewDay
            currentDate: new Date('2026-10-09T01:30:00.000Z'),
            targetDateStr: '2026-10-09',
            timezone: 'Europe/Tallinn',
            forceRun: false,
          }
        );

        const reloaded: OrchestratorState = JSON.parse(fs.readFileSync(file, 'utf-8'));
        expect(reloaded.tasks.getEarved.status).toBe('PENDING');
        expect(reloaded.tasks.getEarved.params?.logId).toBeUndefined();
        expect('logId' in (reloaded.tasks.getEarved.params || {})).toBe(false);

        expect(reloaded.tasks.sendFinBitReport.status).toBe('PENDING');
        expect(reloaded.tasks.sendFinBitReport.params?.logId).toBeUndefined();
        expect('logId' in (reloaded.tasks.sendFinBitReport.params || {})).toBe(false);
      } finally {
        if (fs.existsSync(file)) {
          try {
            fs.unlinkSync(file);
          } catch {}
        }
      }
    });
  });

  describe('Локальная таймзона вне тика (task_full_mode_utc_dates)', () => {
    it('calculateNextScheduledRun вычисляет следующий запуск по Europe/Tallinn (лето UTC+3 и зима UTC+2)', () => {
      // Лето (EEST, UTC+3): 2026-10-09 05:00 Tallinn -> 02:00Z
      expect(calculateNextScheduledRun('2026-10-08', 5, 0, 'Europe/Tallinn')).toBe('2026-10-09T02:00:00.000Z');
      // Зима (EET, UTC+2): 2026-01-16 05:00 Tallinn -> 03:00Z
      expect(calculateNextScheduledRun('2026-01-15', 5, 0, 'Europe/Tallinn')).toBe('2026-01-16T03:00:00.000Z');
    });

    it('resetCycleForNewDay учитывает переданную timezone при проверке finished_at', () => {
      const state = createInitialState('2026-10-08');
      state.tasks.getEarved.status = 'SUCCESS';
      // 2026-10-08T21:30:00.000Z = 2026-10-09 00:30 Europe/Tallinn, но 2026-10-08 в UTC
      state.tasks.getEarved.finished_at = '2026-10-08T21:30:00.000Z';

      const resetTallinn = resetCycleForNewDay(state, '2026-10-09', undefined, 'Europe/Tallinn');
      expect(resetTallinn.tasks.getEarved.status).toBe('SUCCESS');

      const resetUtc = resetCycleForNewDay(state, '2026-10-09', undefined, 'UTC');
      expect(resetUtc.tasks.getEarved.status).toBe('PENDING');
    });

    it('runOrchestrator (--full) вычисляет дату запуска по Europe/Tallinn, а не по UTC-срезу', async () => {
      const seenUrls: string[] = [];
      const mockFetch = jest.fn().mockImplementation(async (url: string, init?: RequestInit) => {
        seenUrls.push(`${url} ${String(init?.body || '')}`);
        if (url.includes('/task/read_log/')) {
          return {
            ok: true,
            status: 200,
            json: async () => ({
              result: 1,
              data: [
                {
                  id: 1,
                  flow: 'any',
                  status: 'success',
                  exec_start: '2026-10-09T00:05:00.000Z',
                  exec_end: '2026-10-09T00:10:00.000Z',
                },
              ],
            }),
          };
        }
        return { ok: true, status: 200, json: async () => ({ result: 1, data: [] }) };
      });
      const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);

      // 2026-10-08T21:30:00.000Z = 2026-10-09 00:30 по Таллину (в UTC это ещё 2026-10-08)
      const result = await runOrchestrator(
        { userId: 2477, rekvId: 63, kond: 1, forceRun: false },
        {
          apiClient: client,
          currentDate: new Date('2026-10-08T21:30:00.000Z'),
          timezone: 'Europe/Tallinn',
        }
      );

      expect(result.executionDate).toBe('2026-10-09');
    });
  });

  describe('Отчётность по закрытому вчерашнему циклу (task_reporter_closed_cycle_gap)', () => {
    it('после resetCycleForNewDay утренний reporter в 08:00 показывает упавшую вчера задачу как FAILED, а не PENDING', async () => {
      const file = testStatePath('test_reporter_closed_cycle_failed.json');
      const reportMock = generateAndSendReportSubagent as jest.Mock;
      reportMock.mockClear();

      try {
        const state = createInitialState('2026-10-08');
        state.status = 'FAILED';
        state.tasks.lisa1_lisa5.status = 'FAILED';
        state.tasks.lisa1_lisa5.log_id = 9001;
        state.tasks.lisa1_lisa5.started_at = '2026-10-08T17:10:00.000Z';
        state.tasks.lisa1_lisa5.finished_at = '2026-10-08T21:05:00.000Z';
        state.tasks.lisa1_lisa5.error = 'TASK_TIMEOUT';

        // Переход на новый день сбрасывает задачи в PENDING, но сохраняет снимок в last_run
        const resetState = resetCycleForNewDay(
          state,
          '2026-10-09',
          undefined,
          'Europe/Tallinn',
          new Date('2026-10-09T03:00:00.000Z')
        );
        expect(resetState.tasks.lisa1_lisa5.status).toBe('PENDING');
        expect(resetState.tasks.lisa1_lisa5.last_run?.status).toBe('FAILED');
        expect(resetState.tasks.lisa1_lisa5.last_run?.error).toBe('TASK_TIMEOUT');

        // Чтобы в 08:00 не запускались другие задачи, оставим только reporter в PENDING,
        // а lisa1_lisa5 оставим PENDING (будто её время запуска ещё не наступило)
        for (const [k, t] of Object.entries(resetState.tasks)) {
          if (k !== 'reporter' && k !== 'lisa1_lisa5') {
            t.status = 'SUCCESS';
            t.finished_at = '2026-10-09T04:00:00.000Z';
          }
        }
        fs.writeFileSync(file, JSON.stringify(resetState, null, 2), 'utf-8');

        const client = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server' },
          jest.fn().mockImplementation(async () => ({
            ok: true,
            status: 200,
            json: async () => ({ result: 1, data: [] }),
          })) as unknown as typeof fetch
        );

        // 08:00 Europe/Tallinn (05:00 UTC)
        await runOrchestratorTick(
          { stateFilePath: file },
          {
            apiClient: client,
            currentDate: new Date('2026-10-09T05:00:00.000Z'),
            targetDateStr: '2026-10-09',
            timezone: 'Europe/Tallinn',
            forceRun: false,
          }
        );

        expect(reportMock).toHaveBeenCalledTimes(1);
        const reportArg = reportMock.mock.calls[0][0];
        const lisaStep = reportArg.steps.find(
          (s: { stepName: string }) => s.stepName === 'eelarve.salvesta_lisa_1_5_kontrol'
        );
        expect(lisaStep).toBeDefined();
        expect(lisaStep.status).toBe('FAILED');
        expect(lisaStep.error).toBe('TASK_TIMEOUT');
        expect(lisaStep.logId).toBe(9001);
        expect(reportArg.overallSuccess).toBe(false);

        const reloaded: OrchestratorState = JSON.parse(fs.readFileSync(file, 'utf-8'));
        expect(reloaded.tasks.lisa1_lisa5.last_run?.status).toBe('FAILED');
      } finally {
        if (fs.existsSync(file)) {
          try {
            fs.unlinkSync(file);
          } catch {}
        }
      }
    });
  });

  describe('Inforegister batch hash и validatePrerequisites (task_inforegister_batch_agent_hash)', () => {
    it('без INFOREGISTER_HASH задача inforegister получает SKIP до HTTP-вызова, а с hash он не попадает в state/history', async () => {
      const file = testStatePath('test_inforegister_hash_skip.json');
      const prevHash = process.env.INFOREGISTER_HASH;
      try {
        delete process.env.INFOREGISTER_HASH;
        const stateManager = new StateManager(file);
        const state = await stateManager.loadState({ userId: 2477, rekvId: 63, kond: 1 }, '2026-10-09');
        state.cycle_date = '2026-10-09';
        state.status = 'IN_PROGRESS';
        state.tasks.getEarved.status = 'SUCCESS';
        state.tasks.getEarved.finished_at = '2026-10-09T02:05:00.000Z';
        state.tasks.check_asutus.status = 'SUCCESS';
        state.tasks.check_asutus.finished_at = '2026-10-09T02:06:00.000Z';
        state.tasks.check_asutus.log_id = 555;
        state.tasks.inforegister.status = 'PENDING';
        fs.writeFileSync(file, JSON.stringify(state, null, 2), 'utf-8');

        const mockFetch = jest.fn();
        const client = new ApiClient({ buh70ApiBaseUrl: 'http://test-server' }, mockFetch as unknown as typeof fetch);

        await runOrchestratorTick(
          { stateFilePath: file, taskKey: 'inforegister' },
          {
            apiClient: client,
            currentDate: new Date('2026-10-09T02:10:00.000Z'),
            targetDateStr: '2026-10-09',
            timezone: 'Europe/Tallinn',
          }
        );

        const afterSkip: OrchestratorState = JSON.parse(fs.readFileSync(file, 'utf-8'));
        expect(afterSkip.tasks.inforegister.status).toBe('SKIPPED');
        expect(afterSkip.tasks.inforegister.error).toBe('INFOREGISTER_HASH puudub');
        expect(afterSkip.tasks.inforegister.attempts).toBe(0);
        expect(mockFetch).not.toHaveBeenCalled();

        // С валидным INFOREGISTER_HASH: запуск проходит, но сам секрет не попадает в state/params/history
        const secretHash = 'super-secret-inforegister-hash-123';
        process.env.INFOREGISTER_HASH = secretHash;
        const authClient = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server' },
          jest.fn().mockImplementation(async (u: string) => {
            if (u.includes('/task/getInforegister/')) {
              return {
                ok: true,
                status: 200,
                json: async () => ({ status: 200, result: 1, log_id: 7777 }),
              };
            }
            return { ok: true, status: 200, json: async () => ({ result: 1, data: [] }) };
          }) as unknown as typeof fetch
        );

        await runOrchestratorTick(
          { stateFilePath: file, taskKey: 'inforegister' },
          {
            apiClient: authClient,
            currentDate: new Date('2026-10-09T02:15:00.000Z'),
            targetDateStr: '2026-10-09',
            timezone: 'Europe/Tallinn',
          }
        );

        const rawSaved = fs.readFileSync(file, 'utf-8');
        expect(rawSaved).not.toContain(secretHash);
        const afterRun: OrchestratorState = JSON.parse(rawSaved);
        expect(afterRun.tasks.inforegister.status).toBe('RUNNING');
        expect(afterRun.tasks.inforegister.log_id).toBe(7777);
      } finally {
        if (prevHash === undefined) {
          delete process.env.INFOREGISTER_HASH;
        } else {
          process.env.INFOREGISTER_HASH = prevHash;
        }
        if (fs.existsSync(file)) {
          try {
            fs.unlinkSync(file);
          } catch {}
        }
      }
    });
  });

  describe('last_run: отчёт после перевооружения (task_report_last_run_snapshot)', () => {
    it('(а) saldoandmik и lisa1_lisa5 SUCCESS вечером D -> TASK_REARMED в 00:05 D+1 -> reporter в 08:00 D+1 показывает оба шага SUCCESS с log_id', async () => {
      const file = testStatePath('test_last_run_rearm_report.json');
      const reportMock = generateAndSendReportSubagent as jest.Mock;
      reportMock.mockClear();

      try {
        const state = createInitialState('2026-10-08');
        state.status = 'COMPLETED';
        state.next_scheduled_run = '2026-10-09T02:00:00.000Z';

        // 20:10 и 20:40 Europe/Tallinn (17:10 и 17:40 UTC)
        state.tasks.saldoandmik.status = 'SUCCESS';
        state.tasks.saldoandmik.schedule = { time: '20:00' };
        state.tasks.saldoandmik.log_id = 1001;
        state.tasks.saldoandmik.started_at = '2026-10-08T17:00:00.000Z';
        state.tasks.saldoandmik.finished_at = '2026-10-08T17:10:00.000Z';
        state.tasks.saldoandmik.duration_ms = 600000;

        state.tasks.lisa1_lisa5.status = 'SUCCESS';
        state.tasks.lisa1_lisa5.log_id = 1002;
        state.tasks.lisa1_lisa5.started_at = '2026-10-08T17:30:00.000Z';
        state.tasks.lisa1_lisa5.finished_at = '2026-10-08T17:40:00.000Z';
        state.tasks.lisa1_lisa5.duration_ms = 600000;

        // Остальные задачи уже SUCCESS, reporter PENDING до 08:00
        for (const [k, t] of Object.entries(state.tasks)) {
          if (k !== 'saldoandmik' && k !== 'lisa1_lisa5' && k !== 'reporter') {
            t.status = 'SUCCESS';
            t.finished_at = '2026-10-08T18:00:00.000Z';
          }
        }
        fs.writeFileSync(file, JSON.stringify(state, null, 2), 'utf-8');

        const client = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server' },
          jest.fn().mockImplementation(async (url: string, init?: RequestInit) => {
            const body = init?.body ? JSON.parse(String(init.body)) : {};
            if (url.includes('/task/read_log/')) {
              if (body.log_id === 1001) {
                return {
                  ok: true,
                  status: 200,
                  json: async () => ({
                    result: 1,
                    data: [
                      {
                        id: 1001,
                        flow: 'eelarve.sp_koosta_saldoandmik',
                        status: 'success',
                        exec_start: '2026-10-08T17:00:00.000Z',
                        exec_end: '2026-10-08T17:10:00.000Z',
                      },
                    ],
                  }),
                };
              }
              if (body.log_id === 1002) {
                return {
                  ok: true,
                  status: 200,
                  json: async () => ({
                    result: 1,
                    data: [
                      {
                        id: 1002,
                        flow: 'eelarve.salvesta_lisa_1_5_kontrol',
                        status: 'success',
                        exec_start: '2026-10-08T17:30:00.000Z',
                        exec_end: '2026-10-08T17:40:00.000Z',
                      },
                    ],
                  }),
                };
              }
            }
            return { ok: true, status: 200, json: async () => ({ result: 1, data: [] }) };
          }) as unknown as typeof fetch
        );

        // Тик 1: 00:05 Europe/Tallinn 2026-10-09 (21:05 UTC 2026-10-08) -> TASK_REARMED
        await runOrchestratorTick(
          { stateFilePath: file },
          {
            apiClient: client,
            currentDate: new Date('2026-10-08T21:05:00.000Z'),
            timezone: 'Europe/Tallinn',
            forceRun: false,
          }
        );

        const afterMidnight: OrchestratorState = JSON.parse(fs.readFileSync(file, 'utf-8'));
        expect(afterMidnight.tasks.saldoandmik.status).toBe('PENDING');
        expect(afterMidnight.tasks.lisa1_lisa5.status).toBe('PENDING');

        // Тик 2: 08:00 Europe/Tallinn 2026-10-09 (05:00 UTC) -> reporter
        // Остальные задачи пометим SUCCESS сегодня, чтобы в 08:00 не запускались
        for (const [k, t] of Object.entries(afterMidnight.tasks)) {
          if (k !== 'saldoandmik' && k !== 'lisa1_lisa5' && k !== 'reporter') {
            t.status = 'SUCCESS';
            t.finished_at = '2026-10-09T04:00:00.000Z';
          }
        }
        afterMidnight.cycle_date = '2026-10-09';
        afterMidnight.status = 'IN_PROGRESS';
        fs.writeFileSync(file, JSON.stringify(afterMidnight, null, 2), 'utf-8');

        await runOrchestratorTick(
          { stateFilePath: file },
          {
            apiClient: client,
            currentDate: new Date('2026-10-09T05:00:00.000Z'),
            targetDateStr: '2026-10-09',
            timezone: 'Europe/Tallinn',
            forceRun: false,
          }
        );

        expect(reportMock).toHaveBeenCalledTimes(1);
        const reportArg = reportMock.mock.calls[0][0];
        const saldoStep = reportArg.steps.find(
          (s: { stepName: string }) => s.stepName === 'eelarve.sp_koosta_saldoandmik'
        );
        const lisaStep = reportArg.steps.find(
          (s: { stepName: string }) => s.stepName === 'eelarve.salvesta_lisa_1_5_kontrol'
        );

        expect(saldoStep?.status).toBe('SUCCESS');
        expect(saldoStep?.logId).toBe(1001);
        expect(saldoStep?.execStart).toBe('2026-10-08T17:00:00.000Z');
        expect(lisaStep?.status).toBe('SUCCESS');
        expect(lisaStep?.logId).toBe(1002);
        expect(lisaStep?.execStart).toBe('2026-10-08T17:30:00.000Z');
      } finally {
        if (fs.existsSync(file)) {
          try {
            fs.unlinkSync(file);
          } catch {}
        }
      }
    });

    it('(б, в) CYCLE_CLOSED_DAY_CHANGE + resetCycleForNewDay сохраняет last_run для SUCCESS и FAILED', () => {
      const state = createInitialState('2026-10-08');
      state.status = 'FAILED';
      state.tasks.saldoandmik.status = 'SUCCESS';
      state.tasks.saldoandmik.log_id = 2001;
      state.tasks.saldoandmik.started_at = '2026-10-08T17:00:00.000Z';
      state.tasks.saldoandmik.finished_at = '2026-10-08T17:10:00.000Z';

      state.tasks.lisa1_lisa5.status = 'FAILED';
      state.tasks.lisa1_lisa5.log_id = 2002;
      state.tasks.lisa1_lisa5.started_at = '2026-10-08T17:20:00.000Z';
      state.tasks.lisa1_lisa5.finished_at = '2026-10-08T17:30:00.000Z';
      state.tasks.lisa1_lisa5.error = 'SQL_FAIL';

      const resetState = resetCycleForNewDay(
        state,
        '2026-10-09',
        undefined,
        'Europe/Tallinn',
        new Date('2026-10-09T00:10:00.000Z')
      );

      expect(resetState.tasks.saldoandmik.status).toBe('PENDING');
      expect(resetState.tasks.saldoandmik.last_run).toMatchObject({
        log_id: 2001,
        status: 'SUCCESS',
        cycle_date: '2026-10-08',
        reset_reason: 'CYCLE_RESET_NEW_DAY',
      });
      expect(resetState.tasks.lisa1_lisa5.status).toBe('PENDING');
      expect(resetState.tasks.lisa1_lisa5.last_run).toMatchObject({
        log_id: 2002,
        status: 'FAILED',
        error: 'SQL_FAIL',
        reset_reason: 'CYCLE_RESET_NEW_DAY',
      });
    });

    it('(г, д, ж) окно 24ч, приоритет текущего запуска с log_id и fallback на поля last_run при ошибке API', async () => {
      const file = testStatePath('test_last_run_window_fallback.json');
      const reportMock = generateAndSendReportSubagent as jest.Mock;
      reportMock.mockClear();

      try {
        const state = createInitialState('2026-10-09');
        state.status = 'IN_PROGRESS';

        // 1) saldoandmik: last_run старше 24ч -> в отчёте должен быть PENDING ('Pooleli')
        state.tasks.saldoandmik.status = 'PENDING';
        state.tasks.saldoandmik.last_run = {
          log_id: 3001,
          status: 'SUCCESS',
          started_at: '2026-10-07T17:00:00.000Z',
          finished_at: '2026-10-07T17:10:00.000Z',
          duration_ms: 600000,
          error: null,
          cycle_date: '2026-10-07',
          reset_at: '2026-10-08T00:00:00.000Z',
          reset_reason: 'TASK_REARMED',
        };

        // 2) lisa1_lisa5: свежий last_run, но API readTaskLog падает -> шаг строится из полей last_run
        state.tasks.lisa1_lisa5.status = 'PENDING';
        state.tasks.lisa1_lisa5.last_run = {
          log_id: 3002,
          status: 'SUCCESS',
          started_at: '2026-10-08T17:30:00.000Z',
          finished_at: '2026-10-08T17:40:00.000Z',
          duration_ms: 600000,
          error: null,
          result_summary: 'Valmis (last_run)',
          cycle_date: '2026-10-08',
          reset_at: '2026-10-09T00:00:00.000Z',
          reset_reason: 'TASK_REARMED',
        };

        // 3) calc_arv_jaak: запущена заново сегодня (есть текущий log_id 4001) -> текущий запуск важнее last_run
        state.tasks.calc_arv_jaak.status = 'SUCCESS';
        state.tasks.calc_arv_jaak.log_id = 4001;
        state.tasks.calc_arv_jaak.started_at = '2026-10-09T04:30:00.000Z';
        state.tasks.calc_arv_jaak.finished_at = '2026-10-09T04:31:00.000Z';
        state.tasks.calc_arv_jaak.last_run = {
          log_id: 3003,
          status: 'FAILED',
          started_at: '2026-10-08T17:00:00.000Z',
          finished_at: '2026-10-08T17:05:00.000Z',
          duration_ms: 300000,
          error: 'OLD_ERROR',
          cycle_date: '2026-10-08',
          reset_at: '2026-10-09T00:00:00.000Z',
          reset_reason: 'TASK_REARMED',
        };

        for (const [k, t] of Object.entries(state.tasks)) {
          if (k !== 'saldoandmik' && k !== 'lisa1_lisa5' && k !== 'calc_arv_jaak' && k !== 'reporter') {
            t.status = 'SUCCESS';
            t.finished_at = '2026-10-09T04:00:00.000Z';
          }
        }
        fs.writeFileSync(file, JSON.stringify(state, null, 2), 'utf-8');

        const client = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server' },
          jest.fn().mockImplementation(async (_url: string, init?: RequestInit) => {
            const body = init?.body ? JSON.parse(String(init.body)) : {};
            if (body.log_id === 3002) {
              return { ok: false, status: 500, statusText: 'Err', text: async () => 'db down' };
            }
            if (body.log_id === 4001) {
              return {
                ok: true,
                status: 200,
                json: async () => ({
                  result: 1,
                  data: [
                    {
                      id: 4001,
                      flow: 'docs.check_arv_jaak',
                      status: 'success',
                      exec_start: '2026-10-09T04:30:00.000Z',
                      exec_end: '2026-10-09T04:31:00.000Z',
                    },
                  ],
                }),
              };
            }
            return { ok: true, status: 200, json: async () => ({ result: 1, data: [] }) };
          }) as unknown as typeof fetch
        );

        await runOrchestratorTick(
          { stateFilePath: file },
          {
            apiClient: client,
            currentDate: new Date('2026-10-09T05:00:00.000Z'),
            targetDateStr: '2026-10-09',
            timezone: 'Europe/Tallinn',
            forceRun: false,
          }
        );

        expect(reportMock).toHaveBeenCalledTimes(1);
        const steps = reportMock.mock.calls[0][0].steps;
        const saldoStep = steps.find((s: { stepName: string }) => s.stepName === 'eelarve.sp_koosta_saldoandmik');
        const lisaStep = steps.find((s: { stepName: string }) => s.stepName === 'eelarve.salvesta_lisa_1_5_kontrol');
        const calcStep = steps.find((s: { stepName: string }) => s.stepName === 'docs.check_arv_jaak');

        expect(saldoStep.status).toBe('PENDING');
        expect(lisaStep).toMatchObject({
          status: 'SUCCESS',
          logId: 3002,
          resultSummary: 'Valmis (last_run)',
        });
        expect(calcStep).toMatchObject({
          status: 'SUCCESS',
          logId: 4001,
        });
      } finally {
        if (fs.existsSync(file)) {
          try {
            fs.unlinkSync(file);
          } catch {}
        }
      }
    });

    it('(е, з, и) повторный сброс PENDING не стирает last_run, старый state с previous_cycle_failures мигрирует, last_run не блокирует запуск в 20:00', async () => {
      const file = testStatePath('test_last_run_migration_and_launch.json');
      try {
        const stateManager = new StateManager(file);
        const state = createInitialState('2026-10-09');
        // Симулируем старый формат state с previous_cycle_failures
        const legacyRaw: any = {
          ...state,
          previous_cycle_failures: {
            lisa1_lisa5: {
              cycle_date: '2026-10-08',
              log_id: 5001,
              started_at: '2026-10-08T17:30:00.000Z',
              finished_at: '2026-10-08T17:40:00.000Z',
              duration_ms: 600000,
              error: 'LEGACY_ERR',
            },
          },
        };
        fs.writeFileSync(file, JSON.stringify(legacyRaw, null, 2), 'utf-8');

        const loaded = await stateManager.loadState();
        expect((loaded as any).previous_cycle_failures).toBeUndefined();
        expect(loaded.tasks.lisa1_lisa5.last_run).toMatchObject({
          status: 'FAILED',
          log_id: 5001,
          error: 'LEGACY_ERR',
          reset_reason: 'CYCLE_RESET_NEW_DAY',
        });

        // Повторный сброс PENDING-задачи без log_id/started_at не стирает last_run
        const resetAgain = resetCycleForNewDay(loaded, '2026-10-10', undefined, 'Europe/Tallinn');
        expect(resetAgain.tasks.lisa1_lisa5.last_run?.log_id).toBe(5001);

        // last_run со статусом SUCCESS не мешает evaluateTaskLaunchDecision запустить saldoandmik в 20:00
        loaded.tasks.saldoandmik.status = 'PENDING';
        loaded.tasks.saldoandmik.schedule = { time: '20:00' };
        loaded.tasks.saldoandmik.last_run = {
          log_id: 5002,
          status: 'SUCCESS',
          started_at: '2026-10-08T17:00:00.000Z',
          finished_at: '2026-10-08T17:10:00.000Z',
          duration_ms: 600000,
          error: null,
          cycle_date: '2026-10-08',
          reset_at: '2026-10-09T00:00:00.000Z',
          reset_reason: 'TASK_REARMED',
        };
        const decision = await evaluateTaskLaunchDecision(
          'saldoandmik',
          loaded.tasks.saldoandmik,
          loaded,
          new Date('2026-10-09T17:05:00.000Z'), // 20:05 Tallinn
          20,
          false,
          undefined,
          undefined,
          '20:00',
          'Europe/Tallinn'
        );
        expect(decision.should_run).toBe(true);
        expect(decision.action).toBe('RUN');
      } finally {
        if (fs.existsSync(file)) {
          try {
            fs.unlinkSync(file);
          } catch {}
        }
      }
    });
  });

  describe('Мягкие зависимости soft_depends_on (task_soft_dependency_inforegister)', () => {
    it('(а) inforegister SKIPPED -> import_earved стартует -> sendFinBitReport стартует после него', async () => {
      const file = testStatePath('test_soft_dep_inforegister_skip.json');
      try {
        const stateManager = new StateManager(file);
        const state = await stateManager.loadState({ userId: 2477, rekvId: 63, kond: 1 }, '2026-10-09');
        state.cycle_date = '2026-10-09';
        state.status = 'IN_PROGRESS';

        state.tasks.getEarved.status = 'SUCCESS';
        state.tasks.getEarved.log_id = 101;
        state.tasks.getEarved.finished_at = '2026-10-09T02:05:00.000Z';

        state.tasks.check_asutus.status = 'SUCCESS';
        state.tasks.check_asutus.log_id = 102;
        state.tasks.check_asutus.finished_at = '2026-10-09T02:06:00.000Z';

        state.tasks.inforegister.status = 'SKIPPED';
        state.tasks.inforegister.error = 'INFOREGISTER_HASH puudub';
        state.tasks.inforegister.finished_at = '2026-10-09T02:07:00.000Z';

        state.tasks.import_earved.status = 'PENDING';
        state.tasks.sendFinBitReport.status = 'PENDING';
        for (const [k, t] of Object.entries(state.tasks)) {
          if (!['getEarved', 'check_asutus', 'inforegister', 'import_earved', 'sendFinBitReport'].includes(k)) {
            t.status = 'SUCCESS';
            t.finished_at = '2026-10-09T02:00:00.000Z';
          }
        }
        fs.writeFileSync(file, JSON.stringify(state, null, 2), 'utf-8');

        const dispatched: string[] = [];
        const testRegistry = {
          import_earved: {
            dispatch: jest.fn().mockImplementation(async () => {
              dispatched.push('import_earved');
              return 103;
            }),
            resolveParentParams: (s: OrchestratorState) => ({ logId: s.tasks.getEarved.log_id }),
          },
          sendFinBitReport: {
            dispatch: jest.fn().mockImplementation(async () => {
              dispatched.push('sendFinBitReport');
              return 104;
            }),
            resolveParentParams: (s: OrchestratorState) => ({ logId: s.tasks.import_earved.log_id }),
          },
        };

        const client = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server' },
          jest.fn().mockImplementation(async () => ({
            ok: true,
            status: 200,
            json: async () => ({
              result: 1,
              data: [
                {
                  id: 103,
                  flow: 'docs.sp_loe_earved',
                  status: 'success',
                  exec_start: '2026-10-09T02:08:00.000Z',
                  exec_end: '2026-10-09T02:08:30.000Z',
                  result: { imported: [{ doc_id: 1, number: 'A-1', rekv_id: 63 }], totalImported: 1 },
                },
              ],
            }),
          })) as unknown as typeof fetch
        );

        // Тик 1: import_earved стартует несмотря на SKIPPED у inforegister
        await runOrchestratorTick(
          { stateFilePath: file },
          {
            apiClient: client,
            currentDate: new Date('2026-10-09T02:08:00.000Z'),
            targetDateStr: '2026-10-09',
            timezone: 'Europe/Tallinn',
            registry: testRegistry,
          }
        );

        const afterTick1: OrchestratorState = JSON.parse(fs.readFileSync(file, 'utf-8'));
        expect(dispatched).toContain('import_earved');
        expect(afterTick1.tasks.import_earved.status).toBe('RUNNING');

        // Тик 2: import_earved завершается SUCCESS -> sendFinBitReport стартует
        await runOrchestratorTick(
          { stateFilePath: file },
          {
            apiClient: client,
            currentDate: new Date('2026-10-09T02:09:00.000Z'),
            targetDateStr: '2026-10-09',
            timezone: 'Europe/Tallinn',
            registry: testRegistry,
          }
        );

        expect(dispatched).toContain('sendFinBitReport');
      } finally {
        if (fs.existsSync(file)) {
          try {
            fs.unlinkSync(file);
          } catch {}
        }
      }
    });

    it('(б, в, г, д) soft_depends_on: ждёт PENDING/RUNNING, стартует при FAILED, но SKIPPED при FAILED жёсткой зависимости', async () => {
      const state = createInitialState('2026-10-09');
      state.tasks.getEarved.status = 'SUCCESS';
      state.tasks.check_asutus.status = 'SUCCESS';

      // (г) inforegister PENDING -> WAIT
      state.tasks.inforegister.status = 'PENDING';
      const dPending = await evaluateTaskLaunchDecision(
        'import_earved',
        state.tasks.import_earved,
        state,
        new Date('2026-10-09T05:00:00.000Z'),
        20,
        false
      );
      expect(dPending.action).toBe('WAIT');
      expect(dPending.reason).toContain('inforegister');

      // (в) inforegister RUNNING -> WAIT
      state.tasks.inforegister.status = 'RUNNING';
      const dRunning = await evaluateTaskLaunchDecision(
        'import_earved',
        state.tasks.import_earved,
        state,
        new Date('2026-10-09T05:00:00.000Z'),
        20,
        false
      );
      expect(dRunning.action).toBe('WAIT');

      // (б) inforegister FAILED -> import_earved стартует
      state.tasks.inforegister.status = 'FAILED';
      const dSoftFailed = await evaluateTaskLaunchDecision(
        'import_earved',
        state.tasks.import_earved,
        state,
        new Date('2026-10-09T05:00:00.000Z'),
        20,
        false
      );
      expect(dSoftFailed.should_run).toBe(true);
      expect(dSoftFailed.action).toBe('RUN');

      // (д) жёсткая зависимость check_asutus FAILED -> SKIP
      state.tasks.check_asutus.status = 'FAILED';
      const dHardFailed = await evaluateTaskLaunchDecision(
        'import_earved',
        state.tasks.import_earved,
        state,
        new Date('2026-10-09T05:00:00.000Z'),
        20,
        false
      );
      expect(dHardFailed.action).toBe('SKIP');
      expect(dHardFailed.should_run).toBe(false);
    });

    it('(е, ж, з, и, к) Downstream Lock, каскад getEarved->import_earved->sendFinBitReport, пометка в отчёте и валидация схемы', async () => {
      // (и) дублирование в depends_on и soft_depends_on -> ошибка валидации
      const { AgentConfigSchema, OrchestratorStateSchema } = require('./orchestrator.schemas');
      expect(() =>
        AgentConfigSchema.parse({
          name: 'bad_agent',
          flow: 'x',
          depends_on: ['a'],
          soft_depends_on: ['a'],
        })
      ).toThrow();

      // (к) state без soft_depends_on загружается совместимо
      const compat = OrchestratorStateSchema.parse({
        cycle_date: '2026-10-09',
        params: { userId: 2477, rekvId: 63, kond: 1 },
        tasks: {
          t1: { flow: 'f1', depends_on: [] },
        },
      });
      expect(compat.tasks.t1.soft_depends_on ?? []).toEqual([]);

      // (е) Downstream Lock: пока import_earved RUNNING, inforegister не запускается (WAIT)
      const state = createInitialState('2026-10-09');
      state.tasks.getEarved.status = 'SUCCESS';
      state.tasks.check_asutus.status = 'SUCCESS';
      state.tasks.inforegister.status = 'PENDING';
      state.tasks.import_earved.status = 'RUNNING';
      const dLock = await evaluateTaskLaunchDecision(
        'inforegister',
        state.tasks.inforegister,
        state,
        new Date('2026-10-09T05:00:00.000Z'),
        20,
        false
      );
      expect(dLock.action).toBe('WAIT');
      expect(dLock.reason).toContain('import_earved');

      // (ж, з) каскадное перевооружение и пометка в отчёте при неуспешной мягкой зависимости
      const file = testStatePath('test_soft_dep_report_note.json');
      const reportMock = generateAndSendReportSubagent as jest.Mock;
      reportMock.mockClear();
      try {
        const s2 = createInitialState('2026-10-08');
        s2.status = 'IN_PROGRESS';
        s2.tasks.getEarved.status = 'SUCCESS';
        s2.tasks.getEarved.finished_at = '2026-10-08T05:05:00.000Z';
        s2.tasks.import_earved.status = 'SUCCESS';
        s2.tasks.import_earved.soft_deps_failed = ['inforegister'];
        s2.tasks.sendFinBitReport.status = 'SUCCESS';
        s2.tasks.saldoandmik.status = 'RUNNING'; // удерживаем цикл от resetCycleForNewDay
        s2.tasks.saldoandmik.started_at = '2026-10-09T01:00:00.000Z';
        fs.writeFileSync(file, JSON.stringify(s2, null, 2), 'utf-8');

        const client = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server' },
          jest.fn().mockResolvedValue({
            ok: true,
            status: 200,
            json: async () => ({ result: 1, data: [] }),
          }) as unknown as typeof fetch
        );

        await runOrchestratorTick(
          { stateFilePath: file },
          {
            apiClient: client,
            currentDate: new Date('2026-10-09T01:30:00.000Z'),
            targetDateStr: '2026-10-09',
            timezone: 'Europe/Tallinn',
          }
        );

        const afterRearm: OrchestratorState = JSON.parse(fs.readFileSync(file, 'utf-8'));
        expect(afterRearm.tasks.import_earved.status).toBe('PENDING');
        expect(afterRearm.tasks.import_earved.soft_deps_failed).toBeUndefined();
        expect(afterRearm.tasks.sendFinBitReport.status).toBe('PENDING');

        // (з) отчёт reporter содержит пометку у import_earved при soft_deps_failed: ['inforegister']
        for (const [k, t] of Object.entries(afterRearm.tasks)) {
          if (k !== 'reporter') {
            t.status = 'SUCCESS';
            t.finished_at = '2026-10-09T04:00:00.000Z';
          }
        }
        afterRearm.cycle_date = '2026-10-09';
        afterRearm.tasks.inforegister.status = 'FAILED';
        afterRearm.tasks.inforegister.error = 'INFOREGISTER_HASH puudub';
        afterRearm.tasks.import_earved.status = 'SUCCESS';
        afterRearm.tasks.import_earved.log_id = 707;
        afterRearm.tasks.import_earved.soft_deps_failed = ['inforegister'];
        fs.writeFileSync(file, JSON.stringify(afterRearm, null, 2), 'utf-8');

        const repClient = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server' },
          jest.fn().mockImplementation(async (_u: string, init?: RequestInit) => {
            const b = init?.body ? JSON.parse(String(init.body)) : {};
            if (b.log_id === 707) {
              return {
                ok: true,
                status: 200,
                json: async () => ({
                  result: 1,
                  data: [
                    {
                      id: 707,
                      flow: 'docs.sp_loe_earved',
                      status: 'success',
                      exec_start: '2026-10-09T03:00:00.000Z',
                      exec_end: '2026-10-09T03:01:00.000Z',
                      result: { imported: [], skipped: [], errors: [] },
                    },
                  ],
                }),
              };
            }
            return { ok: true, status: 200, json: async () => ({ result: 1, data: [] }) };
          }) as unknown as typeof fetch
        );

        await runOrchestratorTick(
          { stateFilePath: file },
          {
            apiClient: repClient,
            currentDate: new Date('2026-10-09T05:00:00.000Z'),
            targetDateStr: '2026-10-09',
            timezone: 'Europe/Tallinn',
          }
        );

        expect(reportMock).toHaveBeenCalledTimes(1);
        const steps = reportMock.mock.calls[0][0].steps;
        const impStep = steps.find((s: { stepName: string }) => s.stepName === 'docs.sp_loe_earved');
        const infoStep = steps.find((s: { stepName: string }) => s.stepName === 'getInforegister');
        expect(impStep.resultSummary).toContain('inforegister ebaõnnestus/vahele jäetud');
        expect(['FAILED', 'SKIPPED']).toContain(infoStep.status);
      } finally {
        if (fs.existsSync(file)) {
          try {
            fs.unlinkSync(file);
          } catch {}
        }
      }
    });
  });

  describe('Приоритет config.json над state для userId/rekvId (task_finbit_service_user_id)', () => {
    it('(а, б, в, г) боевой orchestrator_state.json обновляет userId/rekvId из config.json, сохраняет logId и подставляет userId оркестратора при отсутствии у агента', async () => {
      const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'ai-task-config-owned-'));
      try {
        fs.mkdirSync(path.join(tmpDir, 'orchestrator'), { recursive: true });
        fs.mkdirSync(path.join(tmpDir, 'saldoandmik'), { recursive: true });
        fs.mkdirSync(path.join(tmpDir, 'agent_no_uid'), { recursive: true });

        fs.writeFileSync(
          path.join(tmpDir, 'orchestrator', 'config.json'),
          JSON.stringify({
            name: 'orchestrator',
            params: { userId: 11770, rekvId: 63, kond: 1 },
          }),
          'utf8'
        );
        fs.writeFileSync(
          path.join(tmpDir, 'saldoandmik', 'config.json'),
          JSON.stringify({
            name: 'saldoandmik',
            flow: 'eelarve.sp_koosta_saldoandmik',
            params: { userId: 11770, rekvId: 63, kond: 1 },
          }),
          'utf8'
        );
        fs.writeFileSync(
          path.join(tmpDir, 'agent_no_uid', 'config.json'),
          JSON.stringify({
            name: 'agent_no_uid',
            flow: 'test.agent_no_uid',
            params: {},
          }),
          'utf8'
        );

        const prodStatePath = path.join(tmpDir, 'orchestrator_state.json');
        const oldState = {
          version: 1,
          cycle_date: '2026-10-09',
          status: 'IDLE',
          last_tick_at: null,
          next_scheduled_run: null,
          params: { userId: 2477, rekvId: 99, kond: 1 },
          tasks: {
            saldoandmik: {
              flow: 'eelarve.sp_koosta_saldoandmik',
              depends_on: [],
              allow_parallel: true,
              schedule: null,
              prompt: null,
              params: { userId: 2477, rekvId: 99, kond: 1, logId: 555123 },
              status: 'PENDING',
              attempts: 0,
              max_attempts: 3,
              log_id: null,
              started_at: null,
              finished_at: null,
              duration_ms: null,
              error: null,
            },
            agent_no_uid: {
              flow: 'test.agent_no_uid',
              depends_on: [],
              allow_parallel: true,
              schedule: null,
              prompt: null,
              params: { userId: 2477, rekvId: 99 },
              status: 'PENDING',
              attempts: 0,
              max_attempts: 3,
              log_id: null,
              started_at: null,
              finished_at: null,
              duration_ms: null,
              error: null,
            },
          },
          history: [],
        };
        fs.writeFileSync(prodStatePath, JSON.stringify(oldState, null, 2), 'utf8');

        const manager = new StateManager(prodStatePath);
        const loaded = await manager.loadState({}, '2026-10-09', tmpDir, 'Europe/Tallinn');

        // (а) userId обновлён на 11770 и в задачах, и на уровне цикла
        expect(loaded.params.userId).toBe(11770);
        expect(loaded.tasks.saldoandmik.params?.userId).toBe(11770);
        // (б) динамический logId сохранён
        expect(loaded.tasks.saldoandmik.params?.logId).toBe(555123);
        // (в) rekvId взят из конфига (63), а не из старого state (99)
        expect(loaded.params.rekvId).toBe(63);
        expect(loaded.tasks.saldoandmik.params?.rekvId).toBe(63);
        // (г) агент без userId в своём config.json получает userId из orchestrator/config.json
        expect(loaded.tasks.agent_no_uid.params?.userId).toBe(11770);
        expect(loaded.tasks.agent_no_uid.params?.rekvId).toBe(63);
      } finally {
        fs.rmSync(tmpDir, { recursive: true, force: true });
      }
    });

    it('(д) диспетчеризация задачи и чтение её лога (read_log) используют один и тот же userId, а явный --user не сохраняется в state', async () => {
      const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'ai-task-same-uid-'));
      const stateFile = path.join(tmpDir, 'test_same_uid_state.json');
      try {
        const state: OrchestratorState = {
          version: 1,
          cycle_date: '2026-10-09',
          status: 'IN_PROGRESS',
          last_tick_at: null,
          next_scheduled_run: null,
          params: { userId: 11770, rekvId: 63, kond: 1 },
          tasks: {
            saldoandmik: {
              flow: 'eelarve.sp_koosta_saldoandmik',
              depends_on: [],
              allow_parallel: true,
              schedule: { time: '20:00' },
              prompt: null,
              params: { userId: 11770, rekvId: 63, kond: 1 },
              status: 'PENDING',
              attempts: 0,
              max_attempts: 3,
              log_id: null,
              started_at: null,
              finished_at: null,
              duration_ms: null,
              error: null,
            },
          },
          history: [],
        };
        fs.writeFileSync(stateFile, JSON.stringify(state, null, 2), 'utf8');

        const seenUrls: string[] = [];
        let dispatchedUserId: number | undefined;
        const mockClient = new ApiClient(
          { buh70ApiBaseUrl: 'http://localhost:3000', buh70ApiToken: 't', apiRetryBaseDelayMs: 0 },
          (async (url: string) => {
            seenUrls.push(String(url));
            return { ok: true, status: 200, json: async () => ({ result: 1, data: [] }) };
          }) as unknown as typeof fetch
        );

        const registry = {
          saldoandmik: {
            name: 'saldoandmik',
            dispatch: async (ctx: { userId: number; params: Record<string, unknown> }) => {
              dispatchedUserId = typeof ctx.params.userId === 'number' ? ctx.params.userId : ctx.userId;
              return 77701;
            },
          },
        };

        await runOrchestratorTick(
          { stateFilePath: stateFile },
          {
            apiClient: mockClient,
            registry: registry as any,
            currentDate: new Date('2026-10-09T17:05:00.000Z'), // 20:05 Tallinn
            targetDateStr: '2026-10-09',
            timezone: 'Europe/Tallinn',
          }
        );

        expect(dispatchedUserId).toBe(11770);
        const dupGuardUrl = seenUrls.find((u) => u.includes('/task/read_log/') && u.includes('eelarve.sp_koosta_saldoandmik'));
        expect(dupGuardUrl).toContain('/task/read_log/11770/');

        // Следующий тик проверяет RUNNING задачу тем же userId (11770), даже если передать разовый userId=9999 в другой тик — state.params.userId не меняется
        await runOrchestratorTick(
          { stateFilePath: stateFile, userId: 9999 },
          {
            apiClient: mockClient,
            registry: registry as any,
            currentDate: new Date('2026-10-09T17:10:00.000Z'),
            targetDateStr: '2026-10-09',
            timezone: 'Europe/Tallinn',
          }
        );
        const savedAfter = JSON.parse(fs.readFileSync(stateFile, 'utf8'));
        expect(savedAfter.params.userId).toBe(11770);
        // Задача с params.userId=11770 проверяется под тем же userId=11770, а не под разовым userId=9999
        expect(seenUrls.some((u) => u.includes('/task/read_log/11770/'))).toBe(true);
        expect(seenUrls.some((u) => u.includes('/task/read_log/9999/') && u.includes('eelarve.sp_koosta_saldoandmik'))).toBe(false);
      } finally {
        fs.rmSync(tmpDir, { recursive: true, force: true });
      }
    });

    it('(е) тестовый state-файл (не orchestrator_state.json) не реконсилируется при loadState', async () => {
      const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'ai-task-test-state-'));
      try {
        fs.mkdirSync(path.join(tmpDir, 'orchestrator'), { recursive: true });
        fs.mkdirSync(path.join(tmpDir, 'saldoandmik'), { recursive: true });
        fs.writeFileSync(
          path.join(tmpDir, 'orchestrator', 'config.json'),
          JSON.stringify({ name: 'orchestrator', params: { userId: 11770, rekvId: 63, kond: 1 } }),
          'utf8'
        );
        fs.writeFileSync(
          path.join(tmpDir, 'saldoandmik', 'config.json'),
          JSON.stringify({ name: 'saldoandmik', flow: 'eelarve.sp_koosta_saldoandmik', params: { userId: 11770, rekvId: 63 } }),
          'utf8'
        );

        const nonProdPath = path.join(tmpDir, 'custom_test_state.json');
        fs.writeFileSync(
          nonProdPath,
          JSON.stringify({
            version: 1,
            cycle_date: '2026-10-09',
            status: 'IDLE',
            last_tick_at: null,
            next_scheduled_run: null,
            params: { userId: 2477, rekvId: 99, kond: 1 },
            tasks: {
              saldoandmik: {
                flow: 'eelarve.sp_koosta_saldoandmik',
                depends_on: [],
                allow_parallel: true,
                schedule: null,
                prompt: null,
                params: { userId: 2477, rekvId: 99 },
                status: 'PENDING',
                attempts: 0,
                max_attempts: 3,
                log_id: null,
                started_at: null,
                finished_at: null,
                duration_ms: null,
                error: null,
              },
            },
            history: [],
          }),
          'utf8'
        );

        const manager = new StateManager(nonProdPath);
        const loaded = await manager.loadState({}, '2026-10-09', tmpDir, 'Europe/Tallinn');
        expect(loaded.params.userId).toBe(2477);
        expect(loaded.params.rekvId).toBe(99);
        expect(loaded.tasks.saldoandmik.params?.userId).toBe(2477);
      } finally {
        fs.rmSync(tmpDir, { recursive: true, force: true });
      }
    });
  });

  describe('Задержка перед повторной попыткой (task_read_mail_retry_backoff)', () => {
    it('не запускает повтор раньше retry_delay_minutes, не дублирует TASK_RETRY_WAIT и запускает после задержки', async () => {
      const file = testStatePath('test_retry_backoff_delay.json');
      try {
        const stateManager = new StateManager(file);
        const state = await stateManager.loadState({ userId: 11770, rekvId: 63, kond: 1 }, '2026-11-20');
        state.cycle_date = '2026-11-20';
        state.status = 'IN_PROGRESS';

        // Изолируем тест от остальных задач
        for (const k of Object.keys(state.tasks)) {
          if (k !== 'read_mail') state.tasks[k].status = 'SUCCESS';
        }
        state.tasks.read_mail.status = 'RUNNING';
        state.tasks.read_mail.attempts = 1;
        state.tasks.read_mail.max_attempts = 5;
        state.tasks.read_mail.retry_delay_minutes = 15;
        state.tasks.read_mail.log_id = 9001;
        state.tasks.read_mail.started_at = '2026-11-20T04:00:00.000Z';
        fs.writeFileSync(file, JSON.stringify(state, null, 2), 'utf-8');

        let dispatchCount = 0;
        const client = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server' },
          jest.fn().mockImplementation(async (url: string) => {
            if (url.includes('/task/read_log') || url.includes('read_log')) {
              return {
                ok: true,
                status: 200,
                json: async () => ({
                  status: 200,
                  result: 1,
                  data: [
                    {
                      id: 9001,
                      flow: 'mail.read_mail_errors',
                      status: 'failed',
                      exec_start: '2026-11-20T04:00:00.000Z',
                      exec_end: '2026-11-20T04:00:30.000Z',
                      error: 'IMAP connection timed out',
                    },
                  ],
                }),
              };
            }
            if (url.includes('/task/readMail')) {
              dispatchCount++;
              return {
                ok: true,
                status: 200,
                json: async () => ({ status: 200, result: 1, log_id: 9002 }),
              };
            }
            return {
              ok: true,
              status: 200,
              json: async () => ({ status: 200, result: 1, data: [] }),
            };
          }) as unknown as typeof fetch
        );

        // Тик 1: 06:01 EET (04:01 UTC) — фиксируем сбой, переводим в PENDING с ожиданием 15 мин
        await runOrchestratorTick(
          { stateFilePath: file },
          { apiClient: client, currentDate: new Date('2026-11-20T04:01:00.000Z'), timezone: 'Europe/Tallinn' }
        );

        let reloaded: OrchestratorState = JSON.parse(fs.readFileSync(file, 'utf-8'));
        expect(reloaded.tasks.read_mail.status).toBe('PENDING');
        expect(reloaded.tasks.read_mail.attempts).toBe(1);
        expect(dispatchCount).toBe(0);
        expect(reloaded.history.filter((h) => h.event === 'TASK_RETRY_WAIT' && h.task === 'read_mail')).toHaveLength(1);

        // Тик 2: 06:10 EET (04:10 UTC) — прошло < 15 мин, повтор не запускается, TASK_RETRY_WAIT не дублируется
        await runOrchestratorTick(
          { stateFilePath: file },
          { apiClient: client, currentDate: new Date('2026-11-20T04:10:00.000Z'), timezone: 'Europe/Tallinn' }
        );

        reloaded = JSON.parse(fs.readFileSync(file, 'utf-8'));
        expect(reloaded.tasks.read_mail.status).toBe('PENDING');
        expect(reloaded.tasks.read_mail.attempts).toBe(1);
        expect(dispatchCount).toBe(0);
        expect(reloaded.history.filter((h) => h.event === 'TASK_RETRY_WAIT' && h.task === 'read_mail')).toHaveLength(1);

        // Тик 3: 06:16 EET (04:16 UTC) — прошло > 15 мин с exec_end (04:00:30), повтор запускается
        await runOrchestratorTick(
          { stateFilePath: file },
          { apiClient: client, currentDate: new Date('2026-11-20T04:16:00.000Z'), timezone: 'Europe/Tallinn' }
        );

        reloaded = JSON.parse(fs.readFileSync(file, 'utf-8'));
        expect(reloaded.tasks.read_mail.status).toBe('RUNNING');
        expect(reloaded.tasks.read_mail.attempts).toBe(2);
        expect(reloaded.tasks.read_mail.log_id).toBe(9002);
        expect(dispatchCount).toBe(1);
      } finally {
        if (fs.existsSync(file)) {
          try { fs.unlinkSync(file); } catch {}
        }
      }
    });

    it('при retry_delay_minutes = 0 (default) повторяет немедленно на том же тике', async () => {
      const file = testStatePath('test_retry_backoff_zero.json');
      try {
        const stateManager = new StateManager(file);
        const state = await stateManager.loadState({ userId: 11770, rekvId: 63, kond: 1 }, '2026-11-20');
        state.cycle_date = '2026-11-20';
        state.status = 'IN_PROGRESS';

        for (const k of Object.keys(state.tasks)) {
          if (k !== 'read_mail') state.tasks[k].status = 'SUCCESS';
        }
        state.tasks.read_mail.status = 'RUNNING';
        state.tasks.read_mail.attempts = 1;
        state.tasks.read_mail.max_attempts = 3;
        state.tasks.read_mail.retry_delay_minutes = 0;
        state.tasks.read_mail.log_id = 9011;
        state.tasks.read_mail.started_at = '2026-11-20T04:00:00.000Z';
        fs.writeFileSync(file, JSON.stringify(state, null, 2), 'utf-8');

        let dispatchCount = 0;
        const client = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server' },
          jest.fn().mockImplementation(async (url: string) => {
            if (url.includes('read_log')) {
              return {
                ok: true,
                status: 200,
                json: async () => ({
                  status: 200,
                  result: 1,
                  data: [{ id: 9011, flow: 'mail.read_mail_errors', status: 'failed', exec_start: '2026-11-20T04:00:00.000Z', exec_end: '2026-11-20T04:00:10.000Z', error: 'err' }],
                }),
              };
            }
            if (url.includes('/task/readMail')) {
              dispatchCount++;
              return { ok: true, status: 200, json: async () => ({ status: 200, result: 1, log_id: 9012 }) };
            }
            return { ok: true, status: 200, json: async () => ({ status: 200, result: 1, data: [] }) };
          }) as unknown as typeof fetch
        );

        await runOrchestratorTick(
          { stateFilePath: file },
          { apiClient: client, currentDate: new Date('2026-11-20T04:01:00.000Z'), timezone: 'Europe/Tallinn' }
        );

        const reloaded: OrchestratorState = JSON.parse(fs.readFileSync(file, 'utf-8'));
        expect(reloaded.tasks.read_mail.status).toBe('RUNNING');
        expect(reloaded.tasks.read_mail.attempts).toBe(2);
        expect(dispatchCount).toBe(1);
      } finally {
        if (fs.existsSync(file)) {
          try { fs.unlinkSync(file); } catch {}
        }
      }
    });

    it('resetCycleForNewDay обнуляет attempts, а reconcileTasksWithConfigs переносит retry_delay_minutes и max_attempts', async () => {
      const file = testStatePath('test_retry_backoff_reset.json');
      try {
        const stateManager = new StateManager(file);
        const state = await stateManager.loadState({ userId: 11770, rekvId: 63, kond: 1 }, '2026-11-20');
        state.tasks.read_mail.status = 'FAILED';
        state.tasks.read_mail.attempts = 5;
        state.tasks.read_mail.max_attempts = 3;
        state.tasks.read_mail.retry_delay_minutes = 0;

        const reset = resetCycleForNewDay(state, '2026-11-21', undefined, 'Europe/Tallinn', new Date('2026-11-21T00:05:00.000Z'));
        expect(reset.tasks.read_mail.attempts).toBe(0);
        expect(reset.tasks.read_mail.status).toBe('PENDING');
        expect(reset.tasks.read_mail.max_attempts).toBe(5);
        expect(reset.tasks.read_mail.retry_delay_minutes).toBe(15);

        // Проверка reconcileTasksWithConfigs на существующей задаче
        reconcileTasksWithConfigs(state.tasks, loadAllAgentConfigs(), true);
        expect(state.tasks.read_mail.max_attempts).toBe(5);
        expect(state.tasks.read_mail.retry_delay_minutes).toBe(15);
      } finally {
        if (fs.existsSync(file)) {
          try { fs.unlinkSync(file); } catch {}
        }
      }
    });
  });

  describe('Единый источник userId при явном CLI --user (task_cli_user_override_mismatch)', () => {
    it('(а, б) при явном userId=2477 задача с params.userId=11770 запускается и проверяет логи под 11770, а schedule_monitor использует 2477', async () => {
      const file = testStatePath('test_cli_user_override_mismatch.json');
      try {
        const stateManager = new StateManager(file);
        const state = await stateManager.loadState({ userId: 11770, rekvId: 63, kond: 1 }, '2026-11-20');
        state.cycle_date = '2026-11-20';
        state.status = 'IN_PROGRESS';

        for (const k of Object.keys(state.tasks)) {
          if (k !== 'saldoandmik') state.tasks[k].status = 'SUCCESS';
        }
        state.tasks.saldoandmik.status = 'PENDING';
        state.tasks.saldoandmik.params = { userId: 11770, rekvId: 63, kond: 1 };
        fs.writeFileSync(file, JSON.stringify(state, null, 2), 'utf-8');

        const seenUrls: string[] = [];
        let dispatchedUserId: number | undefined;
        const mockClient = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server', apiRetryBaseDelayMs: 0 },
          jest.fn().mockImplementation(async (url: string) => {
            seenUrls.push(String(url));
            return { ok: true, status: 200, json: async () => ({ status: 200, result: 1, data: [] }) };
          }) as unknown as typeof fetch
        );

        const registry = {
          saldoandmik: {
            name: 'saldoandmik',
            dispatch: async (ctx: { userId: number; params: Record<string, unknown> }) => {
              dispatchedUserId = typeof ctx.params.userId === 'number' ? ctx.params.userId : ctx.userId;
              return 77702;
            },
          },
        };

        // Тик 1: запуск с явным userId=2477 — dupGuard и dispatch должны использовать 11770
        await runOrchestratorTick(
          { stateFilePath: file, userId: 2477 },
          {
            apiClient: mockClient,
            registry: registry as any,
            currentDate: new Date('2026-11-20T18:05:00.000Z'), // 20:05 Tallinn
            targetDateStr: '2026-11-20',
            timezone: 'Europe/Tallinn',
          }
        );

        expect(dispatchedUserId).toBe(11770);
        expect(seenUrls.some((u) => u.includes('/task/read_log/11770/'))).toBe(true);
        expect(seenUrls.some((u) => u.includes('/task/read_log/2477/') && u.includes('eelarve.sp_koosta_saldoandmik'))).toBe(false);

        // Тик 2: проверка RUNNING задачи с явным userId=2477 — checkTaskStatus тоже должен использовать 11770
        seenUrls.length = 0;
        await runOrchestratorTick(
          { stateFilePath: file, userId: 2477 },
          {
            apiClient: mockClient,
            registry: registry as any,
            currentDate: new Date('2026-11-20T18:06:00.000Z'),
            targetDateStr: '2026-11-20',
            timezone: 'Europe/Tallinn',
          }
        );

        expect(seenUrls.some((u) => u.includes('/task/read_log/11770/'))).toBe(true);
        expect(seenUrls.some((u) => u.includes('/task/read_log/2477/') && u.includes('eelarve.sp_koosta_saldoandmik'))).toBe(false);
      } finally {
        if (fs.existsSync(file)) {
          try { fs.unlinkSync(file); } catch {}
        }
      }
    });

    it('dispatch saldoandmik через оркестратор уходит с user_id 2477, rekv_id 63, kond 1 (task_saldoandmik_user_2477)', async () => {
      const file = testStatePath('test_saldoandmik_user_2477.json');
      try {
        const stateManager = new StateManager(file);
        const state = await stateManager.loadState(undefined, '2026-11-20');
        state.cycle_date = '2026-11-20';
        state.status = 'IN_PROGRESS';

        for (const k of Object.keys(state.tasks)) {
          if (k !== 'saldoandmik') state.tasks[k].status = 'SUCCESS';
        }
        state.tasks.saldoandmik.status = 'PENDING';
        fs.writeFileSync(file, JSON.stringify(state, null, 2), 'utf-8');

        let capturedSaldoBody: Record<string, unknown> | null = null;
        const seenReadLogUrls: string[] = [];
        const mockClient = new ApiClient(
          { buh70ApiBaseUrl: 'http://test-server', apiRetryBaseDelayMs: 0 },
          jest.fn().mockImplementation(async (url: string, init?: { body?: string }) => {
            const urlStr = String(url);
            if (urlStr.includes('/task/read_log/')) {
              seenReadLogUrls.push(urlStr);
              return { ok: true, status: 200, json: async () => ({ status: 200, result: 1, data: [] }) };
            }
            if (urlStr.includes('/task/calcKondSaldoandmik/')) {
              capturedSaldoBody = init?.body ? JSON.parse(init.body) : null;
              return { ok: true, status: 200, json: async () => ({ status: 200, result: 1, log_id: 91234 }) };
            }
            return { ok: true, status: 200, json: async () => ({ status: 200, result: 1, data: [] }) };
          }) as unknown as typeof fetch
        );

        await runOrchestratorTick(
          { stateFilePath: file },
          {
            apiClient: mockClient,
            currentDate: new Date('2026-11-20T18:05:00.000Z'), // 20:05 Tallinn
            targetDateStr: '2026-11-20',
            timezone: 'Europe/Tallinn',
          }
        );

        expect(capturedSaldoBody).toEqual({ user_id: 2477, rekv_id: 63, kond: 1 });
        expect(seenReadLogUrls.some((u) => u.includes('/task/read_log/2477/eelarve.sp_koosta_saldoandmik'))).toBe(true);
      } finally {
        if (fs.existsSync(file)) {
          try { fs.unlinkSync(file); } catch {}
        }
      }
    });
  });
});
