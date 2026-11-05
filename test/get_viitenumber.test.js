'use strict';

const getViitenumber = require('../routes/get_viitenumber');
const db = require('../libs/db');

describe('get_viitenumber route controller', () => {
    const VALID_HASH = '2f2b7890e7951a55d589c2bb5df2d0f59cd10877';
    let originalQueryDb;
    let req, res;

    beforeEach(() => {
        originalQueryDb = db.queryDb;
        req = {
            params: { hash: VALID_HASH },
            body: {}
        };
        res = {
            status: jest.fn().mockReturnThis(),
            send: jest.fn().mockReturnThis(),
            render: jest.fn()
        };
    });

    afterEach(() => {
        db.queryDb = originalQueryDb;
    });

    describe('GET /:hash/viitenumber', () => {
        test('should return 403 when hash is invalid', async () => {
            req.params.hash = 'invalid-hash-value';

            await getViitenumber.get(req, res);

            expect(res.status).toHaveBeenCalledWith(403);
            expect(res.send).toHaveBeenCalledWith('Juurdepääs keelatud: vigane turvakood');
            expect(res.render).not.toHaveBeenCalled();
        });

        test('should load institutions and render viitenumber template on valid hash', async () => {
            const mockRekvData = [
                { id: 63, nimetus: 'Narva Linnavalitsus' },
                { id: 119, nimetus: 'Lasteaed Päikene' }
            ];
            db.queryDb = jest.fn(async () => ({ data: mockRekvData }));

            await getViitenumber.get(req, res);

            expect(db.queryDb).toHaveBeenCalledWith(
                expect.stringContaining('FROM ou.rekv'),
                []
            );
            expect(res.render).toHaveBeenCalledWith('viitenumber', expect.objectContaining({
                title: 'Viitenumbri päring',
                hash: VALID_HASH,
                rekvList: mockRekvData,
                inputViitenumber: '',
                selectedTyyp: '1',
                result: null,
                error: null
            }));
        });
    });

    describe('POST /:hash/viitenumber', () => {
        test('should return 403 when hash is invalid', async () => {
            req.params.hash = 'invalid-hash-value';

            await getViitenumber.post(req, res);

            expect(res.status).toHaveBeenCalledWith(403);
            expect(res.send).toHaveBeenCalledWith('Juurdepääs keelatud: vigane turvakood');
        });

        test('should return validation error if completely empty', async () => {
            req.body = { viitenumber: '', rekv_id: '', objekt_number: '', tyyp: '1' };
            db.queryDb = jest.fn(async () => ({ data: [] }));

            await getViitenumber.post(req, res);

            expect(res.render).toHaveBeenCalledWith('viitenumber', expect.objectContaining({
                error: 'Sisesta viitenumber või täida asutus ja dokumendi number',
                result: null
            }));
        });

        test('should return mutual exclusion error if both viitenumber and params are filled', async () => {
            req.body = {
                viitenumber: '3066087775166',
                rekv_id: '63',
                objekt_number: '12345678',
                tyyp: '1'
            };
            db.queryDb = jest.fn(async () => ({ data: [] }));

            await getViitenumber.post(req, res);

            expect(res.render).toHaveBeenCalledWith('viitenumber', expect.objectContaining({
                error: 'Täida kas viitenumber VÕI vali asutus ja dokumendi number (mõlemat korraga ei saa täita)',
                result: null
            }));
        });

        test('should execute reverse lookup (get_data_from_viitenumber) when only viitenumber is given', async () => {
            req.body = {
                viitenumber: '3066087775166'
            };

            const mockReverseResult = {
                error: false,
                error_description: null,
                asutus: 'Narva Linnavalitsus',
                selgitus: 'Arve number: 101, arve kpv: 01.02.2026'
            };

            db.queryDb = jest.fn(async (sql) => {
                if (sql.includes('libs.get_data_from_viitenumber')) {
                    return { data: [{ data: mockReverseResult }] };
                }
                return { data: [{ id: 63, nimetus: 'Narva Linnavalitsus' }] };
            });

            await getViitenumber.post(req, res);

            expect(db.queryDb).toHaveBeenCalledWith(
                expect.stringContaining('SELECT libs.get_data_from_viitenumber'),
                ['3066087775166']
            );
            expect(res.render).toHaveBeenCalledWith('viitenumber', expect.objectContaining({
                result: expect.objectContaining({
                    viitenumber: '3066087775166',
                    asutus: 'Narva Linnavalitsus',
                    selgitus: 'Arve number: 101, arve kpv: 01.02.2026'
                }),
                inputViitenumber: '3066087775166',
                error: null
            }));
        });

        test('should execute forward calculation (get_viitenumber_from_regkood) when params are given', async () => {
            req.body = {
                rekv_id: '63',
                tyyp: '2',
                objekt_number: '12345678'
            };

            const mockProcResult = {
                error: false,
                error_description: null,
                asutus: 'Narva Linnavalitsus',
                viitenumber: '20630001234',
                selgitus: 'Reg.kood: 12345678, Nimetus: Test OÜ'
            };

            db.queryDb = jest.fn(async (sql) => {
                if (sql.includes('libs.get_viitenumber_from_regkood')) {
                    return { data: [{ data: mockProcResult }] };
                }
                return { data: [{ id: 63, nimetus: 'Narva Linnavalitsus' }] };
            });

            await getViitenumber.post(req, res);

            expect(db.queryDb).toHaveBeenCalledWith(
                expect.stringContaining('SELECT libs.get_viitenumber_from_regkood'),
                [63, '12345678', '2']
            );
            expect(res.render).toHaveBeenCalledWith('viitenumber', expect.objectContaining({
                result: mockProcResult,
                selectedRekv: '63',
                selectedTyyp: '2',
                objektNumber: '12345678',
                error: null
            }));
        });
    });
});
