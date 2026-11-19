'use strict';

const crypto = require('crypto');
const db = require('../libs/db');
db.queryDb = jest.fn();

const kehtivusService = require('../libs/asutusKehtivusService');
const route = require('../routes/raama/checkAsutusKehtivus');

function sha256(token) {
    return crypto.createHash('sha256').update(token, 'utf8').digest('hex');
}

function makeRes() {
    const res = {
        statusCode: 200,
        body: null,
        status: jest.fn(function (code) {
            res.statusCode = code;
            return res;
        }),
        send: jest.fn(function (payload) {
            res.body = payload;
            return res;
        })
    };
    return res;
}

function wait(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

describe('POST /task/checkAsutusKehtivus/', () => {
    const syncToken = 'sync-secret-token';
    const lookupToken = 'lookup-only-token';

    beforeEach(() => {
        db.queryDb.mockReset();
    });

    test('(з) 400 invalid_max_close, 401 unauthorized, 403 без scope sync, 409 already_running, 200 dry_run=true по умолчанию', async () => {
        db.queryDb.mockImplementation(async () => ({
            result: 1,
            data: [{
                tokens: [
                    {token_sha256: sha256(lookupToken), user_id: 2477, rekv_id: 63, scopes: ['lookup'], active: true},
                    {token_sha256: sha256(syncToken), user_id: 11770, rekv_id: 63, scopes: ['sync'], active: true}
                ]
            }]
        }));

        // 400 (< 0 и > 5000)
        const res400 = makeRes();
        await route.main({body: {hash: syncToken, max_close: -5}, query: {}, params: {}}, res400);
        expect(res400.statusCode).toBe(400);
        expect(res400.body.data.reason).toBe('invalid_max_close');

        const res400Over = makeRes();
        await route.main({body: {hash: syncToken, max_close: 5001}, query: {}, params: {}}, res400Over);
        expect(res400Over.statusCode).toBe(400);
        expect(res400Over.body.data.reason).toBe('invalid_max_close');

        // 401
        const res401 = makeRes();
        await route.main({body: {hash: 'bad'}, query: {}, params: {}}, res401);
        expect(res401.statusCode).toBe(401);

        // 403
        const res403 = makeRes();
        await route.main({body: {hash: lookupToken}, query: {}, params: {}}, res403);
        expect(res403.statusCode).toBe(403);
        expect(res403.body.data.reason).toBe('forbidden_scope');

        // 409
        const spyLockBusy = jest.spyOn(kehtivusService, 'tryAcquireLock').mockImplementation(async () => null);
        try {
            const res409 = makeRes();
            await route.main({body: {hash: syncToken}, query: {}, params: {}}, res409);
            expect(res409.statusCode).toBe(409);
            expect(res409.body.data.reason).toBe('already_running');
        } finally {
            spyLockBusy.mockRestore();
        }

        // 200 + dry_run=true по умолчанию
        db.queryDb.mockImplementation(async (sql) => {
            if (sql.indexOf('INFOREGISTER_TOKENS') !== -1) {
                return {
                    result: 1,
                    data: [{tokens: [{token_sha256: sha256(syncToken), user_id: 11770, rekv_id: 63, scopes: ['sync'], active: true}]}]
                };
            }
            if (sql.indexOf('insert into ou.logs') !== -1) {
                return {result: 1, data: [{id: 950}]};
            }
            return {result: 1, data: []};
        });

        const fakeLock = {client: {query: jest.fn(), end: jest.fn()}};
        const spyLock = jest.spyOn(kehtivusService, 'tryAcquireLock').mockImplementation(async () => fakeLock);
        const spyRelease = jest.spyOn(kehtivusService, 'releaseLock').mockImplementation(async () => {});
        const spyRun = jest.spyOn(kehtivusService, 'runKehtivusCheck').mockImplementation(async () => ({
            status: 'success',
            dry_run: true,
            candidates_total: 0,
            closed: [],
            would_close: [],
            totalClosed: 0,
            totalErrors: 0
        }));

        try {
            const res200 = makeRes();
            await route.main({body: {hash: syncToken}, query: {}, params: {}}, res200);
            expect(res200.statusCode).toBe(200);
            expect(res200.body.log_id).toBe(950);
            expect(res200.body.data.dry_run).toBe(true);
            await wait(30);
            expect(spyRun).toHaveBeenCalledWith({dryRun: true, maxClose: 100, userId: 11770});
            expect(spyRelease).toHaveBeenCalledWith(fakeLock);
        } finally {
            spyLock.mockRestore();
            spyRelease.mockRestore();
            spyRun.mockRestore();
        }
    });

    test('(л-с) email: DRY_RUN_EMAILS / DEFAULT_EMAILS, extra_emails, CSV >200, SMTP error, защита от дубля по logId', async () => {
        const mailer = require('../routes/raama/sendFinBitReport');
        const spySmtp = jest.spyOn(mailer, 'getSmtpConfig').mockImplementation(async () => ({host: 'smtp.test'}));
        const spySend = jest.spyOn(mailer, 'sendHtmlEmail').mockImplementation(async () => ({messageId: 'msg-1'}));

        try {
            // (м) 0 кандидатов / registry_stale -> письмо не отправляется
            const mailNone = await route.notifyKehtivusResult(
                {status: 'success', dry_run: true, candidates_total: 0, totalClosed: 0, totalErrors: 0},
                11770,
                []
            );
            expect(mailNone.sent).toBe(false);
            expect(mailNone.skipped).toBe('nothing_to_report');

            const mailStale = await route.notifyKehtivusResult(
                {status: 'skipped', reason: 'registry_stale'},
                11770,
                []
            );
            expect(mailStale.sent).toBe(false);
            expect(mailStale.skipped).toBe('registry_stale');
            expect(spySend).not.toHaveBeenCalled();

            // (л, н) dry_run без extra_emails -> DRY_RUN_EMAILS (1 адрес), >200 строк -> CSV attachment
            const manyCandidates = [];
            for (let i = 0; i < 205; i++) {
                manyCandidates.push({
                    regkood: String(10000000 + i),
                    nimetus: `Firma ${i} OÜ`,
                    aadress: 'Narva',
                    reason: 'not_in_registry',
                    old_kehtivus: null,
                    kehtivus: '2026-11-19'
                });
            }
            const mailDry = await route.notifyKehtivusResult(
                {
                    status: 'success',
                    dry_run: true,
                    registry_file_date: '2026-11-19',
                    candidates_total: 205,
                    would_close: manyCandidates,
                    totalClosed: 0,
                    totalErrors: 0
                },
                11770,
                []
            );
            expect(mailDry.sent).toBe(true);
            expect(mailDry.recipients).toEqual(route.DRY_RUN_EMAILS);
            expect(spySend).toHaveBeenCalledTimes(1);
            expect(spySend.mock.calls[0][1]).toContain('[DRY RUN]');
            expect(spySend.mock.calls[0][6].length).toBe(1);
            expect(spySend.mock.calls[0][6][0].filename).toBe('asutuste_kehtivus.csv');

            // (л) реальное закрытие без extra_emails -> DEFAULT_EMAILS (3 адреса)
            const mailLive = await route.notifyKehtivusResult(
                {
                    status: 'success',
                    dry_run: false,
                    registry_file_date: '2026-11-19',
                    candidates_total: 1,
                    closed: [{regkood: '10035608', nimetus: 'Osaühing H.Uuetalu <Test>', aadress: 'Narva', reason: 'not_in_registry', old_kehtivus: null, kehtivus: '2026-11-19'}],
                    totalClosed: 1,
                    totalErrors: 0
                },
                11770,
                []
            );
            expect(mailLive.sent).toBe(true);
            expect(mailLive.recipients).toEqual(route.DEFAULT_EMAILS);
            expect(spySend.mock.calls[1][1]).toContain('suletud 1 kaarti');
            expect(spySend.mock.calls[1][3]).toContain('Osaühing H.Uuetalu &lt;Test&gt;');

            // (л) extra_emails заменяет список получателей
            const mailCustom = await route.notifyKehtivusResult(
                {
                    status: 'failed',
                    reason: 'too_many_candidates',
                    dry_run: false,
                    candidates_total: 150,
                    would_close: [{regkood: '10247291', nimetus: 'NARVA BUSSIVEOD AS', reason: 'not_in_registry', kehtivus: '2026-11-19'}],
                    totalClosed: 0,
                    totalErrors: 0
                },
                11770,
                ['custom@narva.ee']
            );
            expect(mailCustom.sent).toBe(true);
            expect(mailCustom.recipients).toEqual(['custom@narva.ee']);
            expect(spySend.mock.calls[2][1]).toContain('liiga palju kandidaate');

            // (п) повторный запуск по тому же logId -> skipped duplicate
            db.queryDb.mockReturnValueOnce(Promise.resolve({data: [{mail: {sent: true}}]}));
            const mailDup = await route.notifyKehtivusResult(
                {
                    status: 'success',
                    dry_run: false,
                    candidates_total: 1,
                    closed: [{regkood: '10247291', nimetus: 'Test', kehtivus: '2026-11-19'}],
                    totalClosed: 1,
                    totalErrors: 0
                },
                11770,
                [],
                null,
                999
            );
            expect(mailDup.sent).toBe(false);
            expect(mailDup.skipped).toBe('duplicate');

            // (о) ошибка SMTP -> mail.error заполнен, исключение не бросается
            spySend.mockImplementationOnce(async () => {
                throw new Error('SMTP connection refused');
            });
            const mailErr = await route.notifyKehtivusResult(
                {
                    status: 'success',
                    dry_run: false,
                    candidates_total: 1,
                    closed: [{regkood: '10247291', nimetus: 'Test', kehtivus: '2026-11-19'}],
                    totalClosed: 1,
                    totalErrors: 0
                },
                11770,
                ['test@narva.ee']
            );
            expect(mailErr.sent).toBe(false);
            expect(mailErr.error).toBe('SMTP connection refused');
        } finally {
            spySmtp.mockRestore();
            spySend.mockRestore();
        }
    });
});
