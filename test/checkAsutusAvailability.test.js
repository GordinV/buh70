'use strict';

const db = require('../libs/db');
db.queryDb = jest.fn();

jest.mock('../routes/raama/sendFinBitReport', () => ({
    getSmtpConfig: jest.fn(),
    sendHtmlEmail: jest.fn(),
    escapeHtml: (t) => String(t === undefined || t === null ? '' : t)
}));

const mailer = require('../routes/raama/sendFinBitReport');
const check = require('../routes/raama/checkAsutusAvailability');

const makeRes = () => ({
    send: jest.fn().mockReturnThis(),
    status: jest.fn().mockReturnThis()
});

const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

describe('checkAsutusAvailability unit tests', () => {
    beforeEach(() => {
        jest.clearAllMocks();
        db.queryDb.mockReset();
        mailer.getSmtpConfig.mockReset();
        mailer.getSmtpConfig.mockReturnValue(Promise.resolve({host: 'smtp'}));
        mailer.sendHtmlEmail.mockReset();
        mailer.sendHtmlEmail.mockReturnValue(Promise.resolve({messageId: '<m1>'}));
    });

    test('Есть отсутствующие контр-агенты: лог создан, процедура вызвана, рег.коды извлечены из changes и сохранены в result', async () => {
        const req = {query: {}, body: {user_id: 11770, rekv_id: 63}, params: {}};
        const res = makeRes();

        db.queryDb
            // 0. createLog
            .mockReturnValueOnce(Promise.resolve({data: [{id: 500}]}))
            // 1. поиск последнего лога getEarved
            .mockReturnValueOnce(Promise.resolve({data: [{id: 400}]}))
            // 2. libs.check_asutus_availibility
            .mockReturnValueOnce(Promise.resolve({data: [{error_code: 0, result: 2, error_message: 'Leidnud puuduvad asutused'}]}))
            // 3. чтение ou.logs.changes
            .mockReturnValueOnce(Promise.resolve({
                data: [{
                    changes: [
                        {puuduvad_asutused: '16077631', vastutav_isik: 'svetlana.tsaikina', email: 'a@b.ee'},
                        {puuduvad_asutused: '10000001', vastutav_isik: 'svetlana.tsaikina', email: 'a@b.ee'}
                    ]
                }]
            }))
            // 4. проверка дубля извещения
            .mockReturnValueOnce(Promise.resolve({data: [{asutus_mail: null}]}))
            // 5. отметка о отправке на логе getEarved
            .mockReturnValueOnce(Promise.resolve({data: []}))
            // 6. endLog
            .mockReturnValueOnce(Promise.resolve({data: []}));

        await check.main(req, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 200,
                result: 1,
                log_id: 500,
                data: expect.objectContaining({action: 'checkAsutusAvailability', status: 'STARTED', log_id: 500})
            })
        );

        await wait(50);

        // createLog: flow = checkAsutusAvailability, user_id = 11770
        expect(db.queryDb.mock.calls[0][0]).toContain('insert into ou.logs');
        expect(db.queryDb.mock.calls[0][1]).toEqual([63, 11770, 'checkAsutusAvailability']);

        // поиск сырого лога по flow getEarved
        expect(db.queryDb.mock.calls[1][1][0]).toBe('getEarved');

        // вызов процедуры с id сырого лога
        expect(db.queryDb.mock.calls[2][0]).toContain('libs.check_asutus_availibility');
        expect(db.queryDb.mock.calls[2][1]).toEqual([11770, 400]);

        // endLog: success, result содержит missing
        expect(db.queryDb.mock.calls[6][0]).toContain('update ou.logs');
        expect(db.queryDb.mock.calls[6][1][0]).toBe('success');
        expect(db.queryDb.mock.calls[6][1][1]).toBeNull();
        const resultJson = JSON.parse(db.queryDb.mock.calls[6][1][2]);
        expect(resultJson.missing).toEqual(['16077631', '10000001']);
        expect(resultJson.totalMissing).toBe(2);
        expect(resultJson.source_log_id).toBe(400);
        expect(db.queryDb.mock.calls[6][1][3]).toContain('16077631');
        expect(db.queryDb.mock.calls[6][1][4]).toBe(500);

        // письмо: адрес из changes + копия, таблица с рег.кодами
        expect(mailer.sendHtmlEmail).toHaveBeenCalledTimes(1);
        const mailArgs = mailer.sendHtmlEmail.mock.calls[0];
        expect(mailArgs[0]).toEqual(['a@b.ee', 'vladislav.gordin@bs2.ee']);
        expect(mailArgs[3]).toContain('16077631');
        expect(mailArgs[3]).toContain('10000001');

        // лог письма в propertis.mail (6-й параметр endLog) и отметка на логе getEarved
        const mailLog = JSON.parse(db.queryDb.mock.calls[6][1][5]);
        expect(mailLog.sent).toBe(true);
        expect(mailLog.recipients).toEqual(['a@b.ee', 'vladislav.gordin@bs2.ee']);
        expect(db.queryDb.mock.calls[5][1][1]).toBe(400);
    });

    test('Лог getEarved за период не найден: штатный успех с 0 отсутствующих, процедура не вызывается', async () => {
        const req = {query: {}, body: {user_id: 11770}, params: {}};
        const res = makeRes();

        db.queryDb
            .mockReturnValueOnce(Promise.resolve({data: [{id: 501}]})) // createLog
            .mockReturnValueOnce(Promise.resolve({data: []})) // поиск лога getEarved
            .mockReturnValueOnce(Promise.resolve({data: []})); // endLog

        await check.main(req, res);
        await wait(50);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(db.queryDb).toHaveBeenCalledTimes(3);
        expect(db.queryDb.mock.calls[2][1][0]).toBe('success');
        const resultJson = JSON.parse(db.queryDb.mock.calls[2][1][2]);
        expect(resultJson.totalMissing).toBe(0);
        expect(resultJson.missing).toEqual([]);
        expect(resultJson.source_log_id).toBeNull();
    });

    test('Передан log_id основного лога docs.sp_loe_earved: берется result.source_log_id', async () => {
        const req = {query: {}, body: {user_id: 11770, rekv_id: 63, log_id: 8546660}, params: {}};
        const res = makeRes();

        db.queryDb
            .mockReturnValueOnce(Promise.resolve({data: [{id: 502}]})) // createLog
            .mockReturnValueOnce(Promise.resolve({data: [{id: 8546660, flow: 'docs.sp_loe_earved', source_log_id: '8546659'}]}))
            .mockReturnValueOnce(Promise.resolve({data: [{error_code: 0, result: 0, error_message: null}]})) // процедура
            .mockReturnValueOnce(Promise.resolve({data: [{changes: []}]})) // changes
            .mockReturnValueOnce(Promise.resolve({data: []})); // endLog

        await check.main(req, res);
        await wait(50);

        expect(db.queryDb.mock.calls[1][1]).toEqual([8546660]);
        expect(db.queryDb.mock.calls[2][1]).toEqual([11770, 8546659]);
        const resultJson = JSON.parse(db.queryDb.mock.calls[4][1][2]);
        expect(resultJson.totalMissing).toBe(0);
        expect(resultJson.error_message).toBe('Kõik asutused on olemas');
    });

    test('Процедура вернула error_code != 0: лог закрывается со статусом failed', async () => {
        const req = {query: {}, body: {user_id: 11770}, params: {}};
        const res = makeRes();

        db.queryDb
            .mockReturnValueOnce(Promise.resolve({data: [{id: 503}]})) // createLog
            .mockReturnValueOnce(Promise.resolve({data: [{id: 400}]})) // поиск лога
            .mockReturnValueOnce(Promise.resolve({data: [{error_code: 1, result: 0, error_message: 'Puudub log_id'}]})) // процедура
            .mockReturnValueOnce(Promise.resolve({data: []})); // endLog failed

        await check.main(req, res);
        await wait(50);

        expect(db.queryDb.mock.calls[3][1][0]).toBe('failed');
        expect(db.queryDb.mock.calls[3][1][1]).toContain('Puudub log_id');
    });

    describe('notifyMissingAsutused', () => {
        const checkResult = {
            totalMissing: 1,
            missing: ['16598086'],
            source_log_id: 400,
            details: [{puuduvad_asutused: '16598086', email: 'x@narva.ee'}]
        };

        test('Не шлет письмо, если отсутствующих нет', async () => {
            const r = await check.notifyMissingAsutused({totalMissing: 0, missing: [], source_log_id: 400}, 11770);
            expect(r).toBeNull();
            expect(mailer.sendHtmlEmail).not.toHaveBeenCalled();
        });

        test('Дубль: письмо на тот же лог getEarved не отправляется повторно', async () => {
            db.queryDb.mockReturnValueOnce(Promise.resolve({data: [{asutus_mail: {sent: true}}]}));
            const r = await check.notifyMissingAsutused(checkResult, 11770);
            expect(r.skipped).toBe('duplicate');
            expect(r.sent).toBe(false);
            expect(mailer.sendHtmlEmail).not.toHaveBeenCalled();
        });

        test('Ошибка SMTP не бросает исключение и фиксируется в mail.error', async () => {
            db.queryDb.mockReturnValueOnce(Promise.resolve({data: [{asutus_mail: null}]}));
            mailer.sendHtmlEmail.mockReturnValueOnce(Promise.reject(new Error('ETIMEDOUT')));
            const r = await check.notifyMissingAsutused(checkResult, 11770);
            expect(r.sent).toBe(false);
            expect(r.error).toBe('ETIMEDOUT');
            expect(db.queryDb).toHaveBeenCalledTimes(1); // отметка об отправке не ставится
        });

        test('Дополнительные адреса из параметра заменяют адрес по умолчанию, дубли убираются', () => {
            expect(check.collectRecipients(checkResult.details, ['X@narva.ee', 'z@bs2.ee']))
                .toEqual(['x@narva.ee', 'z@bs2.ee']);
            expect(check.parseEmails('a@b.ee; a@b.ee, bad')).toEqual(['a@b.ee']);
        });
    });
});
