import * as fs from 'fs';
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
import { TASK_FLOW_SEND_FIN_BIT_REPORT } from '../sendFinBitReport/schemas';
import { TASK_FLOW_LISA1_LISA5 } from '../lisa1_lisa5/schemas';
import {
  calculateNextScheduledRun,
  getDefaultTaskGraph,
  loadAgentConfig,
  loadAllAgentConfigs,
  loadOrchestratorConfig,
  reconcileTasksWithConfigs,
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
import { resolveModelName } from '../index';

// Мокируем отправку отчета, чтобы исключить внешние сетевые SMTP-запросы во время тестов
jest.mock('../reporter/agent', () => ({
  generateAndSendReportSubagent: jest.fn().mockResolvedValue({
    sent: true,
    deliveryChannel: 'local_fallback',
    timestamp: '2026-09-15T20:00:00.000Z',
    formattedReport: 'Mock test report',
  }),
}));

describe('Главный Оркестратор', () => {
  const testStateFile = path.resolve(__dirname, 'test_orchestrator_state.json');

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
          if (url.includes('docs.sp_loe_earved')) flow = TASK_FLOW_GET_EARVED;
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
      expect(result.steps).toHaveLength(5);
      expect(result.steps[0].stepName).toBe(TASK_FLOW_SALDOANDMIK);
      expect(result.steps[0].status).toBe('SUCCESS');
      expect(result.steps[1].stepName).toBe(TASK_FLOW_CALC_ARV_JAAK);
      expect(result.steps[1].status).toBe('SUCCESS');
      expect(result.steps[2].stepName).toBe(TASK_FLOW_GET_EARVED);
      expect(result.steps[2].status).toBe('SUCCESS');
      expect(result.steps[3].stepName).toBe(TASK_FLOW_SEND_FIN_BIT_REPORT);
      expect(result.steps[3].status).toBe('SUCCESS');
      expect(result.steps[4].stepName).toBe(TASK_FLOW_LISA1_LISA5);
      expect(result.steps[4].status).toBe('SUCCESS');
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
          if (url.includes('docs.sp_loe_earved')) {
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
          currentDate: new Date('2026-09-15T20:05:00.000Z'),
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
      expect(defaultGraph.getEarved.schedule).toEqual({ time: '07:00' });

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
        throw new Error(`Unexpected url called: ${url}`);
      });

      const client = new ApiClient({}, mockFetch as unknown as typeof fetch);

      // Тик в 07:15 утра (после getEarved 07:00, но до calc_arv_jaak 07:30 и saldoandmik 20:00, forceRun: false)
      const tickAtNoon = await runOrchestratorTick(
        { stateFilePath: testStateFile, forceRun: false },
        {
          apiClient: client,
          currentDate: new Date('2026-09-15T07:15:00'),
          dailyStartHour: 20,
        }
      );

      // getEarved должен стартовать, а saldoandmik и calc_arv_jaak должны остаться в PENDING
      expect(tickAtNoon.activeTasks).toEqual(['getEarved']);
      expect(tickAtNoon.pendingTasks).toContain('saldoandmik');
      expect(tickAtNoon.pendingTasks).toContain('calc_arv_jaak');
      expect(mockFetch).toHaveBeenCalledTimes(1);

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
        if (url.includes('/task/read_log/2477/docs.sp_loe_earved')) {
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
        if (url.includes('/task/read_log/2477/docs.sp_loe_earved')) {
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
        expect.stringContaining('/task/read_log/2477/docs.sp_loe_earved'),
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
        if (url.includes('/task/read_log/2477/docs.sp_loe_earved')) {
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
      expect(configs.getEarved.schedule).toEqual({ time: '07:00' });
      expect(configs.getEarved.flow).toBe('docs.sp_loe_earved');
      expect(configs.getEarved.params).toMatchObject({ is_agent: true });

      expect(configs.calc_arv_jaak.flow).toBe('docs.check_arv_jaak');
      expect(configs.calc_arv_jaak.schedule).toEqual({ time: '07:30' });

      expect(configs.sendFinBitReport.flow).toBe('sendFinBitReport');
      expect(configs.sendFinBitReport.depends_on).toEqual(['getEarved']);

      expect(configs.lisa1_lisa5.depends_on).toEqual(['saldoandmik']);
      expect(configs.reporter.allow_parallel).toBe(false);
      expect(configs.reporter.depends_on).toEqual(['saldoandmik', 'calc_arv_jaak', 'getEarved', 'sendFinBitReport', 'lisa1_lisa5']);
    });

    it('getDefaultTaskGraph должен формировать валидный граф задач на базе config.json', () => {
      const graph = getDefaultTaskGraph();
      expect(graph.saldoandmik.status).toBe('PENDING');
      expect(graph.getEarved.schedule).toEqual({ time: '07:00' });
      expect(graph.sendFinBitReport.status).toBe('PENDING');
      expect(graph.sendFinBitReport.depends_on).toEqual(['getEarved']);
      expect(graph.reporter.depends_on.length).toBe(5);
    });

    it('reconcileTasksWithConfigs должен обновлять декларативные поля, сохраняя runtime-состояние задачи', () => {
      const existingTasks = {
        getEarved: {
          flow: 'docs.sp_loe_earved',
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
          flow: 'docs.sp_loe_earved_updated',
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
      expect(existingTasks.getEarved.flow).toBe('docs.sp_loe_earved_updated');
      expect(existingTasks.getEarved.schedule).toEqual({ time: '12:30' });
      expect(existingTasks.getEarved.prompt).toBe('Execute after 12:30');
      expect(existingTasks.getEarved.max_attempts).toBe(5);
      expect(existingTasks.getEarved.params).toEqual({
        defaultParam: 123,
        customRuntimeFlag: true,
      });

      // Рантайм-поля сохранены
      expect(existingTasks.getEarved.status).toBe('RUNNING');
      expect(existingTasks.getEarved.attempts).toBe(2);
      expect(existingTasks.getEarved.log_id).toBe(998877);
      expect(existingTasks.getEarved.started_at).toBe('2026-09-18T10:00:00.000Z');
    });

    it('evaluateTaskLaunchDecision с prompt вызывает aiGenerateFn и возвращает structured output с dynamic_params', async () => {
      const taskState: TaskState = {
        flow: 'docs.sp_loe_earved',
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
        flow: 'docs.sp_loe_earved',
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
          getEarved: {
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
            depends_on: ['getEarved'],
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
      expect(capturedPayload.user_id).toBe(2477);
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
          getEarved: {
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
            depends_on: ['getEarved'],
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
        depends_on: ['getEarved'],
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
          getEarved: getEarvedTask,
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
      expect(config.params).toEqual(expect.objectContaining({ userId: 2477, rekvId: 63, kond: 1 }));
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
      depends_on: ['getEarved'],
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
      const testStateFile = path.resolve(__dirname, 'state_retry_test.json');
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
      baseGraph.getEarved.status = 'SUCCESS';
      baseGraph.getEarved.log_id = 10429;
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
      const testStateFile = path.resolve(__dirname, 'state_dispatch_retry_test.json');
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
    });
  });
});
