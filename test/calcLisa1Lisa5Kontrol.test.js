'use strict';

const db = require('../libs/db');
const lisaModule = require('../routes/raama/calcLisa1Lisa5Kontrol');

describe('calcLisa1Lisa5Kontrol tests', () => {
    let originalQueryDb;
    let originalExecuteQueries;

    beforeEach(() => {
        originalQueryDb = db.queryDb;
        originalExecuteQueries = db.executeQueries;
    });

    afterEach(() => {
        db.queryDb = originalQueryDb;
        db.executeQueries = originalExecuteQueries;
    });

    describe('main Express handler', () => {
        test('should create log, start calculation in background and return 200 with STARTED status and log_id', async () => {
            const mockLogId = 7001;
            const queries = [];
            let executedQueriesList = null;

            db.queryDb = jest.fn(async (sql, params) => {
                queries.push({ sql, params });
                if (sql.includes('insert into ou.logs')) {
                    return { error_code: 0, result: 1, data: [{ id: mockLogId }] };
                }
                if (sql.includes('ou.aasta')) {
                    return {
                        error_code: 0,
                        result: 2,
                        data: [
                            { kpv: '2026-01-31', rekvid: 63 },
                            { kpv: '2026-02-28', rekvid: 63 }
                        ]
                    };
                }
                if (sql.includes('update ou.logs')) {
                    return { error_code: 0, result: 1, data: [] };
                }
                return { error_code: 0, result: 1, data: [] };
            });

            db.executeQueries = jest.fn(async (sqls) => {
                executedQueriesList = sqls;
                return [{ error_code: 0, result: 1, data: [] }];
            });

            const req = {
                body: { user_id: 2477, rekv_id: 63 },
                query: {},
                params: {}
            };

            const res = {
                status: jest.fn().mockReturnThis(),
                send: jest.fn().mockReturnThis()
            };

            await lisaModule.main(req, res);

            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.send).toHaveBeenCalledWith({
                status: 200,
                result: 1,
                log_id: mockLogId,
                data: {
                    action: 'calcLisa1Lisa5',
                    status: 'STARTED',
                    log_id: mockLogId
                },
                error_message: null
            });

            // Ждем завершения фоновой задачи
            await new Promise(resolve => setTimeout(resolve, 50));

            // Проверяем вызовы
            expect(queries[0].sql).toContain('insert into ou.logs');
            expect(queries[0].params).toEqual([63, 2477, 'eelarve.salvesta_lisa_1_5_kontrol']);

            expect(executedQueriesList).not.toBeNull();
            expect(executedQueriesList).toHaveLength(2);
            expect(executedQueriesList[0]).toBe("call eelarve.salvesta_lisa_1_5_kontrol(2477, '2026-01-31', 63);");
            expect(executedQueriesList[1]).toBe("call eelarve.salvesta_lisa_1_5_kontrol(2477, '2026-02-28', 63);");

            expect(queries[2].sql).toContain('update ou.logs');
            expect(queries[2].params).toEqual(['success', null, mockLogId]);
        });

        test('should return 500 if createLog fails', async () => {
            db.queryDb = jest.fn(async (sql) => {
                if (sql.includes('insert into ou.logs')) {
                    throw new Error('Log DB error');
                }
                return { error_code: 0, result: 1, data: [] };
            });

            const req = {
                body: { user_id: 2477, rekv_id: 63 },
                query: {},
                params: {}
            };

            const res = {
                status: jest.fn().mockReturnThis(),
                send: jest.fn().mockReturnThis()
            };

            await lisaModule.main(req, res);

            expect(res.status).toHaveBeenCalledWith(500);
            expect(res.send).toHaveBeenCalledWith({
                status: 500,
                result: 0,
                log_id: null,
                data: null,
                error_message: 'Start calculation failed: DB Query failed: Log DB error'
            });
        });

        test('should update log with failed status if background calculation fails', async () => {
            const mockLogId = 8002;
            const queries = [];

            db.queryDb = jest.fn(async (sql, params) => {
                queries.push({ sql, params });
                if (sql.includes('insert into ou.logs')) {
                    return { error_code: 0, result: 1, data: [{ id: mockLogId }] };
                }
                if (sql.includes('ou.aasta')) {
                    throw new Error('Rekv data fetch error');
                }
                if (sql.includes('update ou.logs')) {
                    return { error_code: 0, result: 1, data: [] };
                }
                return { error_code: 0, result: 1, data: [] };
            });

            const req = {
                body: { user_id: 2477, rekv_id: 63 },
                query: {},
                params: {}
            };

            const res = {
                status: jest.fn().mockReturnThis(),
                send: jest.fn().mockReturnThis()
            };

            await lisaModule.main(req, res);

            expect(res.status).toHaveBeenCalledWith(200);

            await new Promise(resolve => setTimeout(resolve, 50));

            expect(queries[2].sql).toContain('update ou.logs');
            expect(queries[2].params[0]).toBe('failed');
            expect(queries[2].params[1]).toContain('Rekv data fetch error');
            expect(queries[2].params[2]).toBe(mockLogId);
        });
    });

    describe('executeCalculation helper', () => {
        test('should execute calculation with no rows found', async () => {
            const mockLogId = 9003;
            const queries = [];

            db.queryDb = jest.fn(async (sql, params) => {
                queries.push({ sql, params });
                if (sql.includes('insert into ou.logs')) {
                    return { error_code: 0, result: 1, data: [{ id: mockLogId }] };
                }
                if (sql.includes('ou.aasta')) {
                    return { error_code: 0, result: 0, data: [] };
                }
                return { error_code: 0, result: 1, data: [] };
            });

            const result = await lisaModule.executeCalculation(2477, 63);

            expect(result).toEqual({ count: 0, result: [] });
            expect(queries[2].params).toEqual(['success', null, mockLogId]);
        });
    });
});
