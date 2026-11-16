'use strict';

const db = require('../libs/db');
db.queryDb = jest.fn();

jest.mock('../classes/DocumentTemplate', () => jest.fn());
const Doc = require('../classes/DocumentTemplate');
const inforegister = require('../libs/inforegister');
const info = require('../routes/raama/getInforegister');

const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const RAW = {
    base_info: {company_name: 'REGISTER OÜ', reg_code: '11735006', registry_status_text: 'Registrisse kantud', kmkr_number: 'EE101339256'},
    base_info_address: [{full_address: 'Tähe tn 129b, Tartu', city: 'Tartu linn', street: 'Tähe tänav 129b'}],
    base_info_contact: [
        {contact: 'info@ir.ee', type: 'email'},
        {contact: 'info@ir.ee', type: 'email'},
        {contact: '+3727446644', type: 'phone'}
    ],
    base_info_emta_company_taxes: [{period: '2026-Q1', employee_count: 6}, {period: '2026-Q2', employee_count: 7}]
};

const okHttp = (calls) => async () => {
    calls.n += 1;
    return {status: 200, headers: {'x-ratelimit-remaining-year': '90'}, body: JSON.stringify(RAW)};
};

describe('libs/inforegister', () => {
    test('summarizeBundle: название, адрес, контакты без дублей, последний период', () => {
        const b = inforegister.summarizeBundle(RAW, 2026);
        expect(b.name).toBe('REGISTER OÜ');
        expect(b.address.fullAddress).toBe('Tähe tn 129b, Tartu');
        expect(b.contacts.emails).toEqual(['info@ir.ee']);
        expect(b.contacts.phones).toEqual(['+3727446644']);
        expect(b.latestPeriod).toBe('2026-Q2');
    });

    test('Код не из 8 цифр: платный вызов не делается', async () => {
        const calls = {n: 0};
        const c = inforegister.createClient({apiKey: 'k', http: okHttp(calls)});
        const r = await c.getBundle('1K2563758R');
        expect(r.ok).toBe(false);
        expect(r.reason).toBe('invalid_reg_code');
        expect(calls.n).toBe(0);
    });

    test('Нет ключа и dry_run не тратят лимит', async () => {
        const calls = {n: 0};
        const noKey = inforegister.createClient({http: okHttp(calls)});
        process.env.INFOREGISTER_API_KEY = 'from-env'; // переменная окружения больше не используется
        expect((await noKey.getBundle('11735006')).reason).toBe('no_api_key');
        const dry = inforegister.createClient({apiKey: 'k', dryRun: true, http: okHttp(calls)});
        expect((await dry.getBundle('11735006')).reason).toBe('dry_run_no_spend');
        expect(calls.n).toBe(0);
    });

    test('insecureTls передается в http третьим аргументом, по умолчанию проверка сертификата включена', async () => {
        const seen = [];
        const http = async (url, headers, insecure) => {
            seen.push(insecure);
            return {status: 200, headers: {}, body: JSON.stringify(RAW)};
        };
        await inforegister.createClient({apiKey: 'k', http: http}).getBundle('11735006');
        await inforegister.createClient({apiKey: 'k', insecureTls: true, http: http}).getBundle('11735006');
        expect(seen).toEqual([false, true]);
    });

    test('Потолок вызовов за запуск и резерв годового лимита', async () => {
        const calls = {n: 0};
        const c = inforegister.createClient({apiKey: 'k', maxCalls: 1, http: okHttp(calls)});
        expect((await c.getBundle('11735006')).ok).toBe(true);
        expect((await c.getBundle('10000001')).reason).toBe('budget_exhausted');
        expect(calls.n).toBe(1);

        const c2 = inforegister.createClient({apiKey: 'k', maxCalls: 5, minRemaining: 95, http: okHttp(calls)});
        expect((await c2.getBundle('11735006')).ok).toBe(true); // остаток узнаем из заголовка: 90 <= 95
        expect((await c2.getBundle('10000001')).reason).toBe('year_limit_reserve');
    });

    test('404 кэшируется как «данных нет»; 401 отключает ключ', async () => {
        const saved = {};
        const store = {
            get: async (k) => (saved[k] !== undefined ? saved[k] : null),
            set: async (k, payload, negative) => {
                saved[k] = {payload: payload, negative: negative};
            }
        };
        const calls = {n: 0};
        const http404 = async () => {
            calls.n += 1;
            return {status: 404, headers: {}, body: '{"message":"No results"}'};
        };
        const c = inforegister.createClient({apiKey: 'k', store: store, http: http404});
        expect((await c.getBundle('11735006')).reason).toBe('not_found');
        expect((await c.getBundle('11735006')).reason).toBe('not_found'); // из кэша
        expect(calls.n).toBe(1);

        const http401 = async () => ({status: 401, headers: {}, body: ''});
        const c2 = inforegister.createClient({apiKey: 'bad', http: http401});
        expect((await c2.getBundle('11735006')).reason).toBe('unauthorized');
        expect((await c2.getBundle('10000001')).reason).toBe('unauthorized');
    });
});

