'use strict';

const crypto = require('crypto');
const fs = require('fs');
const http = require('http');
const os = require('os');
const path = require('path');
const {EventEmitter} = require('events');
const {Readable} = require('stream');

const db = require('../libs/db');
db.queryDb = jest.fn();

const inforegisterService = require('../libs/inforegisterService');
const ariregisterSync = require('../libs/ariregisterSync');
const syncRoute = require('../routes/raama/syncAriregister');

function wait(ms) {
    return new Promise(function (resolve) {
        setTimeout(resolve, ms);
    });
}

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

const CSV_HEADER = [
    'nimi',
    'ariregistri_kood',
    'ettevotja_oiguslik_vorm',
    'ettevotja_oigusliku_vormi_alaliik',
    'kmkr_nr',
    'ettevotja_staatus',
    'ettevotja_staatus_tekstina',
    'ettevotja_esmakande_kpv',
    'ettevotja_aadress',
    'asukoht_ettevotja_aadressis',
    'asukoha_ehak_kood',
    'asukoha_ehak_tekstina',
    'indeks_ettevotja_aadressis',
    'ads_adr_id',
    'ads_ads_oid',
    'ads_normaliseeritud_taisaadress',
    'teabesysteemi_link'
].join(';');

function streamFromText(text) {
    return Readable.from([Buffer.from(text, 'utf8')]);
}

