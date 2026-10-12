import { ApiClient } from '../shared/api_client';
import { findActiveRun, toLocalDateStr, checkTaskAlreadyRunToday } from './orchestrator.tools';

const FLOW = 'eelarve.sp_koosta_saldoandmik';

function makeClient(data: unknown[] | Error) {
  const fetchMock = jest.fn().mockImplementation(async () => {
    if (data instanceof Error) throw data;
    return { ok: true, status: 200, json: async () => ({ result: 1, data }) };
  });
  return { client: new ApiClient({}, fetchMock as unknown as typeof fetch), fetchMock };
}

describe('Защита от параллельного дубля (findActiveRun)', () => {
  const now = new Date('2026-10-12T21:00:03.959Z'); // 00:00 по Таллину 13.10

  it('запись без status и exec_end (запуск 23:57 по Таллину) определяется как running', async () => {
    const { client, fetchMock } = makeClient([
      { id: 8546984, flow: FLOW, status: null, exec_start: '2026-10-12T23:57:00.000+03:00' },
    ]);
    const res = await findActiveRun(2477, FLOW, client, { now });
    expect(res.state).toBe('running');
    expect(res.logId).toBe(8546984);
    expect(fetchMock.mock.calls[0][0]).toContain('limit=5');
  });

  it('завершенные записи (success/failed/exec_end) не считаются активными', async () => {
    const { client } = makeClient([
      { id: 1, flow: FLOW, status: 'success', exec_start: '2026-10-12T20:00:00+03:00', exec_end: '2026-10-12T20:05:00+03:00' },
      { id: 2, flow: FLOW, status: 'failed', exec_start: '2026-10-12T21:00:00+03:00' },
    ]);
    expect((await findActiveRun(2477, FLOW, client, { now })).state).toBe('none');
  });

  it('«мертвая» запись старше maxAgeHours игнорируется', async () => {
    const { client } = makeClient([
      { id: 3, flow: FLOW, status: null, exec_start: '2026-10-11T08:00:00+03:00' },
    ]);
    expect((await findActiveRun(2477, FLOW, client, { now, maxAgeHours: 12 })).state).toBe('none');
  });

  it('пустой ответ в пределах grace-периода после started_at = running', async () => {
    const { client } = makeClient([]);
    const res = await findActiveRun(2477, FLOW, client, {
      now,
      startedAt: '2026-10-12T20:57:31.592Z',
    });
    expect(res.state).toBe('running');
  });

  it('пустой ответ после grace-периода = none', async () => {
    const { client } = makeClient([]);
    const res = await findActiveRun(2477, FLOW, client, {
      now,
      startedAt: '2026-10-12T20:00:00.000Z',
    });
    expect(res.state).toBe('none');
  });

  it('ошибка API = unknown (дубль запускать нельзя)', async () => {
    const { client } = makeClient(new Error('network down'));
    const res = await findActiveRun(2477, FLOW, client, { now });
    expect(res.state).toBe('unknown');
  });
});

describe('Локальная дата (Europe/Tallinn)', () => {
  it('UTC 21:00 12.10 — это уже 13.10 по Таллину', () => {
    expect(toLocalDateStr('2026-10-12T21:00:03.959Z', 'Europe/Tallinn')).toBe('2026-10-13');
  });

  it('ISO со смещением +03:00 приводится к правильному дню', () => {
    expect(toLocalDateStr('2026-10-12T23:57:00.000+03:00', 'Europe/Tallinn')).toBe('2026-10-12');
  });

  it('checkTaskAlreadyRunToday сравнивает локальный день, а не UTC-срез', async () => {
    const { client } = makeClient([
      {
        id: 10,
        flow: FLOW,
        status: 'success',
        exec_start: '2026-10-12T21:30:00.000Z', // 00:30 13.10 по Таллину
        exec_end: '2026-10-12T21:40:00.000Z',
      },
    ]);
    const res = await checkTaskAlreadyRunToday(2477, FLOW, client, '2026-10-13', undefined, 'Europe/Tallinn');
    expect(res.alreadyRun).toBe(true);
    expect(res.logId).toBe(10);
  });
});
