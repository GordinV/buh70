'use strict';

const db = require('../libs/db');
const getXMLFile = require('../routes/ai/e-arved/getXMLFile');
const XMLtoJson = require('../routes/ai/e-arved/xml_to_json');
const executePostTask = require('../routes/task/executePostTask');

jest.mock('../libs/db', () => ({
    queryDb: jest.fn()
}));
jest.mock('../routes/ai/e-arved/getXMLFile', () => jest.fn());
jest.mock('../routes/ai/e-arved/xml_to_json', () => jest.fn());
jest.mock('../routes/task/executePostTask', () => ({
    executeTask: jest.fn()
}));

const getEarvedFromFinBit = require('../routes/raama/getEarvedFromFinBit');
const getFinArvedFromFinBit = require('../routes/raama/getFinArvedFromFinBit');

describe('getEarvedFromFinBit and getFinArvedFromFinBit unit tests', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    test('getFinArvedFromFinBit re-exports getEarvedFromFinBit correctly', () => {
        expect(getFinArvedFromFinBit.post).toBe(getEarvedFromFinBit.post);
        expect(getFinArvedFromFinBit.checkIsAgent).toBe(getEarvedFromFinBit.checkIsAgent);
        expect(getFinArvedFromFinBit.FLOW_NAME).toBe('docs.sp_loe_earved');
        expect(getFinArvedFromFinBit.ROBOT_USER).toBe('Earved robot');
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

    test('Новая агентская логика (с флагом is_agent=true): в WHERE подменяет на (u.id = $1::integer or u.kasutaja = \'Earved robot\') и запускает в фоне', async () => {
        const mockReq = {
            query: {},
            body: { is_agent: true },
            params: { userid_id: 2477, date_query_from: '2026-09-15' }
        };

        const mockRes = {
            send: jest.fn().mockReturnThis(),
            status: jest.fn().mockReturnThis()
        };

        // 1. Мокаем конфигурацию с условием WHERE
        db.queryDb
            .mockReturnValueOnce(Promise.resolve({
                data: [{ hash: 'test-hash', earved_host: 'http://test-host', rekv_id: 63, user_id: 2477 }]
            }))
            // 2. createLog (insert into ou.logs)
            .mockReturnValueOnce(Promise.resolve({
                data: [{ id: 8888 }]
            }))
            // 3. background docs.sp_loe_earved
            .mockReturnValueOnce(Promise.resolve({
                data: [{ error_code: 0, result: 1, error_message: 'Success' }]
            }))
            // 4. endLog (update ou.logs)
            .mockReturnValueOnce(Promise.resolve({
                data: [{ id: 8888 }]
            }));

        getXMLFile.mockReturnValueOnce(Promise.resolve('<xml>test</xml>'));
        XMLtoJson.mockReturnValueOnce(Promise.resolve([{ number: 'INV-2', summa: 200 }]));

        await getEarvedFromFinBit.post(mockReq, mockRes);

        // Проверяем SQL запрос конфигурации (с robot)
        expect(db.queryDb.mock.calls[0][0]).toContain("(u.id = $1::integer or u.kasutaja = 'Earved robot')");

        // Не должен вызывать ou.sp_salvesta_task и executeTask
        expect(executePostTask.executeTask).not.toHaveBeenCalled();

        // Должен немедленно ответить со статусом 200 и log_id
        expect(mockRes.status).toHaveBeenCalledWith(200);
        expect(mockRes.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 200,
                result: 1,
                log_id: 8888,
                data: expect.objectContaining({
                    action: 'Import FinBit arved',
                    status: 'STARTED',
                    log_id: 8888
                })
            })
        );

        // Ждем асинхронный фоновый запуск
        await new Promise((resolve) => setTimeout(resolve, 50));

        // Проверяем, что createLog вызывался с FLOW_NAME
        expect(db.queryDb.mock.calls[1][0]).toContain('insert into ou.logs');
        expect(db.queryDb.mock.calls[1][1]).toEqual([63, 2477, 'docs.sp_loe_earved']);

        // Проверяем фоновый вызов docs.sp_loe_earved
        expect(db.queryDb.mock.calls[2][0]).toContain('docs.sp_loe_earved');
        expect(db.queryDb.mock.calls[2][1][0]).toBe(2477);

        // Проверяем фиксацию успешного завершения в ou.logs
        expect(db.queryDb.mock.calls[3][0]).toContain('update ou.logs');
        expect(db.queryDb.mock.calls[3][1]).toEqual(['success', null, 8888]);
    });

    test('Агентский режим без явного userId: находит пользователя robot и использует его user_id', async () => {
        const mockReq = {
            query: {},
            body: { is_agent: true },
            params: { date_query_from: '2026-09-15' } // нет userid_id
        };

        const mockRes = {
            send: jest.fn().mockReturnThis(),
            status: jest.fn().mockReturnThis()
        };

        // 1. Конфиг возвращает user_id робота
        db.queryDb
            .mockReturnValueOnce(Promise.resolve({
                data: [{ hash: 'test-hash', earved_host: 'http://test-host', rekv_id: 63, user_id: 777 }]
            }))
            // 2. createLog (insert into ou.logs)
            .mockReturnValueOnce(Promise.resolve({
                data: [{ id: 9999 }]
            }))
            // 3. background docs.sp_loe_earved
            .mockReturnValueOnce(Promise.resolve({
                data: [{ error_code: 0, result: 1, error_message: 'Success' }]
            }))
            // 4. endLog (update ou.logs)
            .mockReturnValueOnce(Promise.resolve({
                data: [{ id: 9999 }]
            }));

        getXMLFile.mockReturnValueOnce(Promise.resolve('<xml>test</xml>'));
        XMLtoJson.mockReturnValueOnce(Promise.resolve([{ number: 'INV-3', summa: 300 }]));

        await getEarvedFromFinBit.post(mockReq, mockRes);

        // Параметр $1 передан как null в sql
        expect(db.queryDb.mock.calls[0][1]).toEqual([null]);

        // Успешный старт с log_id: 9999
        expect(mockRes.status).toHaveBeenCalledWith(200);
        expect(mockRes.send).toHaveBeenCalledWith(
            expect.objectContaining({
                status: 200,
                result: 1,
                log_id: 9999
            })
        );

        await new Promise((resolve) => setTimeout(resolve, 50));

        // createLog использовал l_userId = 777 (робота)
        expect(db.queryDb.mock.calls[1][1]).toEqual([63, 777, 'docs.sp_loe_earved']);
        // docs.sp_loe_earved использовал l_userId = 777
        expect(db.queryDb.mock.calls[2][1][0]).toBe(777);
    });

    test('Множественные учреждения (агентский режим): опрашивает все учреждения и выполняет последовательный запрос select docs.sp_loe_earved(...); select docs.sp_loe_earved(...)', async () => {
        const mockReq = {
            query: {},
            body: { is_agent: true },
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
            // 2. createLog
            .mockReturnValueOnce(Promise.resolve({
                data: [{ id: 5555 }]
            }))
            // 3. combined sp_loe_earved
            .mockReturnValueOnce(Promise.resolve({
                data: [{ error_code: 0, result: 1, error_message: 'Success' }]
            }))
            // 4. endLog
            .mockReturnValueOnce(Promise.resolve({
                data: [{ id: 5555 }]
            }));

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

        await new Promise((resolve) => setTimeout(resolve, 50));

        // Проверяем фоновый вызов docs.sp_loe_earved: сформирован комбинированный SQL с двумя вызовами
        const combinedCallSql = db.queryDb.mock.calls[2][0];
        expect(combinedCallSql).toContain('select docs.sp_loe_earved(2477::integer');
        expect(combinedCallSql).toContain('select docs.sp_loe_earved(777::integer');
        expect(combinedCallSql).toContain('INV-63-1');
        expect(combinedCallSql).toContain('INV-119-1');

        // Проверяем фиксацию в ou.logs
        expect(db.queryDb.mock.calls[3][0]).toContain('update ou.logs');
        expect(db.queryDb.mock.calls[3][1]).toEqual(['success', null, 5555]);
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