describe('libs/ariregisterSync & POST /task/syncAriregister/', () => {
    beforeEach(() => {
        db.queryDb.mockReset();
    });

    test('единая конфигурация БД: ariregisterSync и inforegisterService используют один объект config (narvalv.json)', async () => {
        expect(ariregisterSync.config).toBe(inforegisterService.config);
        expect(ariregisterSync.config.pg.database).toBe('db_test');

        db.queryDb.mockImplementation(async () => ({result: 1, data: [{url: 'https://custom.test/ari.zip'}]}));
        const url = await ariregisterSync.getAriregisterUrl(3);
        expect(url).toBe('https://custom.test/ari.zip');
        expect(db.queryDb).toHaveBeenCalledTimes(1);
        expect(db.queryDb.mock.calls[0][6]).toBe(inforegisterService.config);
    });

    test('tryAcquireLock & releaseLock: lock взят, занят, ошибка connect, releaseLock, emit("error") не падает', async () => {
        const errSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
        try {
            // 1. Lock взят -> handle + обработчик error
            const clientOk = Object.assign(new EventEmitter(), {
                connect: jest.fn(async () => {}),
                query: jest.fn(async () => ({rows: [{locked: true}]})),
                end: jest.fn(async () => {})
            });
            const handle = await ariregisterSync.tryAcquireLock(() => clientOk);
            expect(handle).toEqual({client: clientOk});
            expect(clientOk.listenerCount('error')).toBeGreaterThanOrEqual(1);
            expect(() => clientOk.emit('error', new Error('terminated'))).not.toThrow();
            expect(clientOk.connect).toHaveBeenCalledTimes(1);
            expect(clientOk.query).toHaveBeenCalledWith('SELECT pg_try_advisory_lock($1) AS locked', [ariregisterSync.ADVISORY_LOCK_KEY]);
            expect(clientOk.end).not.toHaveBeenCalled();

            // releaseLock -> unlock + end
            await ariregisterSync.releaseLock(handle);
            expect(clientOk.query).toHaveBeenCalledWith('SELECT pg_advisory_unlock($1)', [ariregisterSync.ADVISORY_LOCK_KEY]);
            expect(clientOk.end).toHaveBeenCalledTimes(1);

            // 2. Lock занят -> null и client.end()
            const clientBusy = {
                connect: jest.fn(async () => {}),
                query: jest.fn(async () => ({rows: [{locked: false}]})),
                end: jest.fn(async () => {})
            };
            const busyHandle = await ariregisterSync.tryAcquireLock(() => clientBusy);
            expect(busyHandle).toBeNull();
            expect(clientBusy.end).toHaveBeenCalledTimes(1);

            // 3. Ошибка connect -> исключение и client.end()
            const clientErr = {
                connect: jest.fn(async () => {
                    throw new Error('connect ETIMEDOUT');
                }),
                query: jest.fn(),
                end: jest.fn(async () => {})
            };
            let caught = null;
            try {
                await ariregisterSync.tryAcquireLock(() => clientErr);
            } catch (e) {
                caught = e;
            }
            expect(caught).not.toBeNull();
            expect(caught.message).toBe('connect ETIMEDOUT');
            expect(clientErr.end).toHaveBeenCalledTimes(1);
        } finally {
            errSpy.mockRestore();
        }
    });

    test('createPgClient и stageClient вешают обработчик error (emit("error") во время вставки пачек не падает)', async () => {
        const errSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
        const realClient = ariregisterSync.createPgClient();
        expect(realClient.listenerCount('error')).toBeGreaterThanOrEqual(1);
        expect(() => realClient.emit('error', new Error('terminated'))).not.toThrow();

        const stageMock = Object.assign(new EventEmitter(), {
            connect: jest.fn(async () => {}),
            query: jest.fn(async () => {
                expect(stageMock.listenerCount('error')).toBeGreaterThanOrEqual(1);
                expect(() => stageMock.emit('error', new Error('terminated'))).not.toThrow();
                return {rows: []};
            }),
            end: jest.fn(async () => {})
        });
        expect(stageMock.listenerCount('error')).toBe(0);
        // Проверяем attachErrorHandler через createClient в syncAriregister не вызывая реальный db.queryDb:
        // Для stageClient без queryFn syncAriregister использует db.queryDb для DELETE/count/apply, поэтому мокаем db.queryDb
        db.queryDb.mockImplementation(async (sql) => {
            if (sql.indexOf('INFOREGISTER_URL') !== -1) return {result: 1, data: [{url: 'https://example.test/a.zip'}]};
            if (sql.indexOf('SELECT count') !== -1) return {result: 1, data: [{cnt: 0}]};
            if (sql.indexOf('sp_ariregister_apply') !== -1) return {result: 1, data: [{result: {inserted: 1, updated: 0, deleted: 0, total: 1}}]};
            return {result: 1, data: []};
        });
        const csv = CSV_HEADER + '\nGood OÜ;12345678;OÜ;;;;;;;;;;;;;;\n';
        try {
            const res = await ariregisterSync.syncAriregister({
                url: 'https://example.test/data.zip',
                createClient: () => stageMock,
                downloadFn: async (u, dest) => {
                    fs.writeFileSync(dest, 'zip');
                    return {filePath: dest, size: 3, fileDate: '2026-11-18'};
                },
                openCsvStreamFn: async () => ({stream: streamFromText(csv), zipfile: {close: jest.fn()}})
            });
            expect(res.inserted).toBe(1);
            expect(stageMock.end).toHaveBeenCalled();
        } finally {
            errSpy.mockRestore();
        }
    });

    test('(а) CSV с BOM, ";" в кавычках и пустым kmkr_nr разбирается корректно', async () => {
        const csv = '\uFEFF' + CSV_HEADER + '\n' +
            '"Test; ""Firma"" OÜ";12345678;Osaühing;;;"R";Registrisse kantud;15.03.2020;"Harju maakond, Tallinn";Narva mnt 1;0784;Tallinn;10111;111;222;"Harju maakond, Tallinn, Narva mnt 1";https://ariregister.rik.ee/est/company/12345678\n';

        const insertedRows = [];
        const queryFn = jest.fn(async (sql, params) => {
            if (sql.indexOf('INSERT INTO libs.ariregister_stage') === 0) {
                insertedRows.push(params);
                return {result: 1, data: []};
            }
            if (sql.indexOf('SELECT count(*)::int AS cnt') === 0) {
                return {result: 1, data: [{cnt: 100}]};
            }
            if (sql.indexOf('SELECT libs.sp_ariregister_apply') === 0) {
                return {result: 1, data: [{result: {inserted: 1, updated: 0, deleted: 0, total: 1, file_date: '2026-11-18'}}]};
            }
            return {result: 0, data: []};
        });

        const res = await ariregisterSync.syncAriregister({
            url: 'https://example.test/data.zip',
            queryFn: queryFn,
            downloadFn: async (u, dest) => {
                fs.writeFileSync(dest, 'zip');
                return {filePath: dest, size: 3, fileDate: '2026-11-18'};
            },
            openCsvStreamFn: async () => ({stream: streamFromText(csv), zipfile: {close: jest.fn()}})
        });

        expect(res.rows_read).toBe(1);
        expect(res.skipped).toBe(0);
        expect(res.inserted).toBe(1);
        expect(res.file_date).toBe('2026-11-18');
        expect(insertedRows.length).toBe(1);
        const p = insertedRows[0];
        expect(p[0]).toBe('12345678'); // regkood
        expect(p[1]).toBe('Test; "Firma" OÜ'); // nimi
        expect(p[4]).toBeNull(); // kmkr_nr пустой -> null
        expect(p[7]).toBe('2020-03-15'); // esmakande_kpv
        expect(p[17]).toBe('2026-11-18'); // file_date
    });

    test('(б) строка с кодом не из 8 цифр или пустым nimi -> skipped, не падает', async () => {
        const csv = CSV_HEADER + '\n' +
            'Bad Code OÜ;12345;OÜ;;;;;;;;;;;;;;\n' +
            ';12345678;OÜ;;;;;;;;;;;;;;\n' +
            'Good OÜ;87654321;OÜ;;;;;;;;;;;;;;\n';

        const queryFn = jest.fn(async (sql) => {
            if (sql.indexOf('SELECT count(*)::int AS cnt') === 0) return {result: 1, data: [{cnt: 0}]};
            if (sql.indexOf('SELECT libs.sp_ariregister_apply') === 0) {
                return {result: 1, data: [{result: {inserted: 1, updated: 0, deleted: 0, total: 1, file_date: '2026-11-18'}}]};
            }
            return {result: 1, data: []};
        });

        const res = await ariregisterSync.syncAriregister({
            url: 'https://example.test/data.zip',
            queryFn: queryFn,
            downloadFn: async (u, dest) => {
                fs.writeFileSync(dest, 'zip');
                return {filePath: dest, size: 3, fileDate: '2026-11-18'};
            },
            openCsvStreamFn: async () => ({stream: streamFromText(csv), zipfile: {close: jest.fn()}})
        });

        expect(res.rows_read).toBe(3);
        expect(res.skipped).toBe(2);
        expect(res.inserted).toBe(1);
    });

    test('(в) пачки по 1000: 2500 строк -> 3 INSERT', async () => {
        const lines = [CSV_HEADER];
        for (let i = 0; i < 2500; i++) {
            const code = String(10000000 + i);
            lines.push('Firma ' + i + ';' + code + ';OÜ;;;;;;;;;;;;;;');
        }
        const csv = lines.join('\n') + '\n';

        let insertCalls = 0;
        const batchLengths = [];
        const queryFn = jest.fn(async (sql, params) => {
            if (sql.indexOf('INSERT INTO libs.ariregister_stage') === 0) {
                insertCalls += 1;
                batchLengths.push(params.length / 18);
                return {result: 1, data: []};
            }
            if (sql.indexOf('SELECT count(*)::int AS cnt') === 0) return {result: 1, data: [{cnt: 0}]};
            if (sql.indexOf('SELECT libs.sp_ariregister_apply') === 0) {
                return {result: 1, data: [{result: {inserted: 2500, updated: 0, deleted: 0, total: 2500}}]};
            }
            return {result: 1, data: []};
        });

        const res = await ariregisterSync.syncAriregister({
            url: 'https://example.test/data.zip',
            queryFn: queryFn,
            downloadFn: async (u, dest) => {
                fs.writeFileSync(dest, 'zip');
                return {filePath: dest, size: 3, fileDate: '2026-11-18'};
            },
            openCsvStreamFn: async () => ({stream: streamFromText(csv), zipfile: {close: jest.fn()}})
        });

        expect(res.rows_read).toBe(2500);
        expect(insertCalls).toBe(3);
        expect(batchLengths).toEqual([1000, 1000, 500]);
    });

    test('insertStageBatch при ошибке возвращает короткое сообщение без SQL и параметров', async () => {
        let err = null;
        try {
            await ariregisterSync.insertStageBatch(
                [{regkood: '12345678', nimi: 'Secret FIE Name'}],
                async () => {
                    throw new Error('duplicate key');
                },
                7
            );
        } catch (e) {
            err = e;
        }
        expect(err).not.toBeNull();
        expect(err.message).toBe('Stage insert failed at batch 7: duplicate key');
        expect(err.message).not.toMatch(/Secret FIE Name/);
        expect(err.message).not.toMatch(/INSERT INTO/);
    });

    test('(г) apply вызывается с min_rows по правилу max(300000, 90% от активных)', async () => {
        expect(ariregisterSync.computeMinRows(100)).toBe(300000);
        expect(ariregisterSync.computeMinRows(381600)).toBe(343440);

        const csv = CSV_HEADER + '\nGood OÜ;12345678;OÜ;;;;;;;;;;;;;;\n';
        let applyArgs = null;
        const queryFn = jest.fn(async (sql, params) => {
            if (sql.indexOf('SELECT count(*)::int AS cnt') === 0) return {result: 1, data: [{cnt: 381600}]};
            if (sql.indexOf('SELECT libs.sp_ariregister_apply') === 0) {
                applyArgs = params;
                return {result: 1, data: [{result: {inserted: 0, updated: 1, deleted: 0, total: 381600, file_date: '2026-11-18'}}]};
            }
            return {result: 1, data: []};
        });

        await ariregisterSync.syncAriregister({
            url: 'https://example.test/data.zip',
            queryFn: queryFn,
            downloadFn: async (u, dest) => {
                fs.writeFileSync(dest, 'zip');
                return {filePath: dest, size: 3, fileDate: '2026-11-18'};
            },
            openCsvStreamFn: async () => ({stream: streamFromText(csv), zipfile: {close: jest.fn()}})
        });

        expect(applyArgs).toEqual(['2026-11-18', 343440]);
    });

    test('(д) HTTP != 200 и маленький файл -> ошибка, лог failed, apply не вызван', async () => {
        let mode = 'http503';
        const server = http.createServer((req, res) => {
            if (mode === 'http503') {
                res.writeHead(503);
                res.end('Service Unavailable');
            } else {
                res.writeHead(200, {'Content-Type': 'application/zip'});
                res.end('tiny');
            }
        });

        await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
        const port = server.address().port;
        const url = 'http://127.0.0.1:' + port + '/test.zip';

        try {
            const tmpFile1 = path.join(os.tmpdir(), 'test_ari_503_' + Date.now() + '.zip');
            let err1 = null;
            try {
                await ariregisterSync.downloadZip(url, tmpFile1, {minZipBytes: 100});
            } catch (e) {
                err1 = e;
            }
            expect(err1).not.toBeNull();
            expect(err1.message).toMatch(/HTTP 503/);
            if (fs.existsSync(tmpFile1)) fs.unlinkSync(tmpFile1);

            mode = 'small';
            const tmpFile2 = path.join(os.tmpdir(), 'test_ari_small_' + Date.now() + '.zip');
            let err2 = null;
            try {
                await ariregisterSync.downloadZip(url, tmpFile2, {minZipBytes: 1024 * 1024});
            } catch (e) {
                err2 = e;
            }
            expect(err2).not.toBeNull();
            expect(err2.message).toMatch(/Downloaded ZIP too small/);
            if (fs.existsSync(tmpFile2)) fs.unlinkSync(tmpFile2);

            const logQueries = [];
            db.queryDb.mockImplementation(async (sql, params) => {
                logQueries.push({sql: sql, params: params});
                return {result: 1, data: []};
            });
            await syncRoute.runInBackground(777, null, {url: url, minZipBytes: 1024 * 1024});
            const endLogCall = logQueries.find((q) => q.sql.indexOf('update ou.logs') !== -1);
            expect(endLogCall).toBeDefined();
            expect(endLogCall.params[0]).toBe('failed');
            expect(endLogCall.params[1]).toMatch(/Downloaded ZIP too small/);
            expect(logQueries.some((q) => q.sql.indexOf('sp_ariregister_apply') !== -1)).toBe(false);
        } finally {
            server.close();
        }
    });

    test('(е) dry_run -> CSV разбирается, но DELETE, INSERT в stage и apply не вызываются', async () => {
        const csv = CSV_HEADER + '\nGood OÜ;12345678;OÜ;;;;;;;;;;;;;;\n';
        const queryFn = jest.fn();

        const res = await ariregisterSync.syncAriregister({
            dryRun: true,
            url: 'https://example.test/data.zip',
            queryFn: queryFn,
            downloadFn: async (u, dest) => {
                fs.writeFileSync(dest, 'zip');
                return {filePath: dest, size: 3, fileDate: '2026-11-18'};
            },
            openCsvStreamFn: async () => ({stream: streamFromText(csv), zipfile: {close: jest.fn()}})
        });

        expect(res.dry_run).toBe(true);
        expect(res.rows_read).toBe(1);
        expect(res.skipped).toBe(0);
        expect(queryFn).not.toHaveBeenCalled();
    });

    test('(ж) неверный hash -> 401; scope без sync -> 403', async () => {
        db.queryDb.mockImplementation(async () => ({
            result: 1,
            data: [{
                tokens: [
                    {token_sha256: sha256('lookup-only-token'), user_id: 2477, rekv_id: 63, scopes: ['lookup'], active: true},
                    {token_sha256: sha256('sync-token'), user_id: 11770, rekv_id: 63, scopes: ['sync'], active: true}
                ]
            }]
        }));

        const res401 = makeRes();
        await syncRoute.main({body: {hash: 'wrong-hash'}, query: {}, params: {}}, res401);
        expect(res401.statusCode).toBe(401);
        expect(res401.body.data.reason).toBe('unauthorized_hash');

        const res403 = makeRes();
        await syncRoute.main({body: {hash: 'lookup-only-token'}, query: {}, params: {}}, res403);
        expect(res403.statusCode).toBe(403);
        expect(res403.body.data.reason).toBe('forbidden_scope');
    });

    test('(з) advisory lock занят -> 409 already_running', async () => {
        db.queryDb.mockImplementation(async () => ({
            result: 1,
            data: [{tokens: [{token_sha256: sha256('sync-token'), user_id: 11770, rekv_id: 63, scopes: ['sync'], active: true}]}]
        }));
        const spyLock = jest.spyOn(ariregisterSync, 'tryAcquireLock').mockImplementation(async () => null);

        try {
            const res = makeRes();
            await syncRoute.main({body: {hash: 'sync-token'}, query: {}, params: {}}, res);
            expect(res.statusCode).toBe(409);
            expect(res.body.data.reason).toBe('already_running');
        } finally {
            spyLock.mockRestore();
        }
    });

    test('(и) временный zip файл удаляется даже при ошибке', async () => {
        let createdTmpPath = null;
        const closeMock = jest.fn();

        let err = null;
        try {
            await ariregisterSync.syncAriregister({
                url: 'https://example.test/data.zip',
                queryFn: jest.fn(async () => ({result: 0, data: []})),
                downloadFn: async (u, dest) => {
                    createdTmpPath = dest;
                    fs.writeFileSync(dest, 'zip');
                    return {filePath: dest, size: 3, fileDate: '2026-11-18'};
                },
                openCsvStreamFn: async () => ({
                    stream: new Readable({
                        read() {
                            this.destroy(new Error('Stream read boom'));
                        }
                    }),
                    zipfile: {close: closeMock}
                })
            });
        } catch (e) {
            err = e;
        }

        expect(err).not.toBeNull();
        expect(err.message).toBe('Stream read boom');
        expect(createdTmpPath).not.toBeNull();
        expect(fs.existsSync(createdTmpPath)).toBe(false);
        expect(closeMock).toHaveBeenCalled();
    });

    test('POST /task/syncAriregister/ при свободном lock создаёт лог и сразу возвращает 200 STARTED', async () => {
        db.queryDb.mockImplementation(async (sql) => {
            if (sql.indexOf('INFOREGISTER_TOKENS') !== -1) {
                return {
                    result: 1,
                    data: [{tokens: [{token_sha256: sha256('sync-token'), user_id: 11770, rekv_id: 63, scopes: ['sync'], active: true}]}]
                };
            }
            if (sql.indexOf('insert into ou.logs') !== -1) {
                return {result: 1, data: [{id: 901}]};
            }
            return {result: 1, data: []};
        });

        const fakeHandle = {client: {query: jest.fn(), end: jest.fn()}};
        const spyLock = jest.spyOn(ariregisterSync, 'tryAcquireLock').mockImplementation(async () => fakeHandle);
        const spyRelease = jest.spyOn(ariregisterSync, 'releaseLock').mockImplementation(async () => {});
        const spySync = jest.spyOn(ariregisterSync, 'syncAriregister').mockImplementation(async () => ({
            file_date: '2026-11-18',
            rows_read: 10,
            skipped: 0,
            inserted: 10,
            updated: 0,
            deleted: 0,
            total: 10,
            dry_run: false,
            duration_ms: 5
        }));

        try {
            const res = makeRes();
            await syncRoute.main({body: {hash: 'sync-token'}, query: {}, params: {}}, res);

            expect(res.statusCode).toBe(200);
            expect(res.body.result).toBe(1);
            expect(res.body.log_id).toBe(901);
            expect(res.body.data.status).toBe('STARTED');

            await wait(30);
            expect(spySync).toHaveBeenCalled();
            expect(spyRelease).toHaveBeenCalledWith(fakeHandle);
        } finally {
            spyLock.mockRestore();
            spyRelease.mockRestore();
            spySync.mockRestore();
        }
    });
});
