'use strict';

const db = require('../libs/db');
const calcModule = require('../routes/raama/calcKondSaldoandmik');

describe('calcKondSaldoandmik tests', () => {
    let originalQueryDb;

    beforeEach(() => {
        originalQueryDb = db.queryDb;
    });

    afterEach(() => {
        db.queryDb = originalQueryDb;
    });

    describe('main Express handler', () => {
        test('should create log, start calculation in background and return 200 with STARTED status and log_id', async () => {
            const mockLogId = 1001;
            const queries = [];

            db.queryDb = jest.fn(async (sql, params) => {
                queries.push({ sql, params });
                if (sql.includes('insert into ou.logs')) {
                    return { error_code: 0, result: 1, data: [{ id: mockLogId }] };
                }
                if (sql.includes('eelarve.sp_koosta_saldoandmik')) {
                    return { error_code: 0, result: 1, data: [{ tulemus: 1 }] };
                }
                if (sql.includes('update ou.logs')) {
                    return { error_code: 0, result: 1, data: [] };
                }
                return { error_code: 0, result: 1, data: [] };
            });

            const req = {
                body: { user_id: 2477, rekv_id: 63, kond: 1 },
                query: {},
                params: {}
            };

            const res = {
                status: jest.fn().mockReturnThis(),
                send: jest.fn().mockReturnThis()
            };

            await calcModule.main(req, res);

            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.send).toHaveBeenCalledWith({
                status: 200,
                result: 1,
                log_id: mockLogId,
                data: {
                    action: 'calcKondSaldoandmik',
                    status: 'STARTED',
                    log_id: mockLogId
                },
                error_message: null
            });

            // Ждем завершения фоновой задачи
            await new Promise(resolve => setTimeout(resolve, 50));

            // Проверяем, что были вызваны createLog, koostaSaldoandmik и endLog со статусом success
            expect(db.queryDb).toHaveBeenCalledTimes(3);
            expect(queries[0].sql).toContain('insert into ou.logs');
            expect(queries[0].params).toEqual([63, 2477]);

            expect(queries[1].sql).toContain('eelarve.sp_koosta_saldoandmik');
            expect(queries[1].params).toEqual([2477, 1, 63]);

            expect(queries[2].sql).toContain('update ou.logs');
            expect(queries[2].params).toEqual(['success', null, mockLogId]);
        });

        test('should use default parameters if not provided in req', async () => {
            const mockLogId = 2002;
            const queries = [];

            db.queryDb = jest.fn(async (sql, params) => {
                queries.push({ sql, params });
                if (sql.includes('insert into ou.logs')) {
                    return { error_code: 0, result: 1, data: [{ id: mockLogId }] };
                }
                return { error_code: 0, result: 1, data: [] };
            });

            const req = {
                body: {},
                query: {},
                params: {}
            };

            const res = {
                status: jest.fn().mockReturnThis(),
                send: jest.fn().mockReturnThis()
            };

            await calcModule.main(req, res);

            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.send).toHaveBeenCalledWith({
                status: 200,
                result: 1,
                log_id: mockLogId,
                data: {
                    action: 'calcKondSaldoandmik',
                    status: 'STARTED',
                    log_id: mockLogId
                },
                error_message: null
            });

            await new Promise(resolve => setTimeout(resolve, 50));

            // Проверка дефолтных параметров (userId: 2477, rekvId: 63, kond: 1)
            expect(queries[0].params).toEqual([63, 2477]);
            expect(queries[1].params).toEqual([2477, 1, 63]);
        });

        test('should return 500 if createLog fails', async () => {
            db.queryDb = jest.fn(async (sql) => {
                if (sql.includes('insert into ou.logs')) {
                    throw new Error('Database connection failed');
                }
                return { error_code: 0, result: 1, data: [] };
            });

            const req = {
                body: { user_id: 2477, rekv_id: 63, kond: 1 },
                query: {},
                params: {}
            };

            const res = {
                status: jest.fn().mockReturnThis(),
                send: jest.fn().mockReturnThis()
            };

            await calcModule.main(req, res);

            expect(res.status).toHaveBeenCalledWith(500);
            expect(res.send).toHaveBeenCalledWith({
                status: 500,
                result: 0,
                log_id: null,
                data: null,
                error_message: 'Start calculation failed: DB Query failed: Database connection failed'
            });
        });

        test('should update log with failed status if background calculation fails', async () => {
            const mockLogId = 3003;
            const queries = [];

            db.queryDb = jest.fn(async (sql, params) => {
                queries.push({ sql, params });
                if (sql.includes('insert into ou.logs')) {
                    return { error_code: 0, result: 1, data: [{ id: mockLogId }] };
                }
                if (sql.includes('eelarve.sp_koosta_saldoandmik')) {
                    throw new Error('Calculation timeout error');
                }
                if (sql.includes('update ou.logs')) {
                    return { error_code: 0, result: 1, data: [] };
                }
                return { error_code: 0, result: 1, data: [] };
            });

            const req = {
                body: { user_id: 2477, rekv_id: 63, kond: 1 },
                query: {},
                params: {}
            };

            const res = {
                status: jest.fn().mockReturnThis(),
                send: jest.fn().mockReturnThis()
            };

            await calcModule.main(req, res);

            expect(res.status).toHaveBeenCalledWith(200);

            // Ждем завершения фоновой задачи
            await new Promise(resolve => setTimeout(resolve, 50));

            // Проверяем, что в endLog передан статус 'failed' с сообщением об ошибке
            expect(queries[2].sql).toContain('update ou.logs');
            expect(queries[2].params[0]).toBe('failed');
            expect(queries[2].params[1]).toContain('Calculation timeout error');
            expect(queries[2].params[2]).toBe(mockLogId);
        });
    });

    describe('executeCalculation direct helper', () => {
        test('should successfully execute calculation and update logs', async () => {
            const mockLogId = 4004;
            const queries = [];

            db.queryDb = jest.fn(async (sql, params) => {
                queries.push({ sql, params });
                if (sql.includes('insert into ou.logs')) {
                    return { error_code: 0, result: 1, data: [{ id: mockLogId }] };
                }
                if (sql.includes('eelarve.sp_koosta_saldoandmik')) {
                    return { error_code: 0, result: 1, data: [{ tulemus: 100 }] };
                }
                return { error_code: 0, result: 1, data: [] };
            });

            const result = await calcModule.executeCalculation(2477, 63, 1);

            expect(result).toEqual({ error_code: 0, result: 1, data: [{ tulemus: 100 }] });
            expect(queries[2].params).toEqual(['success', null, mockLogId]);
        });

        test('should throw error and update log to failed if executeCalculation fails', async () => {
            const mockLogId = 5005;
            const queries = [];

            db.queryDb = jest.fn(async (sql, params) => {
                queries.push({ sql, params });
                if (sql.includes('insert into ou.logs')) {
                    return { error_code: 0, result: 1, data: [{ id: mockLogId }] };
                }
                if (sql.includes('eelarve.sp_koosta_saldoandmik')) {
                    throw new Error('Procedure execution error');
                }
                return { error_code: 0, result: 1, data: [] };
            });

            let caughtError = null;
            try {
                await calcModule.executeCalculation(2477, 63, 1);
            } catch (err) {
                caughtError = err;
            }

            expect(caughtError).not.toBeNull();
            expect(caughtError.message).toContain('Procedure execution error');
            expect(queries[2].params[0]).toBe('failed');
            expect(queries[2].params[1]).toContain('Procedure execution error');
            expect(queries[2].params[2]).toBe(mockLogId);
        });
    });
});
