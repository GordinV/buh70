'use strict';

const crypto = require('crypto');
const https = require('https');
const db = require('../libs/db');
db.queryDb = jest.fn();

jest.mock('../classes/DocumentTemplate', () => jest.fn());
const Doc = require('../classes/DocumentTemplate');
const service = require('../libs/inforegisterService');
const lookup = require('../routes/raama/inforegisterLookup');

const makeRes = () => ({send: jest.fn().mockReturnThis(), status: jest.fn().mockReturnThis()});

describe('POST /task/inforegisterLookup/ (ariregisterStore)', () => {
    const validToken = 'lookup-secret-token-123';
    const validSha = crypto.createHash('sha256').update(validToken, 'utf8').digest('hex');

    beforeEach(() => {
        db.queryDb.mockReset();
        Doc.mockReset();
    });

    test('(л) без hash / неверный hash / active=false -> 401, таблица и лог не вызываются', async () => {
        const resNo = makeRes();
        await lookup.main({query: {}, body: {regkood: '11735006'}, params: {}}, resNo);
        expect(resNo.status).toHaveBeenCalledWith(401);
        expect(db.queryDb).not.toHaveBeenCalled();

        db.queryDb.mockReturnValueOnce(Promise.resolve({
            data: [{tokens: [{token_sha256: validSha, user_id: 11770, rekv_id: 63, scopes: ['lookup'], active: false}]}]
        }));
        const resInactive = makeRes();
        await lookup.main({query: {}, body: {hash: validToken, regkood: '11735006'}, params: {}}, resInactive);
        expect(resInactive.status).toHaveBeenCalledWith(401);
        expect(db.queryDb).toHaveBeenCalledTimes(1);
    });

    test('(ф) batch-only токен -> 403 forbidden_scope', async () => {
        db.queryDb.mockReturnValueOnce(Promise.resolve({
            data: [{tokens: [{token_sha256: validSha, user_id: 11770, rekv_id: 63, scopes: ['batch'], active: true}]}]
        }));
        const res = makeRes();
        await lookup.main({query: {}, body: {hash: validToken, regkood: '11735006'}, params: {}}, res);
        expect(res.status).toHaveBeenCalledWith(403);
        expect(res.send).toHaveBeenCalledWith(expect.objectContaining({data: {reason: 'forbidden_scope'}}));
    });

    test('(в) невалидный regkood ("1234") -> 400 без запроса к БД', async () => {
        db.queryDb.mockReturnValueOnce(Promise.resolve({
            data: [{tokens: [{token_sha256: validSha, user_id: 11770, rekv_id: 63, scopes: ['lookup'], active: true}]}]
        }));
        const res = makeRes();
        await lookup.main({query: {}, body: {hash: validToken, regkood: '1234'}, params: {}}, res);
        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.send).toHaveBeenCalledWith(expect.objectContaining({data: expect.objectContaining({reason: 'invalid_reg_code'})}));
        expect(db.queryDb).toHaveBeenCalledTimes(1);
    });

    test('(а, е, ж, и) код есть в таблице -> 200, формат summarizeBundle, source=ariregister, calls_spent=0, нет diff по email/tel и регистру имени, getApiKey и https не вызываются', async () => {
        const httpsSpy = jest.spyOn(https, 'request');
        const apiKeySpy = jest.spyOn(service, 'getApiKey');

        db.queryDb
            .mockReturnValueOnce(Promise.resolve({
                data: [{tokens: [{token_sha256: validSha, user_id: 11770, rekv_id: 63, label: 'ai_task', scopes: ['lookup'], active: true}]}]
            })) // resolveInforegisterToken
            .mockReturnValueOnce(Promise.resolve({data: [{id: 901}]})) // createLog
            .mockReturnValueOnce(Promise.resolve({
                data: [{id: 55, regkood: '11735006', nimetus: 'REGISTER OÜ', aadress: 'Vana tn 1', kmkr: 'EE101339256', email: 'info@ir.ee', tel: '+3727446644', staatus: 1}]
            })) // readLocalAsutus
            .mockReturnValueOnce(Promise.resolve({
                data: [{file_date: '2026-11-17', rows_total: 381556}]
            })) // readMeta
            .mockReturnValueOnce(Promise.resolve({
                data: [{
                    regkood: '11735006',
                    nimi: 'Register OÜ',
                    oiguslik_vorm: 'Osaühing',
                    kmkr_nr: 'EE101339256',
                    staatus_tekst: 'Registrisse kantud',
                    taisaadress: 'Tähe tn 129b, Tartu',
                    ehak_tekst: 'Tartu linn',
                    asukoht: 'Tähe tn 129b',
                    deleted_at: null
                }]
            })) // readByRegkood
            .mockReturnValueOnce(Promise.resolve({data: []})); // endLog

        try {
            const res = makeRes();
            await lookup.main({
                query: {},
                body: {hash: validToken, user_id: 9999, rekv_id: 1, regkood: '11735006', year: 2026},
                params: {}
            }, res);

            expect(res.status).toHaveBeenCalledWith(200);
            const body = res.send.mock.calls[0][0];
            expect(Object.keys(body).sort()).toEqual(['data', 'error_message', 'result', 'status']);
            expect(Object.keys(body.data).sort()).toEqual([
                'asutus_id', 'calls_spent', 'closed', 'company', 'diff', 'fetched_at', 'local', 'registry', 'regkood', 'remaining_year', 'source'
            ]);
            expect(body.data.source).toBe('ariregister');
            expect(body.data.fetched_at).toBe('2026-11-17');
            expect(body.data.asutus_id).toBe(55);
            expect(body.data.calls_spent).toBe(0);
            expect(body.data.remaining_year).toBeNull();
            expect(body.data.closed).toBe(false);
            expect(body.data.registry).toEqual(body.data.company);
            expect(Object.keys(body.data.registry).sort()).toEqual([
                'address', 'businessType', 'contacts', 'latestEmployeeCount', 'latestPeriod', 'name', 'regCode', 'registryStatus', 'vatNumber', 'year'
            ]);
            expect(body.data.diff).toEqual([
                {field: 'aadress', local: 'Vana tn 1', registry: 'Tähe tn 129b, Tartu'}
            ]);
            expect(httpsSpy).not.toHaveBeenCalled();
            expect(apiKeySpy).not.toHaveBeenCalled();
            expect(Doc).not.toHaveBeenCalled();
            expect(JSON.stringify(body)).not.toContain(validToken);
        } finally {
            httpsSpy.mockRestore();
            apiKeySpy.mockRestore();
        }
    });

    test('(б) кода нет в таблице -> 404 not_found', async () => {
        db.queryDb
            .mockReturnValueOnce(Promise.resolve({
                data: [{tokens: [{token_sha256: validSha, user_id: 11770, rekv_id: 63, scopes: ['lookup'], active: true}]}]
            }))
            .mockReturnValueOnce(Promise.resolve({data: [{id: 902}]})) // createLog
            .mockReturnValueOnce(Promise.resolve({data: []})) // readLocalAsutus
            .mockReturnValueOnce(Promise.resolve({data: [{file_date: '2026-11-17', rows_total: 381556}]})) // readMeta
            .mockReturnValueOnce(Promise.resolve({data: []})) // readByRegkood -> miss
            .mockReturnValueOnce(Promise.resolve({data: []})); // endLog

        const res = makeRes();
        await lookup.main({query: {}, body: {hash: validToken, regkood: '11735006'}, params: {}}, res);
        expect(res.status).toHaveBeenCalledWith(404);
        expect(res.send).toHaveBeenCalledWith(expect.objectContaining({
            status: 404,
            data: expect.objectContaining({reason: 'not_found'})
        }));
    });

    test('(г) deleted_at заполнен -> closed=true, diff содержит closed', async () => {
        db.queryDb
            .mockReturnValueOnce(Promise.resolve({
                data: [{tokens: [{token_sha256: validSha, user_id: 11770, rekv_id: 63, scopes: ['lookup'], active: true}]}]
            }))
            .mockReturnValueOnce(Promise.resolve({data: [{id: 903}]}))
            .mockReturnValueOnce(Promise.resolve({
                data: [{id: 55, regkood: '11735006', nimetus: 'Deleted OÜ', staatus: 1}]
            }))
            .mockReturnValueOnce(Promise.resolve({data: [{file_date: '2026-11-17', rows_total: 381556}]}))
            .mockReturnValueOnce(Promise.resolve({
                data: [{regkood: '11735006', nimi: 'Deleted OÜ', staatus_tekst: 'Kustutatud', deleted_at: '2026-11-18T00:00:00Z'}]
            }))
            .mockReturnValueOnce(Promise.resolve({data: []}));

        const res = makeRes();
        await lookup.main({query: {}, body: {hash: validToken, regkood: '11735006'}, params: {}}, res);
        expect(res.status).toHaveBeenCalledWith(200);
        const body = res.send.mock.calls[0][0];
        expect(body.data.closed).toBe(true);
        expect(body.data.diff.some((d) => d.field === 'closed')).toBe(true);
    });

    test('(д) Likvideerimisel -> closed=true', async () => {
        db.queryDb
            .mockReturnValueOnce(Promise.resolve({
                data: [{tokens: [{token_sha256: validSha, user_id: 11770, rekv_id: 63, scopes: ['lookup'], active: true}]}]
            }))
            .mockReturnValueOnce(Promise.resolve({data: [{id: 904}]}))
            .mockReturnValueOnce(Promise.resolve({data: []}))
            .mockReturnValueOnce(Promise.resolve({data: [{file_date: '2026-11-17', rows_total: 381556}]}))
            .mockReturnValueOnce(Promise.resolve({
                data: [{regkood: '11735006', nimi: 'Liq OÜ', staatus_tekst: 'Likvideerimisel', deleted_at: null}]
            }))
            .mockReturnValueOnce(Promise.resolve({data: []}));

        const res = makeRes();
        await lookup.main({query: {}, body: {hash: validToken, regkood: '11735006'}, params: {}}, res);
        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.send.mock.calls[0][0].data.closed).toBe(true);
    });

    test('(з) таблица пуста (ariregister_meta отсутствует) -> 503 registry_not_loaded', async () => {
        db.queryDb
            .mockReturnValueOnce(Promise.resolve({
                data: [{tokens: [{token_sha256: validSha, user_id: 11770, rekv_id: 63, scopes: ['lookup'], active: true}]}]
            }))
            .mockReturnValueOnce(Promise.resolve({data: [{id: 905}]}))
            .mockReturnValueOnce(Promise.resolve({data: []})) // readLocalAsutus
            .mockReturnValueOnce(Promise.resolve({data: []})) // readMeta -> empty
            .mockReturnValueOnce(Promise.resolve({data: []})); // endLog

        const res = makeRes();
        await lookup.main({query: {}, body: {hash: validToken, regkood: '11735006'}, params: {}}, res);
        expect(res.status).toHaveBeenCalledWith(503);
        expect(res.send).toHaveBeenCalledWith(expect.objectContaining({
            status: 503,
            data: expect.objectContaining({reason: 'registry_not_loaded'})
        }));
    });

    test('readLocalAsutus запрашивает (properties->>\'kmkr\') as kmkr, а не голую колонку kmkr', async () => {
        db.queryDb.mockReturnValueOnce(Promise.resolve({data: [{id: 1, regkood: '11735006', kmkr: 'EE101339256'}]}));
        const row = await service.readLocalAsutus('11735006');
        expect(row).not.toBeNull();
        expect(row.kmkr).toBe('EE101339256');
        const sql = db.queryDb.mock.calls[0][0];
        expect(sql).toContain("properties->>'kmkr'");
        expect(sql).not.toMatch(/,\s*kmkr\s*,/);
    });

    test('(ж) not_found + local (1xxx) с эстонским адресом -> HTTP 200, closed=true, registryStatus=Kustutatud', async () => {
        db.queryDb
            .mockReturnValueOnce(Promise.resolve({
                data: [{tokens: [{token_sha256: validSha, user_id: 11770, rekv_id: 63, scopes: ['lookup'], active: true}]}]
            }))
            .mockReturnValueOnce(Promise.resolve({data: [{id: 906}]})) // createLog
            .mockReturnValueOnce(Promise.resolve({
                data: [{id: 77, regkood: '10035608', nimetus: 'Kadunud OÜ', aadress: 'Peetri 3, Narva 20308', staatus: 1}]
            })) // readLocalAsutus
            .mockReturnValueOnce(Promise.resolve({data: [{file_date: '2026-11-18', rows_total: 381641}]})) // readMeta
            .mockReturnValueOnce(Promise.resolve({data: []})) // readByRegkood -> not_found
            .mockReturnValueOnce(Promise.resolve({data: []})); // endLog

        const res = makeRes();
        await lookup.main({query: {}, body: {hash: validToken, regkood: '10035608'}, params: {}}, res);
        expect(res.status).toHaveBeenCalledWith(200);
        const body = res.send.mock.calls[0][0];
        expect(body.data.closed).toBe(true);
        expect(body.data.source).toBe('ariregister');
        expect(body.data.fetched_at).toBe('2026-11-18');
        expect(body.data.registry.registryStatus).toBe('Kustutatud');
        expect(body.data.company.registryStatus).toBe('Kustutatud');
        expect(body.data.registry.name).toBe('Kadunud OÜ');
    });

    test('(е) inforegisterLookup для 10247291 с aadress=null -> HTTP 200, data.closed=true', async () => {
        db.queryDb
            .mockReturnValueOnce(Promise.resolve({
                data: [{tokens: [{token_sha256: validSha, user_id: 11770, rekv_id: 63, scopes: ['lookup'], active: true}]}]
            }))
            .mockReturnValueOnce(Promise.resolve({data: [{id: 907}]})) // createLog
            .mockReturnValueOnce(Promise.resolve({
                data: [{id: 26330, regkood: '10247291', nimetus: 'NARVA BUSSIVEOD AS ', aadress: null, staatus: 1, kehtivus: null}]
            })) // readLocalAsutus
            .mockReturnValueOnce(Promise.resolve({data: [{file_date: '2026-11-18', rows_total: 381641}]})) // readMeta
            .mockReturnValueOnce(Promise.resolve({data: []})) // readByRegkood -> not_found
            .mockReturnValueOnce(Promise.resolve({data: []})); // endLog

        const res = makeRes();
        await lookup.main({query: {}, body: {hash: validToken, regkood: '10247291'}, params: {}}, res);
        expect(res.status).toHaveBeenCalledWith(200);
        const body = res.send.mock.calls[0][0];
        expect(body.data.closed).toBe(true);
        expect(body.data.registry.registryStatus).toBe('Kustutatud');
        expect(body.data.registry.name).toBe('NARVA BUSSIVEOD AS');
    });
});
