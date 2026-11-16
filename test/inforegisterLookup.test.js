'use strict';

const crypto = require('crypto');
const db = require('../libs/db');
db.queryDb = jest.fn();

jest.mock('../classes/DocumentTemplate', () => jest.fn());
const Doc = require('../classes/DocumentTemplate');
const lookup = require('../routes/raama/inforegisterLookup');

const makeRes = () => ({send: jest.fn().mockReturnThis(), status: jest.fn().mockReturnThis()});

describe('POST /task/inforegisterLookup/', () => {
    const validToken = 'lookup-secret-token-123';
    const validSha = crypto.createHash('sha256').update(validToken, 'utf8').digest('hex');

    beforeEach(() => {
        db.queryDb.mockReset();
        Doc.mockReset();
        Doc.mockImplementation(() => ({
            select: jest.fn().mockReturnValue(Promise.resolve({row: [{inforegister_api_key: 'API_SECRET_KEY'}]}))
        }));
    });

    test('(л) без hash / неверный hash / active=false -> 401, кэш и реестр не вызываются', async () => {
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

    test('(в) невалидный regkood ("1234") -> 400 без вызова реестра', async () => {
        db.queryDb.mockReturnValueOnce(Promise.resolve({
            data: [{tokens: [{token_sha256: validSha, user_id: 11770, rekv_id: 63, scopes: ['lookup'], active: true}]}]
        }));
        const res = makeRes();
        await lookup.main({query: {}, body: {hash: validToken, regkood: '1234'}, params: {}}, res);
        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.send).toHaveBeenCalledWith(expect.objectContaining({data: expect.objectContaining({reason: 'invalid_reg_code'})}));
        expect(db.queryDb).toHaveBeenCalledTimes(1);
    });

    test('(а, м, н, р, с) верный hash подставляет user_id/rekv_id из токена, возвращает local + registry + diff из кэша и не светит hash', async () => {
        db.queryDb
            .mockReturnValueOnce(Promise.resolve({
                data: [{tokens: [{token_sha256: validSha, user_id: 11770, rekv_id: 63, label: 'ai_task', scopes: ['lookup'], active: true}]}]
            }))
            .mockReturnValueOnce(Promise.resolve({data: [{id: 901}]})) // createLog
            .mockReturnValueOnce(Promise.resolve({
                data: [{id: 55, regkood: '11735006', nimetus: 'REGISTER OÜ', aadress: 'Vana tn 1', kmkr: 'EE101339256', email: 'info@ir.ee', tel: '+3727446644', staatus: 1}]
            })) // readLocalAsutus
            .mockReturnValueOnce(Promise.resolve({
                data: [{
                    payload: {
                        name: 'REGISTER OÜ',
                        registryStatus: 'Registrisse kantud',
                        vatNumber: 'EE101339256',
                        address: {fullAddress: 'Tähe tn 129b, Tartu'},
                        contacts: {emails: ['info@ir.ee'], phones: ['+3727446644']}
                    },
                    negative: false,
                    fetched_at: '2026-11-16T08:00:00.000Z'
                }]
            })) // cache get
            .mockReturnValueOnce(Promise.resolve({data: []})); // endLog

        const res = makeRes();
        await lookup.main({
            query: {},
            body: {hash: validToken, user_id: 9999, rekv_id: 1, regkood: '11735006'},
            params: {}
        }, res);

        expect(res.status).toHaveBeenCalledWith(200);
        const body = res.send.mock.calls[0][0];
        expect(body.data.source).toBe('cache');
        expect(body.data.asutus_id).toBe(55);
        expect(body.data.calls_spent).toBe(0);
        expect(body.data.diff).toEqual([
            {field: 'aadress', local: 'Vana tn 1', registry: 'Tähe tn 129b, Tartu'}
        ]);
        expect(db.queryDb.mock.calls[1][1]).toEqual([63, 11770, 'inforegisterLookup']);
        expect(JSON.stringify(body)).not.toContain(validToken);
        expect(JSON.stringify(body)).not.toContain('API_SECRET_KEY');
        expect(JSON.stringify(db.queryDb.mock.calls)).not.toContain(validToken);
    });

    test('(д) cache_only без кэша -> 404 dry_run_no_spend', async () => {
        db.queryDb
            .mockReturnValueOnce(Promise.resolve({
                data: [{tokens: [{token_sha256: validSha, user_id: 11770, rekv_id: 63, scopes: ['lookup'], active: true}]}]
            }))
            .mockReturnValueOnce(Promise.resolve({data: [{id: 902}]})) // createLog
            .mockReturnValueOnce(Promise.resolve({data: []})) // readLocalAsutus
            .mockReturnValueOnce(Promise.resolve({data: []})) // cache get -> miss
            .mockReturnValueOnce(Promise.resolve({data: []})); // endLog

        const res = makeRes();
        await lookup.main({query: {}, body: {hash: validToken, regkood: '11735006', cache_only: true}, params: {}}, res);
        expect(res.status).toHaveBeenCalledWith(404);
        expect(res.send).toHaveBeenCalledWith(expect.objectContaining({
            status: 404,
            data: expect.objectContaining({reason: 'dry_run_no_spend'})
        }));
    });

    test('(е) нет API-ключа -> 503 no_api_key', async () => {
        Doc.mockImplementation(() => ({
            select: jest.fn().mockReturnValue(Promise.resolve({row: [{inforegister_api_key: ''}]}))
        }));
        db.queryDb
            .mockReturnValueOnce(Promise.resolve({
                data: [{tokens: [{token_sha256: validSha, user_id: 11770, rekv_id: 63, scopes: ['lookup'], active: true}]}]
            }))
            .mockReturnValueOnce(Promise.resolve({data: [{id: 903}]})) // createLog
            .mockReturnValueOnce(Promise.resolve({data: []})) // readLocalAsutus
            .mockReturnValueOnce(Promise.resolve({data: []})) // cache get -> miss
            .mockReturnValueOnce(Promise.resolve({data: []})); // endLog

        const res = makeRes();
        await lookup.main({query: {}, body: {hash: validToken, regkood: '11735006'}, params: {}}, res);
        expect(res.status).toHaveBeenCalledWith(503);
        expect(res.send).toHaveBeenCalledWith(expect.objectContaining({
            status: 503,
            data: expect.objectContaining({reason: 'no_api_key'})
        }));
    });
});