describe('getInforegister backend', () => {
    beforeEach(() => {
        db.queryDb.mockReset();
    });

    const fakeClient = (map) => ({
        getBundle: async (code) => map[code] || {ok: false, reason: 'not_found', message: 'x'},
        getUsage: () => ({spent: 2, remainingYear: 80})
    });
    const bundle = (name, status) => ({
        ok: true,
        source: 'api',
        data: {name: name, registryStatus: status || 'Registrisse kantud', vatNumber: 'EE1', address: {fullAddress: 'Tallinn'}, contacts: {emails: ['a@b.ee'], phones: []}}
    });

    test('parseDryRun: по умолчанию true, выключается только явным false', () => {
        expect(info.parseDryRun(undefined)).toBe(true);
        expect(info.parseDryRun('true')).toBe(true);
        expect(info.parseDryRun(false)).toBe(false);
        expect(info.parseDryRun('false')).toBe(false);
    });

    test('buildAsutusPayload: id=0, omvorm пустая строка (NOT NULL), поля из реестра', () => {
        const p = info.buildAsutusPayload('11735006', bundle('REGISTER OÜ').data);
        expect(p.id).toBe(0);
        expect(p.data.regkood).toBe('11735006');
        expect(p.data.nimetus).toBe('REGISTER OÜ');
        expect(p.data.omvorm).toBe('');
        expect(p.data.email).toBe('a@b.ee');
        expect(p.data.kmkr).toBe('EE1');
    });

    test('dry_run: данные получены, процедура сохранения не вызывается', async () => {
        db.queryDb
            .mockReturnValueOnce(Promise.resolve({data: [{id: 700, missing: ['11735006']}]})) // findMissing
            .mockReturnValueOnce(Promise.resolve({data: []})); // asutusExists
        const r = await info.processMissingAsutused(11770, 63, 700, {dryRun: true}, fakeClient({'11735006': bundle('REGISTER OÜ')}));
        expect(r.items[0].status).toBe('would_create');
        expect(r.would_create).toBe(1);
        expect(r.created).toBe(0);
        expect(r.calls_spent).toBe(2);
        expect(db.queryDb).toHaveBeenCalledTimes(2);
    });

    test('Запись: вызывается libs.sp_salvesta_asutus с user_id и rekv_id, id попадает в результат', async () => {
        db.queryDb
            .mockReturnValueOnce(Promise.resolve({data: [{id: 700, missing: ['11735006']}]}))
            .mockReturnValueOnce(Promise.resolve({data: []})) // не существует
            .mockReturnValueOnce(Promise.resolve({data: [{id: 4321}]})); // sp_salvesta_asutus
        const r = await info.processMissingAsutused(11770, 63, 700, {dryRun: false}, fakeClient({'11735006': bundle('REGISTER OÜ')}));
        expect(r.items[0].status).toBe('created');
        expect(r.items[0].asutus_id).toBe(4321);
        const call = db.queryDb.mock.calls[2];
        expect(call[0]).toContain('libs.sp_salvesta_asutus');
        expect(call[1][1]).toBe(11770);
        expect(call[1][2]).toBe(63);
        expect(JSON.parse(call[1][0]).data.nimetus).toBe('REGISTER OÜ');
    });

    test('Уже есть в libs.asutus: пропуск без вызова реестра; закрытая и неверный код не сохраняются; ошибка не блокирует остальных', async () => {
        db.queryDb
            .mockReturnValueOnce(Promise.resolve({data: [{id: 701, missing: ['11111111', '22222222', '1K2563758R', '33333333', '44444444']}]}))
            .mockReturnValueOnce(Promise.resolve({data: [{id: 9}]})) // 11111111 уже есть
            .mockReturnValueOnce(Promise.resolve({data: []})) // 22222222 нет
            .mockReturnValueOnce(Promise.resolve({data: []})) // 1K2563758R нет
            .mockReturnValueOnce(Promise.resolve({data: []})) // 33333333 нет
            .mockReturnValueOnce(Promise.reject(new Error('Viga. IK juba olemas'))) // сохранение 33333333
            .mockReturnValueOnce(Promise.resolve({data: []})) // 44444444 нет
            .mockReturnValueOnce(Promise.resolve({data: [{id: 55}]})); // сохранение 44444444
        const client = {
            getBundle: async (code) => {
                if (code === '1K2563758R') return {ok: false, reason: 'invalid_reg_code', message: 'x'};
                if (code === '22222222') return bundle('KINNI OÜ', 'Kustutatud');
                return bundle('ORG ' + code);
            },
            getUsage: () => ({spent: 3, remainingYear: 50})
        };
        const r = await info.processMissingAsutused(11770, 63, 701, {dryRun: false}, client);
        const st = r.items.map((i) => i.regkood + ':' + i.status).join(' ');
        expect(st).toBe('11111111:exists 22222222:closed 1K2563758R:needs_manual 33333333:error 44444444:created');
        expect(r.items[3].error).toContain('IK juba olemas');
        expect(r.created).toBe(1);
    });

    test('Лог check_asutus не найден / missing пуст: клиент реестра не вызывается', async () => {
        db.queryDb.mockReturnValueOnce(Promise.resolve({data: []}));
        const client = {getBundle: jest.fn(), getUsage: () => ({spent: 0, remainingYear: null})};
        const r1 = await info.processMissingAsutused(11770, 63, null, {dryRun: true}, client);
        expect(r1.total).toBe(0);
        expect(r1.source_log_id).toBeNull();

        db.queryDb.mockReturnValueOnce(Promise.resolve({data: [{id: 702, missing: []}]}));
        const r2 = await info.processMissingAsutused(11770, 63, 702, {dryRun: true}, client);
        expect(r2.total).toBe(0);
        expect(client.getBundle).not.toHaveBeenCalled();
    });

    test('main: создает лог и сразу возвращает log_id (фон не блокирует ответ)', async () => {
        const crypto = require('crypto');
        const token = 'valid-batch-token';
        const sha256 = crypto.createHash('sha256').update(token, 'utf8').digest('hex');
        const res = {send: jest.fn().mockReturnThis(), status: jest.fn().mockReturnThis()};
        db.queryDb
            .mockReturnValueOnce(Promise.resolve({data: [{tokens: [{token_sha256: sha256, user_id: 11770, rekv_id: 63, label: 'ai_task', scopes: ['batch'], active: true}]}]})) // resolveInforegisterToken
            .mockReturnValueOnce(Promise.resolve({data: [{id: 800}]})) // createLog
            .mockReturnValue(Promise.resolve({data: []})); // остальное (поиск лога, endLog)
        await info.main({query: {}, body: {hash: token, user_id: 11770, rekv_id: 63, log_id: 702}, params: {}}, res);
        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.send).toHaveBeenCalledWith(expect.objectContaining({log_id: 800, status: 200}));
        await wait(50);
    });

    describe('getApiKey (ключ из ou.config через модель config)', () => {
        test('Ключ берется из inforegister_api_key конфига учреждения configRekvId (по умолчанию 3), а не из rekvId сохранения', async () => {
            const select = jest.fn().mockReturnValue(Promise.resolve({row: [{inforegister_api_key: '  SECRET  '}]}));
            Doc.mockImplementation(() => ({select: select}));
            expect(await info.getApiKey(11770, 3)).toBe('SECRET');
            expect(Doc).toHaveBeenCalledWith('config', 3, 11770, 3, 'lapsed');
        });

        test('Пустое поле, select() вернул undefined или исключение: пустой ключ', async () => {
            Doc.mockImplementation(() => ({select: jest.fn().mockReturnValue(Promise.resolve({row: [{inforegister_api_key: null}]}))}));
            expect(await info.getApiKey(11770, 63)).toBe('');
            Doc.mockImplementation(() => ({select: jest.fn().mockReturnValue(Promise.resolve(undefined))}));
            expect(await info.getApiKey(11770, 63)).toBe('');
            Doc.mockImplementation(() => ({select: jest.fn().mockReturnValue(Promise.reject(new Error('db')))}));
            expect(await info.getApiKey(11770, 63)).toBe('');
        });

        test('Нет ключа в конфиге: платный вызов не делается, статус registry_unavailable, ключа нет в result', async () => {
            Doc.mockImplementation(() => ({select: jest.fn().mockReturnValue(Promise.resolve({row: [{inforegister_api_key: ''}]}))}));
            db.queryDb
                .mockReturnValueOnce(Promise.resolve({data: [{id: 710, missing: ['11735006']}]}))
                .mockReturnValueOnce(Promise.resolve({data: []})) // asutusExists
                .mockReturnValue(Promise.resolve(null)); // кэш недоступен
            const r = await info.processMissingAsutused(11770, 63, 710, {dryRun: false});
            expect(Doc).toHaveBeenCalledWith('config', 3, 11770, 3, 'lapsed');
            expect(r.items[0].status).toBe('registry_unavailable');
            expect(r.items[0].error).toContain('no_api_key');
            expect(r.calls_spent).toBe(0);
        });

        test('Ключ не попадает в result', async () => {
            Doc.mockImplementation(() => ({select: jest.fn().mockReturnValue(Promise.resolve({row: [{inforegister_api_key: 'TOPSECRET'}]}))}));
            db.queryDb
                .mockReturnValueOnce(Promise.resolve({data: [{id: 711, missing: ['1K2563758R']}]}))
                .mockReturnValueOnce(Promise.resolve({data: []}));
            const r = await info.processMissingAsutused(11770, 63, 711, {dryRun: true});
            expect(JSON.stringify(r)).not.toContain('TOPSECRET');
        });
    });

    describe('hash auth на /task/getInforegister/ (spec_update_v3)', () => {
        const crypto = require('crypto');
        const makeRes = () => ({send: jest.fn().mockReturnThis(), status: jest.fn().mockReturnThis()});

        afterEach(() => {
            delete process.env.INFOREGISTER_REQUIRE_HASH_BATCH;
        });

        test('(т) без hash -> 401, createLog и БД не вызываются', async () => {
            const res = makeRes();
            await info.main({query: {}, body: {user_id: 11770, rekv_id: 63}, params: {}}, res);
            expect(res.status).toHaveBeenCalledWith(401);
            expect(res.send).toHaveBeenCalledWith(expect.objectContaining({
                status: 401,
                result: 0,
                log_id: null,
                data: {reason: 'unauthorized_hash'}
            }));
            expect(db.queryDb).not.toHaveBeenCalled();
        });

        test('(у) неверный или active=false hash -> 401 без создания лога', async () => {
            const sha = crypto.createHash('sha256').update('real-token', 'utf8').digest('hex');
            db.queryDb.mockReturnValueOnce(Promise.resolve({data: [{tokens: [{token_sha256: sha, user_id: 11770, rekv_id: 63, scopes: ['batch'], active: false}]}]}));
            const res = makeRes();
            await info.main({query: {}, body: {hash: 'real-token'}, params: {}}, res);
            expect(res.status).toHaveBeenCalledWith(401);
            expect(res.send).toHaveBeenCalledWith(expect.objectContaining({data: {reason: 'unauthorized_hash'}, log_id: null}));
            expect(db.queryDb).toHaveBeenCalledTimes(1);
        });

        test('(ф) токен только со scope lookup -> 403 forbidden_scope', async () => {
            const sha = crypto.createHash('sha256').update('lookup-only', 'utf8').digest('hex');
            db.queryDb.mockReturnValueOnce(Promise.resolve({data: [{tokens: [{token_sha256: sha, user_id: 11770, rekv_id: 63, scopes: ['lookup'], active: true}]}]}));
            const res = makeRes();
            await info.main({query: {}, body: {hash: 'lookup-only'}, params: {}}, res);
            expect(res.status).toHaveBeenCalledWith(403);
            expect(res.send).toHaveBeenCalledWith(expect.objectContaining({data: {reason: 'forbidden_scope'}, log_id: null}));
        });

        test('(х) верный hash -> log создаётся от user_id токена, а не из тела, hash не попадает в ответ/console', async () => {
            const secret = 'secret-batch-token-xyz';
            const sha = crypto.createHash('sha256').update(secret, 'utf8').digest('hex');
            const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});
            try {
                db.queryDb
                    .mockReturnValueOnce(Promise.resolve({data: [{tokens: [{token_sha256: sha, user_id: 11770, rekv_id: 63, label: 'ai_task', scopes: ['batch'], active: true}]}]}))
                    .mockReturnValueOnce(Promise.resolve({data: [{id: 801}]}))
                    .mockReturnValue(Promise.resolve({data: []}));
                const res = makeRes();
                await info.main({query: {}, body: {hash: secret, user_id: 9999, rekv_id: 1}, params: {}}, res);
                expect(res.status).toHaveBeenCalledWith(200);
                // createLog вызван с userId и rekvId токена (11770, 63)
                expect(db.queryDb.mock.calls[1][1]).toEqual([63, 11770, 'getInforegister']);
                expect(JSON.stringify(res.send.mock.calls)).not.toContain(secret);
                expect(warnSpy).toHaveBeenCalled();
                expect(JSON.stringify(warnSpy.mock.calls)).not.toContain(secret);
                await wait(30);
            } finally {
                warnSpy.mockRestore();
            }
        });

        test('(ц) INFOREGISTER_REQUIRE_HASH_BATCH=false: без hash работает с warning, с неверным -> 401', async () => {
            process.env.INFOREGISTER_REQUIRE_HASH_BATCH = 'false';
            const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});
            try {
                db.queryDb
                    .mockReturnValueOnce(Promise.resolve({data: [{id: 802}]}))
                    .mockReturnValue(Promise.resolve({data: []}));
                const resOk = makeRes();
                await info.main({query: {}, body: {user_id: 2477, rekv_id: 63}, params: {}}, resOk);
                expect(resOk.status).toHaveBeenCalledWith(200);
                expect(warnSpy).toHaveBeenCalledWith('getInforegister called without hash');

                db.queryDb.mockReturnValueOnce(Promise.resolve({data: [{tokens: []}]}));
                const resBad = makeRes();
                await info.main({query: {}, body: {hash: 'bad-token'}, params: {}}, resBad);
                expect(resBad.status).toHaveBeenCalledWith(401);
                await wait(30);
            } finally {
                warnSpy.mockRestore();
            }
        });
    });
});
