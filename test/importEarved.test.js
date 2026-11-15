'use strict';

const db = require('../libs/db');
db.queryDb = jest.fn();

const importEarved = require('../routes/raama/importEarved');

const makeRes = () => ({
    send: jest.fn().mockReturnThis(),
    status: jest.fn().mockReturnThis()
});

const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const inv = (number, asutusid) => ({id: 0, data: {number: number, asutusid: asutusid}});

describe('importEarved unit tests', () => {
    beforeEach(() => {
        jest.clearAllMocks();
        db.queryDb.mockReset();
    });

    test('Частичный импорт: счета с отсутствующим контр-агентом пропускаются, остальные уходят в docs.sp_loe_earved', async () => {
        const req = {query: {}, body: {user_id: 11770, rekv_id: 63, log_id: 400}, params: {}};
        const res = makeRes();

        db.queryDb
            // 0. createLog (flow = docs.sp_loe_earved)
            .mockReturnValueOnce(Promise.resolve({data: [{id: 600}]}))
            // 1. findSourceLogId по log_id (лог getEarved)
            .mockReturnValueOnce(Promise.resolve({data: [{id: 400, flow: 'getEarved', source_log_id: null}]}))
            // 2. readSourceLog: счета и список отсутствующих контр-агентов (changes)
            .mockReturnValueOnce(Promise.resolve({
                data: [{
                    arved: [{rekvId: 63, userId: 11770, count: 2, arved: [inv('N1', 111), inv('N2', 222)]}],
                    changes: [{puuduvad_asutused: '222', vastutav_isik: 'x', email: 'a@b.ee'}]
                }]
            }))
            // 3. docs.sp_loe_earved для батча
            .mockReturnValueOnce(Promise.resolve({
                data: [{error_code: 0, result: 1, error_message: 'Arve nr.N1 importeeritud (id: 55)'}]
            }))
            // 4. endLog
            .mockReturnValueOnce(Promise.resolve({data: []}));

        await importEarved.main(req, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 200,
                result: 1,
                log_id: 600,
                data: expect.objectContaining({action: 'importEarved', status: 'STARTED', log_id: 600})
            })
        );

        await wait(50);

        // flow лога импорта сохранен прежним (используется docs.get_arve_kinnitaja)
        expect(db.queryDb.mock.calls[0][1]).toEqual([63, 11770, 'docs.sp_loe_earved']);

        // в процедуру ушел только счет N1 (контр-агент 222 пропущен)
        expect(db.queryDb.mock.calls[3][0]).toContain('docs.sp_loe_earved');
        expect(db.queryDb.mock.calls[3][1][0]).toBe(11770);
        expect(db.queryDb.mock.calls[3][1][1]).toContain('N1');
        expect(db.queryDb.mock.calls[3][1][1]).not.toContain('N2');

        // endLog: success, пропущенные счета и рег.коды в result, сообщение содержит id документов (для get_arve_kinnitaja)
        expect(db.queryDb.mock.calls[4][1][0]).toBe('success');
        const resultJson = JSON.parse(db.queryDb.mock.calls[4][1][2]);
        expect(resultJson.totalFetched).toBe(2);
        expect(resultJson.totalImported).toBe(1);
        expect(resultJson.totalSkipped).toBe(1);
        expect(resultJson.skipped).toEqual([{number: 'N2', asutusid: '222', rekvId: 63}]);
        expect(resultJson.missing).toEqual(['222']);
        expect(resultJson.invoiceNumbers).toEqual(['N1']);
        expect(resultJson.source_log_id).toBe(400);
        expect(db.queryDb.mock.calls[4][1][3]).toContain('(id: 55)');
        expect(db.queryDb.mock.calls[4][1][3]).toContain('Vahele jäetud 1 arvet');
        expect(db.queryDb.mock.calls[4][1][4]).toBe(600);
    });

    test('Все контр-агенты отсутствуют: процедура не вызывается, лог закрывается success с 0 импортированных', async () => {
        const req = {query: {}, body: {user_id: 11770, log_id: 400}, params: {}};
        const res = makeRes();

        db.queryDb
            .mockReturnValueOnce(Promise.resolve({data: [{id: 601}]})) // createLog
            .mockReturnValueOnce(Promise.resolve({data: [{id: 400, flow: 'getEarved', source_log_id: null}]}))
            .mockReturnValueOnce(Promise.resolve({
                data: [{
                    arved: [{rekvId: 63, userId: 11770, count: 1, arved: [inv('N2', 222)]}],
                    changes: [{puuduvad_asutused: '222'}]
                }]
            }))
            .mockReturnValueOnce(Promise.resolve({data: []})); // endLog

        await importEarved.main(req, res);
        await wait(50);

        expect(db.queryDb).toHaveBeenCalledTimes(4);
        expect(db.queryDb.mock.calls[3][1][0]).toBe('success');
        const resultJson = JSON.parse(db.queryDb.mock.calls[3][1][2]);
        expect(resultJson.totalImported).toBe(0);
        expect(resultJson.totalSkipped).toBe(1);
        expect(resultJson.missing).toEqual(['222']);
    });

    test('Нет лога getEarved: штатный успех, процедура не вызывается', async () => {
        const req = {query: {}, body: {user_id: 11770}, params: {}};
        const res = makeRes();

        db.queryDb
            .mockReturnValueOnce(Promise.resolve({data: [{id: 602}]})) // createLog
            .mockReturnValueOnce(Promise.resolve({data: []})) // поиск последнего лога getEarved
            .mockReturnValueOnce(Promise.resolve({data: []})); // endLog

        await importEarved.main(req, res);
        await wait(50);

        expect(db.queryDb).toHaveBeenCalledTimes(3);
        expect(db.queryDb.mock.calls[2][1][0]).toBe('success');
        const resultJson = JSON.parse(db.queryDb.mock.calls[2][1][2]);
        expect(resultJson.totalImported).toBe(0);
        expect(resultJson.source_log_id).toBeNull();
    });

    test('Ошибка docs.sp_loe_earved: лог закрывается failed', async () => {
        const req = {query: {}, body: {user_id: 11770, log_id: 400}, params: {}};
        const res = makeRes();

        db.queryDb
            .mockReturnValueOnce(Promise.resolve({data: [{id: 603}]})) // createLog
            .mockReturnValueOnce(Promise.resolve({data: [{id: 400, flow: 'getEarved', source_log_id: null}]}))
            .mockReturnValueOnce(Promise.resolve({
                data: [{
                    arved: [{rekvId: 63, userId: 11770, count: 1, arved: [inv('N1', 111)]}],
                    changes: []
                }]
            }))
            .mockReturnValueOnce(Promise.resolve({data: [{error_code: 1, result: 0, error_message: 'Viga: test'}]}))
            .mockReturnValueOnce(Promise.resolve({data: []})); // endLog failed

        await importEarved.main(req, res);
        await wait(50);

        expect(db.queryDb.mock.calls[4][1][0]).toBe('failed');
        expect(db.queryDb.mock.calls[4][1][1]).toContain('Viga: test');
    });

    const runWithProcedureRow = async (row, logId) => {
        const req = {query: {}, body: {user_id: 11770, log_id: 400}, params: {}};
        const res = makeRes();
        db.queryDb
            .mockReturnValueOnce(Promise.resolve({data: [{id: logId}]})) // createLog
            .mockReturnValueOnce(Promise.resolve({data: [{id: 400, flow: 'getEarved', source_log_id: null}]}))
            .mockReturnValueOnce(Promise.resolve({
                data: [{
                    arved: [{rekvId: 63, userId: 11770, count: 2, arved: [inv('N1', 111), inv('N2', 112)]}],
                    changes: []
                }]
            }))
            .mockReturnValueOnce(Promise.resolve({data: [row]}))
            .mockReturnValueOnce(Promise.resolve({data: []})); // endLog
        await importEarved.main(req, res);
        await wait(50);
        return db.queryDb.mock.calls[4][1];
    };

    test('Частичный успех: один счет с ошибкой, другой импортирован -> success, imported и errors в result', async () => {
        const params = await runWithProcedureRow({
            error_code: 0,
            result: 1,
            error_message: 'Arve nr.N1 importeeritud (id: 55); Arve nr.N2 viga: asutus ei leidnud; ',
            imported: [{doc_id: 55, number: 'N1', rekv_id: 63}],
            errors: [{number: 'N2', asutusid: '112', error: 'Viga: asutus ei leidnud'}]
        }, 610);

        expect(params[0]).toBe('success');
        const resultJson = JSON.parse(params[2]);
        expect(resultJson.totalImported).toBe(1);
        expect(resultJson.totalFailed).toBe(1);
        expect(resultJson.imported).toEqual([{doc_id: 55, number: 'N1', rekv_id: 63}]);
        expect(resultJson.errors[0].number).toBe('N2');
        expect(params[5]).toBeNull(); // retryable не пишется при success
    });

    test('Все счета с ошибкой (0 импортированных) -> failed, retryable=false', async () => {
        const params = await runWithProcedureRow({
            error_code: 0,
            result: 0,
            error_message: 'viga',
            imported: [],
            errors: [{number: 'N1', error: 'x'}, {number: 'N2', error: 'y'}]
        }, 611);

        expect(params[0]).toBe('failed');
        expect(params[1]).toContain('vigu: 2');
        expect(JSON.parse(params[2]).totalFailed).toBe(2);
        expect(JSON.parse(params[5])).toEqual({retryable: false});
    });

    test('Исключение (БД недоступна) -> failed, retryable=true; Puudub õigused -> retryable=false', async () => {
        const params = await runWithProcedureRow({error_code: 5, result: 0, error_message: 'connection reset'}, 612);
        expect(params[0]).toBe('failed');
        expect(JSON.parse(params[5])).toEqual({retryable: true});

        db.queryDb.mockReset();
        const params2 = await runWithProcedureRow({error_code: 4, result: 0, error_message: 'Puudub õigused'}, 613);
        expect(params2[0]).toBe('failed');
        expect(JSON.parse(params2[5])).toEqual({retryable: false});
    });

    test('splitByMissingAsutus делит счета по всем батчам и обрабатывает пустой asutusid', () => {
        const split = importEarved.splitByMissingAsutus(
            [
                {rekvId: 63, userId: 1, arved: [inv('A', 111), inv('B', 222)]},
                {rekvId: 119, userId: 2, arved: [inv('C', 222), inv('D', '')]}
            ],
            {'222': true}
        );
        expect(split.totalFetched).toBe(4);
        expect(split.skipped.map((s) => s.number)).toEqual(['B', 'C']);
        expect(split.batches).toHaveLength(2);
        expect(split.batches[0].json.map((i) => i.data.number)).toEqual(['A']);
        expect(split.batches[1].json.map((i) => i.data.number)).toEqual(['D']);
    });
});
