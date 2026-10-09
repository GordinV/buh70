import {
  buildScheduleSnapshot,
  computeNextPlannedRun,
  runScheduleMonitor,
  runScheduleMonitorSubagent,
  manifest,
} from './agent';
import { logAgentSchedule } from './tools';
import { OrchestratorState } from '../orchestrator/orchestrator.schemas';
import { ApiClient } from '../shared/api_client';

describe('Субагент schedule_monitor', () => {
  const baseState: OrchestratorState = {
    version: 1,
    cycle_date: '2026-10-09',
    status: 'IN_PROGRESS',
    last_tick_at: '2026-10-09T05:00:00.000Z',
    next_scheduled_run: null,
    params: { userId: 2477, rekvId: 63, kond: 1 },
    tasks: {
      getEarved: {
        flow: 'docs.sp_loe_earved',
        depends_on: [],
        allow_parallel: true,
        schedule: { time: '07:00' },
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
      calc_arv_jaak: {
        flow: 'docs.check_arv_jaak',
        depends_on: [],
        allow_parallel: true,
        schedule: { time: '07:30' },
        prompt: null,
        params: {},
        status: 'SUCCESS',
        attempts: 1,
        max_attempts: 3,
        log_id: 101,
        started_at: '2026-10-09T04:30:00.000Z',
        finished_at: '2026-10-09T04:31:00.000Z',
        duration_ms: 60000,
        error: null,
      },
      lisa1_lisa5: {
        flow: 'eelarve.salvesta_lisa_1_5_kontrol',
        depends_on: ['saldoandmik'],
        allow_parallel: true,
        schedule: null,
        prompt: null,
        params: {},
        status: 'RUNNING',
        attempts: 1,
        max_attempts: 3,
        timeout_hours: 6,
        log_id: 102,
        started_at: '2026-10-09T04:00:00.000Z',
        finished_at: null,
        duration_ms: null,
        error: null,
      },
      reporter: {
        flow: 'email_report',
        depends_on: ['calc_arv_jaak', 'lisa1_lisa5'],
        allow_parallel: false,
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

  describe('buildScheduleSnapshot', () => {
    it('корректно вычисляет статус PENDING до и после наступления schedule.time', () => {
      // 06:00 в Таллинне (03:00 UTC) - до 07:00
      const before7 = new Date('2026-10-09T03:00:00.000Z');
      const snapshotBefore = buildScheduleSnapshot(baseState, before7, 'Europe/Tallinn');
      const getEarvedBefore = snapshotBefore.agents.find((a) => a.agent === 'getEarved');
      expect(getEarvedBefore?.next_run_reason).toBe('SCHEDULE_TODAY');
      expect(getEarvedBefore?.next_planned_run).toBe('2026-10-09T07:00:00');

      // 08:00 в Таллинне (05:00 UTC) - после 07:00
      const after7 = new Date('2026-10-09T05:00:00.000Z');
      const snapshotAfter = buildScheduleSnapshot(baseState, after7, 'Europe/Tallinn');
      const getEarvedAfter = snapshotAfter.agents.find((a) => a.agent === 'getEarved');
      expect(getEarvedAfter?.next_run_reason).toBe('SCHEDULE_TOMORROW');
      expect(getEarvedAfter?.next_planned_run).toBe('2026-10-10T07:00:00');
    });

    it('корректно работает при PENDING с depends_on без расписания', () => {
      const now = new Date('2026-10-09T05:00:00.000Z');
      const snapshot = buildScheduleSnapshot(baseState, now, 'Europe/Tallinn');
      const rep = snapshot.agents.find((a) => a.agent === 'reporter');
      expect(rep?.next_run_reason).toBe('AFTER_DEPENDENCIES');
      expect(rep?.next_planned_run).toBeNull();
    });

    it('корректно обрабатывает RETRY для PENDING с attempts > 0', () => {
      const now = new Date('2026-10-09T05:00:00.000Z');
      const stateWithRetry: OrchestratorState = {
        ...baseState,
        tasks: {
          ...baseState.tasks,
          getEarved: {
            ...baseState.tasks.getEarved,
            attempts: 1,
          },
        },
      };
      const snapshot = buildScheduleSnapshot(stateWithRetry, now, 'Europe/Tallinn');
      const getEarved = snapshot.agents.find((a) => a.agent === 'getEarved');
      expect(getEarved?.next_run_reason).toBe('RETRY');
      expect(getEarved?.next_planned_run).toBe(now.toISOString());
    });

    it('вычисляет timeout_deadline для RUNNING задачи с учетом timeout_hours', () => {
      const now = new Date('2026-10-09T05:00:00.000Z');
      const snapshot = buildScheduleSnapshot(baseState, now, 'Europe/Tallinn');
      const lisa = snapshot.agents.find((a) => a.agent === 'lisa1_lisa5');
      expect(lisa?.next_run_reason).toBe('RUNNING_NOW');
      expect(lisa?.next_planned_run).toBeNull();
      // started_at = 04:00Z, timeout_hours = 6 => deadline = 10:00Z
      expect(lisa?.timeout_deadline).toBe(new Date('2026-10-09T10:00:00.000Z').toISOString());
    });

    it('подставляет дефолтный таймаут 12 часов при отсутствии timeout_hours у RUNNING задачи', () => {
      const now = new Date('2026-10-09T05:00:00.000Z');
      const stateWithoutTimeoutHours: OrchestratorState = {
        ...baseState,
        tasks: {
          ...baseState.tasks,
          lisa1_lisa5: {
            ...baseState.tasks.lisa1_lisa5,
            timeout_hours: undefined,
          },
        },
      };
      const snapshot = buildScheduleSnapshot(stateWithoutTimeoutHours, now, 'Europe/Tallinn');
      const lisa = snapshot.agents.find((a) => a.agent === 'lisa1_lisa5');
      // started_at = 04:00Z, timeout_hours default = 12 => deadline = 16:00Z
      expect(lisa?.timeout_deadline).toBe(new Date('2026-10-09T16:00:00.000Z').toISOString());
    });

    it('для завершенных задач со schedule планирует запуск на завтра', () => {
      const now = new Date('2026-10-09T05:00:00.000Z');
      const snapshot = buildScheduleSnapshot(baseState, now, 'Europe/Tallinn');
      const calc = snapshot.agents.find((a) => a.agent === 'calc_arv_jaak');
      expect(calc?.status).toBe('SUCCESS');
      expect(calc?.next_run_reason).toBe('SCHEDULE_TOMORROW');
      expect(calc?.next_planned_run).toBe('2026-10-10T07:30:00');
    });

    it('агрегирует счетчики summary по всем статусам', () => {
      const now = new Date('2026-10-09T05:00:00.000Z');
      const snapshot = buildScheduleSnapshot(baseState, now, 'Europe/Tallinn');
      expect(snapshot.summary).toEqual({
        pending: 2, // getEarved, reporter
        running: 1, // lisa1_lisa5
        success: 1, // calc_arv_jaak
        failed: 0,
        skipped: 0,
      });
    });

    it('усекает текст ошибки до 500 символов', () => {
      const longError = 'E'.repeat(600);
      const stateWithError: OrchestratorState = {
        ...baseState,
        tasks: {
          ...baseState.tasks,
          getEarved: {
            ...baseState.tasks.getEarved,
            error: longError,
          },
        },
      };
      const snapshot = buildScheduleSnapshot(stateWithError, new Date(), 'Europe/Tallinn');
      const getEarved = snapshot.agents.find((a) => a.agent === 'getEarved');
      expect(getEarved?.error?.length).toBe(503); // 500 + '...'
      expect(getEarved?.error?.endsWith('...')).toBe(true);
    });
  });

  describe('tools: logAgentSchedule', () => {
    it('вызывает POST /task/logAgentSchedule/ и возвращает валидный ответ', async () => {
      const mockPost = jest.fn().mockResolvedValue({
        status: 200,
        result: 1,
        log_id: 889911,
      });
      const mockApiClient = {
        post: mockPost,
      } as unknown as ApiClient;

      const snapshot = buildScheduleSnapshot(baseState, new Date(), 'Europe/Tallinn');
      const result = await logAgentSchedule(
        {
          userId: 2477,
          rekvId: 63,
          snapshot,
        },
        mockApiClient
      );

      expect(mockPost).toHaveBeenCalledWith(
        '/task/logAgentSchedule/',
        {
          user_id: 2477,
          rekv_id: 63,
          snapshot,
        },
        { timeoutMs: 5000 }
      );
      expect(result.log_id).toBe(889911);
    });
  });

  describe('runScheduleMonitor', () => {
    it('возвращает log_id при успешном обращении к бэкенду', async () => {
      const mockPost = jest.fn().mockResolvedValue({
        status: 200,
        result: 1,
        log_id: 554433,
      });
      const mockApiClient = {
        post: mockPost,
      } as unknown as ApiClient;

      const logId = await runScheduleMonitor(
        baseState,
        { userId: 2477, rekvId: 63 },
        mockApiClient,
        new Date(),
        'Europe/Tallinn'
      );

      expect(logId).toBe(554433);
    });

    it('не выбрасывает исключение при ошибке бэкенда и возвращает null', async () => {
      const mockPost = jest.fn().mockRejectedValue(new Error('Network failure'));
      const mockApiClient = {
        post: mockPost,
      } as unknown as ApiClient;

      const logId = await runScheduleMonitor(
        baseState,
        { userId: 2477, rekvId: 63 },
        mockApiClient,
        new Date(),
        'Europe/Tallinn'
      );

      expect(logId).toBeNull();
    });
  });

  describe('runScheduleMonitorSubagent', () => {
    it('успешно выполняется при передаче state и возвращает ScheduleMonitorResult', async () => {
      const mockPost = jest.fn().mockResolvedValue({
        status: 200,
        result: 1,
        log_id: 998877,
      });
      const mockApiClient = {
        post: mockPost,
      } as unknown as ApiClient;

      const result = await runScheduleMonitorSubagent(
        { userId: 2477, rekvId: 63, state: baseState },
        { apiClient: mockApiClient, now: new Date(), timezone: 'Europe/Tallinn' }
      );

      expect(result.status).toBe('success');
      expect(result.logId).toBe(998877);
      expect(result.flow).toBe('ai_task.agent_schedule');
      expect(result.snapshot.agents.length).toBe(4);
    });

    it('корректно обрабатывает ошибку бэкенда без throw при throwOnError=false', async () => {
      const mockPost = jest.fn().mockRejectedValue(new Error('Connection refused'));
      const mockApiClient = {
        post: mockPost,
      } as unknown as ApiClient;

      const result = await runScheduleMonitorSubagent(
        { userId: 2477, rekvId: 63, state: baseState },
        { apiClient: mockApiClient, throwOnError: false }
      );

      expect(result.status).toBe('failed');
      expect(result.logId).toBeNull();
      expect(result.error).toBe('Connection refused');
    });

    it('выбрасывает ошибку при throwOnError=true', async () => {
      const mockPost = jest.fn().mockRejectedValue(new Error('Fatal API Error'));
      const mockApiClient = {
        post: mockPost,
      } as unknown as ApiClient;

      await expect(
        runScheduleMonitorSubagent(
          { userId: 2477, rekvId: 63, state: baseState },
          { apiClient: mockApiClient, throwOnError: true }
        )
      ).rejects.toThrow('Fatal API Error');
    });

    it('manifest.dispatch вызывает runScheduleMonitorSubagent и возвращает log_id', async () => {
      const mockPost = jest.fn().mockResolvedValue({
        status: 200,
        result: 1,
        log_id: 123456,
      });
      const mockApiClient = {
        post: mockPost,
      } as unknown as ApiClient;

      const logId = await manifest.dispatch({
        key: 'schedule_monitor',
        userId: 2477,
        rekvId: 63,
        kond: 1,
        params: { userId: 2477, rekvId: 63, state: baseState },
        apiClient: mockApiClient,
      });

      expect(logId).toBe(123456);
    });
  });
});
