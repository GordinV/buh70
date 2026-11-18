'use strict';

const crypto = require('crypto');
const db = require('../libs/db');
db.queryDb = jest.fn();

jest.mock('../classes/DocumentTemplate', () => jest.fn());
const inforegister = require('../libs/inforegister');
const service = require('../libs/inforegisterService');

describe('libs/inforegisterService', () => {
    beforeEach(() => {
        db.queryDb.mockReset();
    });

    test('resolveInforegisterToken: проверяет sha256, active и scopes', async () => {
        const token = 'my-secret-token';
        const sha = crypto.createHash('sha256').update(token, 'utf8').digest('hex');

        // Нет hash -> 401 без обращения к БД
        expect(await service.resolveInforegisterToken('', 'lookup', 3)).toMatchObject({
            ok: false,
            status: 401,
            reason: 'unauthorized_hash'
        });
        expect(db.queryDb).not.toHaveBeenCalled();

        // Есть токен только для batch -> 403 на lookup
        db.queryDb.mockReturnValueOnce(Promise.resolve({
            data: [{tokens: [{token_sha256: sha, user_id: 11770, rekv_id: 63, label: 'ai', scopes: ['batch'], active: true}]}]
        }));
        expect(await service.resolveInforegisterToken(token, 'lookup', 3)).toMatchObject({
            ok: false,
            status: 403,
            reason: 'forbidden_scope'
        });

        // Валидный токен со scope lookup
        db.queryDb.mockReturnValueOnce(Promise.resolve({
            data: [{tokens: [{token_sha256: sha, user_id: 11770, rekv_id: 63, label: 'ai', scopes: ['batch', 'lookup'], active: true}]}]
        }));
        expect(await service.resolveInforegisterToken(token, 'lookup', 3)).toEqual({
            ok: true,
            userId: 11770,
            rekvId: 63,
            label: 'ai'
        });
    });

    test('buildDiff: выявляет расхождения адреса, пустых полей, контактов и closed, игнорируя регистр/пробелы', () => {
        const local = {
            id: 55,
            regkood: '11735006',
            nimetus: '  register   oü ',
            aadress: 'Vana tn 1, Tallinn',
            kmkr: '',
            email: 'INFO@IR.EE',
            tel: '+372 744 6644',
            staatus: 1
        };
        const bundle = {
            name: 'REGISTER OÜ',
            registryStatus: 'Kustutatud',
            vatNumber: 'EE101339256',
            address: {fullAddress: 'Tähe tn 129b, Tartu'},
            contacts: {emails: ['info@ir.ee'], phones: ['+3727446644']}
        };

        const diff = service.buildDiff(local, bundle);
        expect(diff).toEqual([
            {field: 'aadress', local: 'Vana tn 1, Tallinn', registry: 'Tähe tn 129b, Tartu'},
            {field: 'kmkr', local: null, registry: 'EE101339256'},
            {field: 'closed', local: false, registry: 'Kustutatud'}
        ]);
    });

    test('lookupOne: идёт в реестр даже если организация есть в libs.asutus, и не вызывает sp_salvesta_asutus', async () => {
        db.queryDb.mockReturnValueOnce(Promise.resolve({
            data: [{id: 10, regkood: '11735006', nimetus: 'REGISTER OÜ', aadress: 'Tähe tn 129b, Tartu', kmkr: 'EE101339256', email: 'info@ir.ee', tel: '+3727446644', staatus: 1}]
        }));
        const mockClient = {
            getBundle: jest.fn().mockReturnValue(Promise.resolve({
                ok: true,
                source: 'cache',
                fetchedAt: '2026-11-16T10:00:00.000Z',
                data: {
                    name: 'REGISTER OÜ',
                    registryStatus: 'Registrisse kantud',
                    vatNumber: 'EE101339256',
                    address: {fullAddress: 'Tähe tn 129b, Tartu'},
                    contacts: {emails: ['info@ir.ee'], phones: ['+3727446644']}
                }
            }))
        };

        const res = await service.lookupOne('11735006', mockClient);
        expect(res.ok).toBe(true);
        expect(res.source).toBe('cache');
        expect(res.local.id).toBe(10);
        expect(res.diff).toEqual([]);
        expect(mockClient.getBundle).toHaveBeenCalledWith('11735006', undefined);
        expect(db.queryDb).toHaveBeenCalledTimes(1);
    });

    test('createClient skipCacheRead: обходит чтение кэша и обновляет его', async () => {
        const saved = {
            'bundle:11735006:2026': {payload: {name: 'OLD OÜ'}, negative: false, fetchedAt: '2026-11-01T00:00:00.000Z'}
        };
        const store = {
            get: jest.fn(async (k) => saved[k] || null),
            set: jest.fn(async (k, payload, negative) => {
                saved[k] = {payload, negative};
            })
        };
        const http = jest.fn(async () => ({
            status: 200,
            headers: {'x-ratelimit-remaining-year': '88'},
            body: JSON.stringify({base_info: {company_name: 'NEW OÜ', registry_status_text: 'Registrisse kantud'}})
        }));

        const c = inforegister.createClient({
            apiKey: 'k',
            store: store,
            skipCacheRead: true,
            maxCalls: 1,
            http: http,
            now: () => new Date('2026-11-16T12:00:00.000Z').getTime()
        });
        const r = await c.getBundle('11735006', 2026);
        expect(r.ok).toBe(true);
        expect(r.source).toBe('api');
        expect(r.data.name).toBe('NEW OÜ');
        expect(http).toHaveBeenCalledTimes(1);
        expect(saved['bundle:11735006:2026'].payload.name).toBe('NEW OÜ');
    });
});

