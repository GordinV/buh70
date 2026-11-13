'use strict';

const db = require('../libs/db');
db.queryDb = jest.fn();

const executePostTask = require('../routes/task/executePostTask');
executePostTask.executeTask = jest.fn();

const getEarvedFromFinBit = require('../routes/raama/getEarvedFromFinBit');
const getXMLFile = jest.fn();
const XMLtoJson = jest.fn();
getEarvedFromFinBit.deps.getXMLFile = getXMLFile;
getEarvedFromFinBit.deps.XMLtoJson = XMLtoJson;

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
            }));

        getXMLFile.mockReturnValueOnce(Promise.resolve('<xml>test</xml>'));
        XMLtoJson.mockReturnValueOnce(Promise.resolve([{ number: 'INV-1', summa: 100 }]));

        await getEarvedFromFinBit.post(mockReq, mockRes);

        // Проверяем SQL запрос конфигурации (без robot)
        expect(db.queryDb.mock.calls[0][0]).toContain('u.id = $1::integer');
        expect(db.queryDb.mock.calls[0][0]).not.toContain("u.kasutaja = 'Earved robot'");

        // Проверяем вызов старой логики
        expect(db.queryDb).toHaveBeenCalledTimes(2);
        expect(db.queryDb.mock.calls[1][0]).toContain('ou.sp_salvesta_task');
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
            // 1. конфигурация
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

    test('Множественные учреждения (не агентский режим): формирует последовательный SQL в ou.sp_salvesta_task', async () => {
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
            }));

        getXMLFile
            .mockReturnValueOnce(Promise.resolve('<xml>rekv-63</xml>'))
            .mockReturnValueOnce(Promise.resolve('<xml>rekv-119</xml>'));

        XMLtoJson
            .mockReturnValueOnce(Promise.resolve([{ number: 'INV-A', summa: 50 }]))
            .mockReturnValueOnce(Promise.resolve([{ number: 'INV-B', summa: 75 }]));

        await getEarvedFromFinBit.post(mockReq, mockRes);

        expect(getXMLFile).toHaveBeenCalledTimes(2);
        expect(XMLtoJson).toHaveBeenCalledTimes(2);

        // Проверяем вызов ou.sp_salvesta_task: содержит оба select docs.sp_loe_earved, разделенные ';'
        const saveTaskSql = db.queryDb.mock.calls[1][0];
        expect(saveTaskSql).toContain('ou.sp_salvesta_task');
        expect(saveTaskSql).toContain('select docs.sp_loe_earved(2477');
        expect(saveTaskSql).toContain('select docs.sp_loe_earved(777');
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
});
