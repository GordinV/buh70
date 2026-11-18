'use strict';

const db = require('../libs/db');
db.queryDb = jest.fn();

const ariregisterStore = require('../libs/ariregisterStore');

describe('libs/ariregisterStore', () => {
    beforeEach(() => {
        db.queryDb.mockReset();
    });

    test('toBundle: полный маппинг, пустые контакты, fallback адреса и deleted_at', () => {
        const bundle = ariregisterStore.toBundle({
            regkood: '11735006',
            nimi: 'Register OÜ',
            oiguslik_vorm: 'Osaühing',
            kmkr_nr: 'EE101339256',
            staatus_tekst: 'Registrisse kantud',
            aadress: 'Vana tn 1',
            asukoht: 'Tähe tn 129b',
            ehak_tekst: 'Tartu linn, Tartu maakond',
            indeks: '50107',
            taisaadress: 'Tähe tn 129b, Tartu linn, Tartu maakond',
            deleted_at: null
        }, 2026);

        expect(bundle).toEqual({
            name: 'Register OÜ',
            regCode: '11735006',
            registryStatus: 'Registrisse kantud',
            businessType: 'Osaühing',
            vatNumber: 'EE101339256',
            address: {
                fullAddress: 'Tähe tn 129b, Tartu linn, Tartu maakond',
                city: 'Tartu linn',
                street: 'Tähe tn 129b'
            },
            contacts: {emails: [], phones: [], webs: []},
            latestEmployeeCount: null,
            latestPeriod: null,
            year: 2026
        });

        const deletedBundle = ariregisterStore.toBundle({
            regkood: '11735006',
            nimi: 'Deleted OÜ',
            staatus_tekst: 'Registrisse kantud',
            deleted_at: '2026-11-18T00:00:00Z'
        }, 2026);
        expect(deletedBundle.registryStatus).toBe('Kustutatud');
        expect(deletedBundle.address).toBeNull();
    });

    test('createStoreClient: invalid_reg_code без запроса к БД', async () => {
        const queryFn = jest.fn();
        const client = ariregisterStore.createStoreClient({queryFn: queryFn});
        const res = await client.getBundle('1234');
        expect(res.ok).toBe(false);
        expect(res.reason).toBe('invalid_reg_code');
        expect(queryFn).not.toHaveBeenCalled();
    });

    test('createStoreClient: пустая ariregister_meta -> registry_not_loaded', async () => {
        const queryFn = jest.fn(async () => ({result: 0, data: []}));
        const client = ariregisterStore.createStoreClient({queryFn: queryFn});
        const res = await client.getBundle('11735006');
        expect(res.ok).toBe(false);
        expect(res.reason).toBe('registry_not_loaded');
    });

    test('createStoreClient: кода нет -> not_found; код есть -> ok, fetchedAt из meta.file_date', async () => {
        const queryFn = jest.fn(async (sql) => {
            if (sql.indexOf('ariregister_meta') !== -1) {
                return {result: 1, data: [{file_date: '2026-11-17', rows_total: 381556}]};
            }
            return {result: 0, data: []};
        });
        const client = ariregisterStore.createStoreClient({queryFn: queryFn});

        const notFound = await client.getBundle('99999999');
        expect(notFound.ok).toBe(false);
        expect(notFound.reason).toBe('not_found');

        queryFn.mockImplementation(async (sql) => {
            if (sql.indexOf('ariregister_meta') !== -1) {
                return {result: 1, data: [{file_date: '2026-11-17', rows_total: 381556}]};
            }
            return {
                result: 1,
                data: [{
                    regkood: '11735006',
                    nimi: 'Register OÜ',
                    oiguslik_vorm: 'Osaühing',
                    kmkr_nr: '',
                    staatus_tekst: 'Registrisse kantud',
                    taisaadress: 'Tähe tn 129b, Tartu',
                    ehak_tekst: 'Tartu linn',
                    asukoht: 'Tähe tn 129b',
                    deleted_at: null
                }]
            };
        });

        const ok = await client.getBundle('11735006', 2026);
        expect(ok.ok).toBe(true);
        expect(ok.source).toBe('ariregister');
        expect(ok.fetchedAt).toBe('2026-11-17');
        expect(ok.data.vatNumber).toBeNull();
        expect(client.getUsage()).toEqual({spent: 0, remainingYear: null});
    });
});