describe('libs/inforegisterService: isEstonianAddress и lookupOne (not_in_registry)', () => {
    const db = require('../libs/db');
    const service = require('../libs/inforegisterService');

    beforeEach(() => {
        db.queryDb = jest.fn();
    });

    test('(а) isEstonianAddress корректно различает эстонские, пустые и иностранные адреса', () => {
        expect(service.isEstonianAddress('Ida-Viru maakond, Narva linn, Puškini 10')).toBe(true);
        expect(service.isEstonianAddress('Peetri 3, Narva 20308')).toBe(true);
        expect(service.isEstonianAddress('Narva mnt. 80-68 Johvi 41536')).toBe(true);
        expect(service.isEstonianAddress('Kiiu sjk  74604  Harjumaa')).toBe(true);
        expect(service.isEstonianAddress('Tallinn\r\nKesklinn')).toBe(true);
        expect(service.isEstonianAddress('Tartu maakond, Tartu linn, Tartu linn, Riia tn 132, 50096')).toBe(true);
        expect(service.isEstonianAddress('RIIA 185, TARTU')).toBe(true);
        expect(service.isEstonianAddress('Aasa32,Narva20605')).toBe(true);
        expect(service.isEstonianAddress('Liivalaia 20a, 10118Tallinn')).toBe(true);
        expect(service.isEstonianAddress('Peterburi tee 46, Tallinn')).toBe(true);
        expect(service.isEstonianAddress('')).toBe(false);
        expect(service.isEstonianAddress(null)).toBe(false);
        expect(service.isEstonianAddress('Riga, Brivibas 1, Latvia')).toBe(false);
        expect(service.isEstonianAddress('Helsinki, Finland 00100')).toBe(false);
        expect(service.isEstonianAddress('Neumarkt Galerie,D-50667,Koln-Germany')).toBe(false);
        expect(service.isEstonianAddress('Riga, LV-1048,Latvija,Slokas iela 1')).toBe(false);
        expect(service.isEstonianAddress('Krapivny per.5 194044 St.Peterburg Russia')).toBe(false);
    });

    test('(б) lookupOne: not_found + local 10035608 с эстонским адресом -> ok:true, closed:true, status:closed, reason:not_in_registry', async () => {
        db.queryDb.mockReturnValueOnce(Promise.resolve({
            data: [{id: 10, regkood: '10035608', nimetus: '  Vana Firma OÜ ', aadress: 'Peetri 3, Narva 20308', kmkr: null, staatus: 1}]
        }));
        const client = {
            getBundle: async () => ({ok: false, reason: 'not_found', error: 'missing', fetchedAt: '2026-11-18'}),
            getUsage: () => ({spent: 0, remainingYear: null})
        };

        const r = await service.lookupOne('10035608', client, {year: 2026});
        expect(r.ok).toBe(true);
        expect(r.status).toBe('closed');
        expect(r.closed).toBe(true);
        expect(r.reason).toBe('not_in_registry');
        expect(r.source).toBe('ariregister');
        expect(r.fetched_at).toBe('2026-11-18');
        expect(r.diff).toEqual([]);
        expect(r.registry).toEqual({
            name: 'Vana Firma OÜ',
            regCode: '10035608',
            registryStatus: 'Kustutatud',
            businessType: null,
            vatNumber: null,
            address: null,
            contacts: {emails: [], phones: [], webs: []},
            latestEmployeeCount: null,
            latestPeriod: null,
            year: 2026
        });
    });

    test('(в, г, д, е) код 7x, пустой/иностранный адрес, нет local, registry_not_loaded -> ok:false', async () => {
        const notFoundClient = {
            getBundle: async () => ({ok: false, reason: 'not_found', error: 'missing', fetchedAt: '2026-11-18'})
        };

        // (в) 75026902 (гос/KOV)
        db.queryDb.mockReturnValueOnce(Promise.resolve({
            data: [{id: 1, regkood: '75026902', nimetus: 'Narva Lasteaed', aadress: 'Narva 20308', staatus: 1}]
        }));
        const r7 = await service.lookupOne('75026902', notFoundClient);
        expect(r7.ok).toBe(false);
        expect(r7.reason).toBe('not_found');

        // (г) пустой и иностранный адрес
        db.queryDb.mockReturnValueOnce(Promise.resolve({
            data: [{id: 2, regkood: '10035608', nimetus: 'Empty Addr OÜ', aadress: '', staatus: 1}]
        }));
        expect((await service.lookupOne('10035608', notFoundClient)).ok).toBe(false);

        db.queryDb.mockReturnValueOnce(Promise.resolve({
            data: [{id: 3, regkood: '10035608', nimetus: 'Latvia SIA', aadress: 'Riga, Brivibas 1, Latvia', staatus: 1}]
        }));
        expect((await service.lookupOne('10035608', notFoundClient)).ok).toBe(false);

        // (д) нет local
        db.queryDb.mockReturnValueOnce(Promise.resolve({data: []}));
        expect((await service.lookupOne('10035608', notFoundClient)).ok).toBe(false);

        // (е) registry_not_loaded -> 503 (registry_unavailable)
        db.queryDb.mockReturnValueOnce(Promise.resolve({
            data: [{id: 4, regkood: '10035608', nimetus: 'Firma OÜ', aadress: 'Tallinn 10111', staatus: 1}]
        }));
        const rUnavail = await service.lookupOne('10035608', {
            getBundle: async () => ({ok: false, reason: 'registry_not_loaded', error: 'empty'})
        });
        expect(rUnavail.ok).toBe(false);
        expect(rUnavail.reason).toBe('registry_not_loaded');
        expect(rUnavail.status).toBe('registry_unavailable');
    });
});
