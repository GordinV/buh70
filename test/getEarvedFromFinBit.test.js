'use strict';

const db = require('../libs/db');
db.queryDb = jest.fn();

const executePostTask = require('../routes/task/executePostTask');
executePostTask.executeTask = jest.fn();

const getEarvedFromFinBit = require('../routes/raama/getEarvedFromFinBit');
const getXMLFile = jest.fn();
const XMLtoJson = jest.fn();
const mockSendFinBitReport = {
    escapeHtml: getEarvedFromFinBit.deps.sendFinBitReport.escapeHtml,
    getUserMailAccount: jest.fn(),
    getRobotSmtpConfig: jest.fn(),
    sendHtmlEmail: jest.fn(),
    executeReport: jest.fn()
};
getEarvedFromFinBit.deps.getXMLFile = getXMLFile;
getEarvedFromFinBit.deps.XMLtoJson = XMLtoJson;
getEarvedFromFinBit.deps.sendFinBitReport = mockSendFinBitReport;

describe('getEarvedFromFinBit unit tests', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    test('checkIsAgent correctly detects agent flag in various formats', () => {
        expect(getEarvedFromFinBit.checkIsAgent({})).toBe(false);
        expect(getEarvedFromFinBit.checkIsAgent({ is_agent: false })).toBe(false);
        expect(getEarvedFromFinBit.checkIsAgent({ is_agent: 'false' })).toBe(false);
        expect(getEarvedFromFinBit.checkIsAgent({ is_agent: true })).toBe(true);
        expect(getEarvedFromFinBit.checkIsAgent({ is_agent: 'true' })).toBe(true);
        expect(getEarvedFromFinBit.checkIsAgent({ is_agent: 1 })).toBe(true);
        expect(getEarvedFromFinBit.checkIsAgent({ isAgent: true })).toBe(true);
        expect(getEarvedFromFinBit.checkIsAgent({ agent: true })).toBe(true);
        expect(getEarvedFromFinBit.checkIsAgent({ mode: 'agent' })).toBe(true);
    });

    test('Старая логика (без флага is_agent): WHERE u.id = $1::integer, сохраняет задачу через ou.sp_salvesta_task и вызывает executeTask', async () => {
        const mockReq = {
            query: {},
            body: {},
            params: { userid_id: 2477, date_query_from: '2026-09-15' }
        };

        const mockRes = {
            send: jest.fn().mockReturnThis(),
            status: jest.fn().mockReturnThis()
        };

        // 1. Мокаем получение конфигурации учреждения
        db.queryDb
            .mockReturnValueOnce(Promise.resolve({
                data: [{ hash: 'test-hash', earved_host: 'http://test-host', rekv_id: 63, user_id: 2477 }]
            }))
            // 2. Мокаем вызов ou.sp_salvesta_task
            .mockReturnValueOnce(Promise.resolve({
                data: [{ sp_salvesta_task: 999 }]
            }))
            // 3. createLog в фоне (ou.logs)
            .mockReturnValueOnce(Promise.resolve({ data: [{ id: 111 }] }))
            // 4. чтение ou.task в фоне
            .mockReturnValueOnce(Promise.resolve({
                data: [{ id: 999, user_id: 2477, rekv_id: 63, status: 1, tulemused: null, properties: { imported: [], errors: [] } }]
            }))
            // 5. endLog в фоне
            .mockReturnValueOnce(Promise.resolve({ data: [] }));
        executePostTask.executeTask.mockReturnValueOnce(Promise.resolve({ data: [] }));
        mockSendFinBitReport.executeReport.mockReturnValueOnce(Promise.resolve({ logId: null }));

        getXMLFile.mockReturnValueOnce(Promise.resolve('<xml>test</xml>'));
        XMLtoJson.mockReturnValueOnce(Promise.resolve([{ number: 'INV-1', summa: 100 }]));

        await getEarvedFromFinBit.post(mockReq, mockRes);
        await new Promise((resolve) => setTimeout(resolve, 20));

        // Проверяем SQL запрос конфигурации (без robot)
        expect(db.queryDb.mock.calls[0][0]).toContain('u.id = $1::integer');
        expect(db.queryDb.mock.calls[0][0]).not.toContain("u.kasutaja = 'Earved robot'");

        // Проверяем вызов старой логики (параметризованный ou.sp_salvesta_task с sp_loe_earved_batches)
        expect(db.queryDb.mock.calls[1][0]).toContain('ou.sp_salvesta_task($1::text, $2::text, $3::integer)');
        expect(db.queryDb.mock.calls[1][1][0]).toContain('select * from docs.sp_loe_earved_batches(');
        expect(db.queryDb.mock.calls[1][1][1]).toBe('Loe FinBit arved');
        expect(db.queryDb.mock.calls[1][1][2]).toBe(2477);
        expect(executePostTask.executeTask).toHaveBeenCalledWith(999);

        // Проверяем формат ответа старой логики
        expect(mockRes.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 200,
                result: 1,
                data: expect.objectContaining({
                    action: 'Import FinBit arved',
                    result: expect.objectContaining({
                        doc_id: 999,
                        error_code: 0
                    })
                })
            })
        );
    });

    test('Агентская логика (is_agent=true): только выкачка - массив счетов сохраняется в лог flow=getEarved, sp_loe_earved не вызывается', async () => {
        const mockReq = {
            query: {},
            body: { is_agent: true },
            params: { userid_id: 2477, date_query_from: '2026-09-15' }
        };

        const mockRes = {
            send: jest.fn().mockReturnThis(),
            status: jest.fn().mockReturnThis()
        };

        db.queryDb
            // 1. конфигурация (учреждения с hash)
            .mockReturnValueOnce(Promise.resolve({
                data: [{ hash: 'test-hash', earved_host: 'http://test-host', rekv_id: 63, user_id: 2477 }]
            }))
            // 2. insert ou.logs (flow = getEarved) с массивом счетов, закрытый success
            .mockReturnValueOnce(Promise.resolve({ data: [{ id: 8888 }] }));

        getXMLFile.mockReturnValueOnce(Promise.resolve('<xml>test</xml>'));
        XMLtoJson.mockReturnValueOnce(Promise.resolve([{ number: 'INV-2', summa: 200 }]));

        await getEarvedFromFinBit.post(mockReq, mockRes);

        // Проверяем SQL запрос конфигурации (с robot)
        expect(db.queryDb.mock.calls[0][0]).toContain("(u.id = $1::integer or u.kasutaja = 'Earved robot')");

        // Не должен вызывать ou.sp_salvesta_task и executeTask
        expect(executePostTask.executeTask).not.toHaveBeenCalled();

        // Выкачка завершена синхронно: статус COMPLETED и log_id лога getEarved
        expect(mockRes.status).toHaveBeenCalledWith(200);
        expect(mockRes.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 200,
                result: 1,
                log_id: 8888,
                data: expect.objectContaining({
                    action: 'Import FinBit arved',
                    status: 'COMPLETED',
                    log_id: 8888
                })
            })
        );

        // Массив счетов сохранен в лог flow = getEarved
        expect(db.queryDb.mock.calls[1][0]).toContain('insert into ou.logs');
        expect(db.queryDb.mock.calls[1][1][0]).toBe(63);
        expect(db.queryDb.mock.calls[1][1][1]).toBe(2477);
        expect(db.queryDb.mock.calls[1][1][2]).toBe('getEarved');
        expect(db.queryDb.mock.calls[1][1][3]).toContain('INV-2');
        expect(db.queryDb.mock.calls[1][1][4]).toBe(1);
        expect(JSON.parse(db.queryDb.mock.calls[1][1][5]).totalFetched).toBe(1);

        await new Promise((resolve) => setTimeout(resolve, 50));

        // Больше обращений к БД нет: разбор (docs.sp_loe_earved) выполняет агент import_earved
        expect(db.queryDb).toHaveBeenCalledTimes(2);
    });

    test('Агентский режим без явного userId: находит пользователя robot и использует его user_id в логе getEarved', async () => {
        const mockReq = {
            query: {},
            body: { is_agent: true },
            params: { date_query_from: '2026-09-15' } // нет userid_id
        };

        const mockRes = {
            send: jest.fn().mockReturnThis(),
            status: jest.fn().mockReturnThis()
        };

        db.queryDb
            // 1. Конфиг возвращает user_id робота
            .mockReturnValueOnce(Promise.resolve({
                data: [{ hash: 'test-hash', earved_host: 'http://test-host', rekv_id: 63, user_id: 777 }]
            }))
            // 2. insert лога getEarved
            .mockReturnValueOnce(Promise.resolve({ data: [{ id: 9999 }] }));

        getXMLFile.mockReturnValueOnce(Promise.resolve('<xml>test</xml>'));
        XMLtoJson.mockReturnValueOnce(Promise.resolve([{ number: 'INV-3', summa: 300 }]));

        await getEarvedFromFinBit.post(mockReq, mockRes);

        // Параметр $1 передан как null в sql
        expect(db.queryDb.mock.calls[0][1]).toEqual([null]);

        expect(mockRes.status).toHaveBeenCalledWith(200);
        expect(mockRes.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 200,
                result: 1,
                log_id: 9999
            })
        );

        // лог getEarved создан под пользователем-роботом (l_userId = 777)
        expect(db.queryDb.mock.calls[1][1][0]).toBe(63);
        expect(db.queryDb.mock.calls[1][1][1]).toBe(777);
        expect(db.queryDb.mock.calls[1][1][2]).toBe('getEarved');
    });

    test('Множественные учреждения (агентский режим): опрашивает все учреждения и сохраняет ВСЕ батчи в одном логе getEarved', async () => {
        const mockReq = {
            query: {},
            body: { is_agent: true },
            params: { userid_id: 2477, date_query_from: '2026-09-15' }
        };

        const mockRes = {
            send: jest.fn().mockReturnThis(),
            status: jest.fn().mockReturnThis()
        };

        db.queryDb
            // 1. Конфигурация возвращает массив из двух учреждений
            .mockReturnValueOnce(Promise.resolve({
                data: [
                    { hash: 'hash-rekv-63', earved_host: 'http://host-63', rekv_id: 63, user_id: 2477 },
                    { hash: 'hash-rekv-119', earved_host: 'http://host-119', rekv_id: 119, user_id: 777 }
                ]
            }))
            // 2. insert лога getEarved
            .mockReturnValueOnce(Promise.resolve({ data: [{ id: 5555 }] }));

        // Мокаем получение XML и преобразование в JSON для обоих учреждений
        getXMLFile
            .mockReturnValueOnce(Promise.resolve('<xml>rekv-63</xml>'))
            .mockReturnValueOnce(Promise.resolve('<xml>rekv-119</xml>'));

        XMLtoJson
            .mockReturnValueOnce(Promise.resolve([{ number: 'INV-63-1', summa: 100 }]))
            .mockReturnValueOnce(Promise.resolve([{ number: 'INV-119-1', summa: 200 }]));

        await getEarvedFromFinBit.post(mockReq, mockRes);

        expect(mockRes.status).toHaveBeenCalledWith(200);
        expect(mockRes.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 200,
                result: 1,
                log_id: 5555
            })
        );

        // Проверяем, что оба учреждения были опрошены
        expect(getXMLFile).toHaveBeenCalledTimes(2);
        expect(getXMLFile.mock.calls[0]).toEqual(['hash-rekv-63', 'http://host-63', '2026-09-15']);
        expect(getXMLFile.mock.calls[1]).toEqual(['hash-rekv-119', 'http://host-119', '2026-09-15']);

        // Один лог с двумя батчами, всего 2 счета
        expect(db.queryDb).toHaveBeenCalledTimes(2);
        const payload = JSON.parse(db.queryDb.mock.calls[1][1][3]);
        expect(payload).toHaveLength(2);
        expect(payload[0]).toEqual(expect.objectContaining({ rekvId: 63, userId: 2477, count: 1 }));
        expect(payload[1]).toEqual(expect.objectContaining({ rekvId: 119, userId: 777, count: 1 }));
        expect(db.queryDb.mock.calls[1][1][4]).toBe(2);
        const resultJson = JSON.parse(db.queryDb.mock.calls[1][1][5]);
        expect(resultJson.totalFetched).toBe(2);
        expect(resultJson.invoiceNumbers).toEqual(['INV-63-1', 'INV-119-1']);
    });

    test('Множественные учреждения (не агентский режим): формирует один вызов docs.sp_loe_earved_batches со всеми батчами в ou.sp_salvesta_task', async () => {
        const mockReq = {
            query: {},
            body: {},
            params: { userid_id: 2477, date_query_from: '2026-09-15' }
        };

        const mockRes = {
            send: jest.fn().mockReturnThis(),
            status: jest.fn().mockReturnThis()
        };

        // 1. Конфигурация возвращает массив из двух учреждений
        db.queryDb
            .mockReturnValueOnce(Promise.resolve({
                data: [
                    { hash: 'hash-rekv-63', earved_host: 'http://host-63', rekv_id: 63, user_id: 2477 },
                    { hash: 'hash-rekv-119', earved_host: 'http://host-119', rekv_id: 119, user_id: 777 }
                ]
            }))
            // 2. ou.sp_salvesta_task
            .mockReturnValueOnce(Promise.resolve({
                data: [{ sp_salvesta_task: 1234 }]
            }))
            // 3. фоновые вызовы (createLog, select ou.task, endLog)
            .mockReturnValueOnce(Promise.resolve({ data: [{ id: 120 }] }))
            .mockReturnValueOnce(Promise.resolve({
                data: [{ id: 1234, user_id: 2477, rekv_id: 63, status: 1, tulemused: null, properties: { imported: [], errors: [] } }]
            }))
            .mockReturnValueOnce(Promise.resolve({ data: [] }));
        executePostTask.executeTask.mockReturnValueOnce(Promise.resolve({ data: [] }));
        mockSendFinBitReport.executeReport.mockReturnValueOnce(Promise.resolve({ logId: null }));

        getXMLFile
            .mockReturnValueOnce(Promise.resolve('<xml>rekv-63</xml>'))
            .mockReturnValueOnce(Promise.resolve('<xml>rekv-119</xml>'));

        XMLtoJson
            .mockReturnValueOnce(Promise.resolve([{ number: 'INV-A', asutus: "O'Connor OÜ", summa: 50 }]))
            .mockReturnValueOnce(Promise.resolve([{ number: 'INV-B', summa: 75 }]));

        await getEarvedFromFinBit.post(mockReq, mockRes);
        await new Promise((resolve) => setTimeout(resolve, 20));

        expect(getXMLFile).toHaveBeenCalledTimes(2);
        expect(XMLtoJson).toHaveBeenCalledTimes(2);

        // Проверяем вызов ou.sp_salvesta_task: параметризованный вызов с ровно одним docs.sp_loe_earved_batches
        const saveTaskSql = db.queryDb.mock.calls[1][0];
        const saveTaskParams = db.queryDb.mock.calls[1][1];
        expect(saveTaskSql).toBe('select ou.sp_salvesta_task($1::text, $2::text, $3::integer)');
        expect(saveTaskParams[1]).toBe('Loe FinBit arved');
        expect(saveTaskParams[2]).toBe(2477);

        const taskSqlText = saveTaskParams[0];
        expect(taskSqlText.match(/docs\.sp_loe_earved_batches/g)).toHaveLength(1);
        expect(taskSqlText).not.toContain(';');
        expect(taskSqlText).toContain("O'Connor OÜ");
        const match = taskSqlText.match(/\$\$(.*)\$\$/);
        expect(match).not.toBeNull();
        const parsedBatches = JSON.parse(match[1]);
        expect(parsedBatches).toEqual([
            { user_id: 2477, data: [{ number: 'INV-A', asutus: "O'Connor OÜ", summa: 50 }] },
            { user_id: 777, data: [{ number: 'INV-B', summa: 75 }] }
        ]);
        expect(executePostTask.executeTask).toHaveBeenCalledWith(1234);

        expect(mockRes.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 200,
                result: 1,
                data: expect.objectContaining({
                    action: 'Import FinBit arved',
                    result: expect.objectContaining({ doc_id: 1234 })
                })
            })
        );
    });

    test('Неагентский вызов с rekv_id=106 и user_id: фильтрует по r.id = $2 и передает user_id в sp_loe_earved_batches', async () => {
        const mockReq = {
            query: {},
            body: { user_id: 5106, rekv_id: 106, date_query_from: '2026-11-28' },
            params: {}
        };

        const mockRes = {
            send: jest.fn().mockReturnThis(),
            status: jest.fn().mockReturnThis()
        };

        db.queryDb
            .mockReturnValueOnce(Promise.resolve({
                data: [
                    { hash: 'hash-106', earved_host: 'http://host-106', rekv_id: 106, rekv_regkood: '75024260', user_id: 5106 }
                ]
            }))
            .mockReturnValueOnce(Promise.resolve({
                data: [{ sp_salvesta_task: 4321 }]
            }))
            .mockReturnValueOnce(Promise.resolve({ data: [{ id: 121 }] }))
            .mockReturnValueOnce(Promise.resolve({
                data: [{ id: 4321, user_id: 5106, rekv_id: 106, status: 1, tulemused: null, properties: { imported: [], errors: [] } }]
            }))
            .mockReturnValueOnce(Promise.resolve({ data: [] }));
        executePostTask.executeTask.mockReturnValueOnce(Promise.resolve({ data: [] }));
        mockSendFinBitReport.executeReport.mockReturnValueOnce(Promise.resolve({ logId: null }));

        getXMLFile.mockReturnValueOnce(Promise.resolve('<xml>106</xml>'));
        XMLtoJson.mockReturnValueOnce(Promise.resolve([
            { id: 0, data: { number: '82020126240', rekv_regkood: '75024260', rekvid: 106, userid: 5106 } }
        ]));

        await getEarvedFromFinBit.post(mockReq, mockRes);
        await new Promise((resolve) => setTimeout(resolve, 20));

        expect(db.queryDb.mock.calls[0][0]).toContain('and r.id = $2::integer');
        expect(db.queryDb.mock.calls[0][1]).toEqual([5106, 106]);
        expect(XMLtoJson).toHaveBeenCalledWith('<xml>106</xml>', { rekvid: 106, userid: 5106 });

        const saveTaskParams = db.queryDb.mock.calls[1][1];
        expect(saveTaskParams[0]).toContain('docs.sp_loe_earved_batches');
        expect(saveTaskParams[0]).toContain('"user_id":5106');
        expect(saveTaskParams[0]).toContain('82020126240');
        expect(saveTaskParams[1]).toBe('Loe FinBit arved');
        expect(saveTaskParams[2]).toBe(5106);
        expect(executePostTask.executeTask).toHaveBeenCalledWith(4321);
    });

    describe('Покупатель = учреждение выкачки (BuyerRegNumber не используется для маршрутизации)', () => {
        test('Неагентский вызов rekv_id=106: счет на регкод вышестоящего (75024260) импортируется в 106, unmatched нет', async () => {
            const mockReq = {
                query: {},
                body: { user_id: 5106, rekv_id: 106, date_query_from: '2026-11-28' },
                params: {}
            };
            const mockRes = {
                send: jest.fn().mockReturnThis(),
                status: jest.fn().mockReturnThis()
            };

            db.queryDb
                .mockReturnValueOnce(Promise.resolve({
                    data: [
                        { hash: 'hash-106', earved_host: 'http://host-106', rekv_id: 106, user_id: 5106 }
                    ]
                }))
                .mockReturnValueOnce(Promise.resolve({ data: [{ sp_salvesta_task: 8888 }] }))
                .mockReturnValueOnce(Promise.resolve({ data: [{ id: 130 }] }))
                .mockReturnValueOnce(Promise.resolve({
                    data: [{ id: 8888, user_id: 5106, rekv_id: 106, status: 1, tulemused: null, properties: { imported: [], errors: [] } }]
                }))
                .mockReturnValueOnce(Promise.resolve({ data: [] }));
            executePostTask.executeTask.mockReturnValueOnce(Promise.resolve({ data: [] }));
            mockSendFinBitReport.executeReport.mockReturnValueOnce(Promise.resolve({ logId: null }));

            getXMLFile.mockReturnValueOnce(Promise.resolve('<xml>106</xml>'));
            XMLtoJson.mockReturnValueOnce(Promise.resolve([
                { id: 0, data: { number: 'INV-OWN', rekv_regkood: '75008611', rekvid: 106, userid: 5106 } },
                { id: 0, data: { number: 'INV-PARENT', rekv_regkood: '75024260', rekvid: 106, userid: 5106 } }
            ]));

            await getEarvedFromFinBit.post(mockReq, mockRes);
            await new Promise((resolve) => setTimeout(resolve, 20));

            const taskSqlText = db.queryDb.mock.calls[1][1][0];
            const match = taskSqlText.match(/\$\$(.*)\$\$/);
            expect(match).not.toBeNull();
            const parsedBatches = JSON.parse(match[1]);
            expect(parsedBatches).toHaveLength(1);
            expect(parsedBatches[0].user_id).toBe(5106);
            expect(parsedBatches[0].data.map((x) => x.data.number)).toEqual(['INV-OWN', 'INV-PARENT']);
            expect(parsedBatches[0].data.every((x) => x.data.rekvid === 106)).toBe(true);

            const sent = mockRes.send.mock.calls[0][0];
            expect(sent.status).toBe(200);
            expect(sent.unmatched).toBeUndefined();
        });

        test('Агентский режим: каждое учреждение получает свой batch со всеми счетами своей выкачки, ou.rekv по regkood не запрашивается', async () => {
            const mockReq = {
                query: {},
                body: { is_agent: true },
                params: { userid_id: 2477, date_query_from: '2026-11-28' }
            };
            const mockRes = {
                send: jest.fn().mockReturnThis(),
                status: jest.fn().mockReturnThis()
            };

            db.queryDb
                .mockReturnValueOnce(Promise.resolve({
                    data: [
                        { hash: 'hash-3', earved_host: 'http://host', rekv_id: 3, user_id: 11769 },
                        { hash: 'hash-63', earved_host: 'http://host', rekv_id: 63, user_id: 2477 }
                    ]
                }))
                .mockReturnValueOnce(Promise.resolve({ data: [{ id: 6001 }] }));

            getXMLFile
                .mockReturnValueOnce(Promise.resolve('<xml>3</xml>'))
                .mockReturnValueOnce(Promise.resolve('<xml>63</xml>'));
            XMLtoJson
                .mockReturnValueOnce(Promise.resolve([
                    { id: 0, data: { number: 'INV-3', rekv_regkood: '75024260', rekvid: 3, userid: 11769 } }
                ]))
                .mockReturnValueOnce(Promise.resolve([
                    { id: 0, data: { number: 'INV-63', rekv_regkood: '75008427', rekvid: 63, userid: 2477 } },
                    { id: 0, data: { number: 'INV-63-OTHER', rekv_regkood: '99999999', rekvid: 63, userid: 2477 } }
                ]));

            await getEarvedFromFinBit.post(mockReq, mockRes);

            expect(getXMLFile).toHaveBeenCalledTimes(2);
            expect(db.queryDb).toHaveBeenCalledTimes(2);

            const payload = JSON.parse(db.queryDb.mock.calls[1][1][3]);
            expect(payload).toHaveLength(2);
            expect(payload[0]).toEqual(expect.objectContaining({ rekvId: 3, userId: 11769, count: 1 }));
            expect(payload[0].arved[0].data).toEqual(expect.objectContaining({ number: 'INV-3', rekvid: 3, userid: 11769 }));
            expect(payload[1]).toEqual(expect.objectContaining({ rekvId: 63, userId: 2477, count: 2 }));

            const resultJson = JSON.parse(db.queryDb.mock.calls[1][1][5]);
            expect(resultJson.totalFetched).toBe(3);
            expect(resultJson.unmatched).toBeUndefined();
        });

        test('formatTaskErrorEmail: колонка Asutus берется из asutusid ошибки импорта', () => {
            const mail = getEarvedFromFinBit.formatTaskErrorEmail(777, 2, 'Imporditud 0 arvet, vigu 1', [
                { number: 'INV-X', asutusid: '12345678', error: 'Viga' }
            ]);
            expect(mail.text).toContain('Asutus: 12345678');
            expect(mail.html).toContain('12345678');
        });
    });

    test('buildBatchesTaskSql: при наличии $$ в JSON использует тег $finbit$', () => {
        const sql = getEarvedFromFinBit.buildBatchesTaskSql([
            { userId: 10, json: [{ number: 'INV-1', muud: 'Hind 100$$' }] }
        ]);
        expect(sql).toMatch(/^select \* from docs\.sp_loe_earved_batches\(\$finbit\$[\s\S]*\$finbit\$::jsonb\)$/);
        expect(sql).toContain('Hind 100$$');
    });

    describe('runPostTaskInBackground: error mail и рассылка уведомлений после импорта', () => {
        const smtpStub = {
            host: 'mail.narva.ee',
            port: 465,
            secure: true,
            auth: { user: 'robot', pass: 'secret' },
            from: 'robot@narva.ee'
        };

        test('status = 2: закрывает лог как failed, шлет письмо VIGA инициатору, executeReport не вызывает', async () => {
            db.queryDb
                // 1. createLog
                .mockReturnValueOnce(Promise.resolve({ data: [{ id: 501 }] }))
                // 2. select ou.task
                .mockReturnValueOnce(Promise.resolve({
                    data: [{
                        id: 700,
                        user_id: 2477,
                        rekv_id: 63,
                        status: 2,
                        tulemused: 'Imporditud 0 arvet, vigu 1: INV-ERR: Puudub asutus',
                        properties: {
                            imported: [],
                            errors: [{ number: 'INV-ERR', asutusid: '12345678', error: 'Puudub asutus' }]
                        },
                        user_email: 'user@narva.ee',
                        rekv_email: 'asutus@narva.ee'
                    }]
                }))
                // 3. endLog
                .mockReturnValueOnce(Promise.resolve({ data: [] }));

            executePostTask.executeTask.mockReturnValueOnce(Promise.resolve({ data: [] }));
            mockSendFinBitReport.getUserMailAccount.mockReturnValueOnce(Promise.resolve({ smtp: smtpStub }));
            mockSendFinBitReport.sendHtmlEmail.mockReturnValueOnce(Promise.resolve({ messageId: 'm1' }));

            await getEarvedFromFinBit.runPostTaskInBackground(700, 63, 2477);

            // createLog с flow = docs.sp_loe_earved
            expect(db.queryDb.mock.calls[0][0]).toContain('insert into ou.logs');
            expect(db.queryDb.mock.calls[0][1]).toEqual([63, 2477, 'docs.sp_loe_earved']);

            // endLog со статусом failed и ou_task_id
            expect(db.queryDb.mock.calls[2][0]).toContain('update ou.logs');
            expect(db.queryDb.mock.calls[2][1][0]).toBe('failed');
            expect(JSON.parse(db.queryDb.mock.calls[2][1][2])).toEqual(expect.objectContaining({
                totalImported: 0,
                totalFailed: 1,
                ou_task_id: 700
            }));
            expect(JSON.parse(db.queryDb.mock.calls[2][1][5])).toEqual({ ou_task_id: 700 });

            // письмо об ошибке инициатору
            expect(mockSendFinBitReport.sendHtmlEmail).toHaveBeenCalledTimes(1);
            const mailArgs = mockSendFinBitReport.sendHtmlEmail.mock.calls[0];
            expect(mailArgs[0]).toBe('user@narva.ee');
            expect(mailArgs[1]).toBe('Loe FinBit arved: VIGA (task 700)');
            expect(mailArgs[2]).toContain('INV-ERR');
            expect(mailArgs[2]).toContain('Puudub asutus');

            // при status=2 executeReport не вызывается
            expect(mockSendFinBitReport.executeReport).not.toHaveBeenCalled();
        });

        test('Частичный успех (status = 1 + errors): шлет письмо osaliselt imporditud И вызывает executeReport с записью send_log_id', async () => {
            db.queryDb
                // 1. createLog
                .mockReturnValueOnce(Promise.resolve({ data: [{ id: 502 }] }))
                // 2. select ou.task
                .mockReturnValueOnce(Promise.resolve({
                    data: [{
                        id: 701,
                        user_id: 2477,
                        rekv_id: 63,
                        status: 1,
                        tulemused: 'Imporditud 1 arvet, vigu 1: INV-BAD: Viga',
                        properties: {
                            imported: [{ doc_id: 9001, number: 'INV-OK', rekv_id: 63 }],
                            errors: [{ number: 'INV-BAD', asutusid: '87654321', error: 'Viga' }]
                        },
                        user_email: 'user@narva.ee',
                        rekv_email: 'asutus@narva.ee'
                    }]
                }))
                // 3. endLog
                .mockReturnValueOnce(Promise.resolve({ data: [] }))
                // 4. update ou.task send_log_id
                .mockReturnValueOnce(Promise.resolve({ data: [] }));

            executePostTask.executeTask.mockReturnValueOnce(Promise.resolve({ data: [] }));
            mockSendFinBitReport.getUserMailAccount.mockReturnValueOnce(Promise.resolve({ smtp: smtpStub }));
            mockSendFinBitReport.sendHtmlEmail.mockReturnValueOnce(Promise.resolve({ messageId: 'm2' }));
            mockSendFinBitReport.executeReport.mockReturnValueOnce(Promise.resolve({ logId: 8801, status: 'success' }));

            await getEarvedFromFinBit.runPostTaskInBackground(701, 63, 2477);

            // endLog со статусом success и imported из ou.task
            const endLogResult = JSON.parse(db.queryDb.mock.calls[2][1][2]);
            expect(endLogResult.imported).toEqual([{ doc_id: 9001, number: 'INV-OK', rekv_id: 63 }]);
            expect(endLogResult.totalImported).toBe(1);
            expect(endLogResult.totalFailed).toBe(1);

            // письмо о частичном успехе
            expect(mockSendFinBitReport.sendHtmlEmail).toHaveBeenCalledTimes(1);
            expect(mockSendFinBitReport.sendHtmlEmail.mock.calls[0][1]).toBe('Loe FinBit arved: osaliselt imporditud (task 701)');

            // executeReport вызван с importLogId = 502
            expect(mockSendFinBitReport.executeReport).toHaveBeenCalledWith(2477, 63, 502);

            // send_log_id записан в ou.task.properties
            expect(db.queryDb.mock.calls[3][0]).toContain('send_log_id');
            expect(db.queryDb.mock.calls[3][1]).toEqual([8801, 701]);
        });

        test('Полный успех (status = 1, errors = []): письмо об ошибке НЕ отправляется, executeReport вызывается', async () => {
            db.queryDb
                .mockReturnValueOnce(Promise.resolve({ data: [{ id: 503 }] }))
                .mockReturnValueOnce(Promise.resolve({
                    data: [{
                        id: 702,
                        user_id: 2477,
                        rekv_id: 63,
                        status: 1,
                        tulemused: null,
                        properties: {
                            imported: [{ doc_id: 9002, number: 'INV-OK-2', rekv_id: 63 }],
                            errors: []
                        },
                        user_email: 'user@narva.ee',
                        rekv_email: 'asutus@narva.ee'
                    }]
                }))
                .mockReturnValueOnce(Promise.resolve({ data: [] }))
                .mockReturnValueOnce(Promise.resolve({ data: [] }));

            executePostTask.executeTask.mockReturnValueOnce(Promise.resolve({ data: [] }));
            mockSendFinBitReport.executeReport.mockReturnValueOnce(Promise.resolve({ logId: 8802, status: 'success' }));

            await getEarvedFromFinBit.runPostTaskInBackground(702, 63, 2477);

            expect(mockSendFinBitReport.sendHtmlEmail).not.toHaveBeenCalled();
            expect(mockSendFinBitReport.executeReport).toHaveBeenCalledWith(2477, 63, 503);
            expect(db.queryDb.mock.calls[3][1]).toEqual([8802, 702]);
        });

        test('Нет email пользователя -> fallback на email учреждения и fallback SMTP робота', async () => {
            db.queryDb
                .mockReturnValueOnce(Promise.resolve({ data: [{ id: 504 }] }))
                .mockReturnValueOnce(Promise.resolve({
                    data: [{
                        id: 703,
                        user_id: 2477,
                        rekv_id: 63,
                        status: 2,
                        tulemused: 'Puudub õigused',
                        properties: { imported: [], errors: [{ number: null, user_id: 2477, error: 'Puudub õigused' }] },
                        user_email: null,
                        rekv_email: 'asutus@narva.ee'
                    }]
                }))
                .mockReturnValueOnce(Promise.resolve({ data: [] }));

            executePostTask.executeTask.mockReturnValueOnce(Promise.resolve({ data: [] }));
            mockSendFinBitReport.getUserMailAccount.mockReturnValueOnce(Promise.reject(new Error('mail_password_missing')));
            mockSendFinBitReport.getRobotSmtpConfig.mockReturnValueOnce(Promise.resolve(smtpStub));
            mockSendFinBitReport.sendHtmlEmail.mockReturnValueOnce(Promise.resolve({ messageId: 'm3' }));

            await getEarvedFromFinBit.runPostTaskInBackground(703, 63, 2477);

            expect(mockSendFinBitReport.getRobotSmtpConfig).toHaveBeenCalledWith(63);
            expect(mockSendFinBitReport.sendHtmlEmail).toHaveBeenCalledTimes(1);
            expect(mockSendFinBitReport.sendHtmlEmail.mock.calls[0][0]).toBe('asutus@narva.ee');
        });

        test('Падение mailer и падение executeReport не бросают исключение наружу', async () => {
            db.queryDb
                .mockReturnValueOnce(Promise.resolve({ data: [{ id: 505 }] }))
                .mockReturnValueOnce(Promise.resolve({
                    data: [{
                        id: 704,
                        user_id: 2477,
                        rekv_id: 63,
                        status: 1,
                        tulemused: 'Imporditud 1 arvet, vigu 1',
                        properties: {
                            imported: [{ doc_id: 9003, number: 'INV-OK-3', rekv_id: 63 }],
                            errors: [{ number: 'INV-ERR-3', error: 'Boom' }]
                        },
                        user_email: 'user@narva.ee',
                        rekv_email: null
                    }]
                }))
                .mockReturnValueOnce(Promise.resolve({ data: [] }));

            executePostTask.executeTask.mockReturnValueOnce(Promise.resolve({ data: [] }));
            mockSendFinBitReport.getUserMailAccount.mockReturnValueOnce(Promise.resolve({ smtp: smtpStub }));
            mockSendFinBitReport.sendHtmlEmail.mockReturnValueOnce(Promise.reject(new Error('SMTP connection refused')));
            mockSendFinBitReport.executeReport.mockReturnValueOnce(Promise.reject(new Error('Report crash')));

            await expect(getEarvedFromFinBit.runPostTaskInBackground(704, 63, 2477)).resolves.toBeUndefined();
            expect(mockSendFinBitReport.sendHtmlEmail).toHaveBeenCalledTimes(1);
            expect(mockSendFinBitReport.executeReport).toHaveBeenCalledWith(2477, 63, 505);
        });
    });
});
