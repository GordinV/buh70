'use strict';

const db = require('../../libs/db');
const readLogModule = require('./readLog');

describe('readLog route tests', () => {
    let mockReq;
    let mockRes;
    let queryDbSpy;

    beforeEach(() => {
        mockReq = {
            query: {},
            body: {},
            params: {}
        };

        mockRes = {
            statusCode: null,
            sentData: null,
            status: function (code) {
                this.statusCode = code;
                return this;
            },
            send: function (data) {
                this.sentData = data;
                return this;
            }
        };

        queryDbSpy = jest.spyOn(db, 'queryDb');
    });

    afterEach(() => {
        if (queryDbSpy) {
            queryDbSpy.mockRestore();
        }
    });

    it('should return status 400 when user_id is missing', async () => {
        mockReq.params = { task_name: 'testTask' };

        await readLogModule.main(mockReq, mockRes);

        expect(mockRes.statusCode).toBe(400);
        expect(mockRes.sentData).toEqual({
            error_message: 'Viga: puudub user_id',
            result: 0,
            data: null
        });
    });

    it('should return status 400 when task_name is missing', async () => {
        mockReq.params = { user_id: 123 };

        await readLogModule.main(mockReq, mockRes);

        expect(mockRes.statusCode).toBe(400);
        expect(mockRes.sentData).toEqual({
            error_message: 'Viga: puudub task_name',
            result: 0,
            data: null
        });
    });

    it('should accept userId and taskName from params, body, or query with alternative keys', async () => {
        const mockDbResult = {
            error_code: 0,
            result: 1,
            error_message: null,
            data: [{
                flow: 'testFlow',
                status: 'done',
                exec_start: '2026-09-14 10:00:00',
                exec_end: '2026-09-14 10:05:00'
            }]
        };
        queryDbSpy.mockReturnValue(Promise.resolve(mockDbResult));

        // Test with req.body containing userid_id and taskName
        mockReq.body = { userid_id: 456, taskName: 'calcSaldo' };

        await readLogModule.main(mockReq, mockRes);

        expect(mockRes.statusCode).toBe(200);
        expect(mockRes.sentData).toEqual(mockDbResult);
        expect(queryDbSpy).toHaveBeenCalledTimes(1);
        expect(queryDbSpy.mock.calls[0][1]).toEqual([456, 'calcSaldo']);
    });

    it('should return status 200 and query result when valid user_id and task_name are provided', async () => {
        const mockDbResult = {
            error_code: 0,
            result: 1,
            error_message: null,
            data: [{
                flow: 'arvestaTaabel',
                status: 'finished',
                exec_start: '2026-09-14 08:00:00',
                exec_end: '2026-09-14 08:01:00'
            }]
        };

        queryDbSpy.mockReturnValue(Promise.resolve(mockDbResult));

        mockReq.params = {
            user_id: 1,
            task_name: 'arvestaTaabel'
        };

        await readLogModule.main(mockReq, mockRes);

        expect(mockRes.statusCode).toBe(200);
        expect(mockRes.sentData).toEqual(mockDbResult);
        expect(queryDbSpy).toHaveBeenCalledTimes(1);

        const [sql, params] = queryDbSpy.mock.calls[0];
        expect(sql).toContain('ou.logs');
        expect(sql).toContain('user_id = $1');
        expect(params).toEqual([1, 'arvestaTaabel']);
    });

    it('should return status 500 when database query throws an error', async () => {
        queryDbSpy.mockReturnValue(Promise.reject(new Error('Connection timeout')));

        mockReq.params = {
            user_id: 99,
            task_name: 'testTask'
        };

        await readLogModule.main(mockReq, mockRes);

        expect(mockRes.statusCode).toBe(500);
        expect(mockRes.sentData).toEqual({
            error_message: 'Viga: DB Query failed: Connection timeout',
            result: 0,
            data: null
        });
    });
});
