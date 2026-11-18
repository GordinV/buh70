'use strict';

const db = require('../libs/db');
db.queryDb = jest.fn();

const ariregisterStore = require('../libs/ariregisterStore');
const inforegisterService = require('../libs/inforegisterService');

describe('libs/ariregisterStore', () => {
    beforeEach(() => {
        db.queryDb.mockReset();
    });

    test('toBundle: полный маппинг, сокращённый businessType, пустые контакты, индекс в адресе и deleted_at', () => {
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
            businessType: 'OÜ',
            vatNumber: 'EE101339256',
            address: {
                fullAddress: 'Tähe tn 129b, Tartu linn, Tartu maakond, 50107',
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

    describe('почтовый индекс в buildAddress (task_ariregister_address_postcode)', () => {
        test('(а) 10020162: taisaadress + indeks -> добавляет ", 40110"', () => {
            const addr = ariregisterStore.buildAddress({
                taisaadress: 'Ida-Viru maakond, Narva-Jõesuu linn, Laagna küla, Jaagu',
                indeks: '40110',
                asukoht: 'Jaagu talu',
                ehak_tekst: 'Laagna küla, Narva-Jõesuu linn, Ida-Viru maakond'
            });
            expect(addr.fullAddress).toBe('Ida-Viru maakond, Narva-Jõesuu linn, Laagna küla, Jaagu, 40110');
            expect(addr.city).toBe('Laagna küla');
            expect(addr.street).toBe('Jaagu talu');
        });

        test('(б) indeks null -> taisaadress без изменений', () => {
            const addr = ariregisterStore.buildAddress({
                taisaadress: 'Harju maakond, Tallinn, Narva mnt 1',
                indeks: null
            });
            expect(addr.fullAddress).toBe('Harju maakond, Tallinn, Narva mnt 1');
        });

        test('(в) taisaadress уже оканчивается на ", 40110" -> индекс не дублируется', () => {
            const addr = ariregisterStore.buildAddress({
                taisaadress: 'Ida-Viru maakond, Narva-Jõesuu linn, Laagna küla, Jaagu, 40110',
                indeks: '40110'
            });
            expect(addr.fullAddress).toBe('Ida-Viru maakond, Narva-Jõesuu linn, Laagna küla, Jaagu, 40110');
        });

        test('(г) taisaadress null -> прежний fallback (asukoht, ehak_tekst, indeks / aadress)', () => {
            const addr1 = ariregisterStore.buildAddress({
                taisaadress: null,
                asukoht: 'Narva mnt 1',
                ehak_tekst: 'Tallinn',
                indeks: '10111'
            });
            expect(addr1.fullAddress).toBe('Narva mnt 1, Tallinn, 10111');

            const addr2 = ariregisterStore.buildAddress({
                taisaadress: null,
                aadress: 'Vana aadress 5'
            });
            expect(addr2.fullAddress).toBe('Vana aadress 5');
        });

        test('(д) buildDiff: локальный адрес "... Jaagu, 40110" совпадает с реестром -> diff по aadress нет', () => {
            const bundle = ariregisterStore.toBundle({
                regkood: '10020162',
                nimi: 'Jaagu Talu',
                oiguslik_vorm: 'Füüsilisest isikust ettevõtja',
                staatus_tekst: 'Registrisse kantud',
                taisaadress: 'Ida-Viru maakond, Narva-Jõesuu linn, Laagna küla, Jaagu',
                indeks: '40110',
                deleted_at: null
            }, 2026);
            expect(bundle.businessType).toBe('FIE');

            const diff = inforegisterService.buildDiff(
                {
                    nimetus: 'Jaagu Talu',
                    aadress: 'Ida-Viru maakond, Narva-Jõesuu linn, Laagna küla, Jaagu, 40110',
                    kmkr: null,
                    email: null,
                    tel: null
                },
                bundle
            );
            expect(diff).toEqual([]);
        });
    });

    describe('сокращения правовых форм (task_ariregister_legal_form_abbrev)', () => {
        test('(а) табличный тест на все 11 сокращений словаря', () => {
            const cases = [
                ['Osaühing', 'OÜ'],
                ['Aktsiaselts', 'AS'],
                ['Füüsilisest isikust ettevõtja', 'FIE'],
                ['Mittetulundusühing', 'MTÜ'],
                ['Korteriühistu', 'KÜ'],
                ['Usaldusühing', 'UÜ'],
                ['Täisühing', 'TÜ'],
                ['Sihtasutus', 'SA'],
                ['Euroopa äriühing (Societas Europaea)', 'SE'],
                ['Euroopa ühistu', 'SCE'],
                ['Kohaliku omavalitsuse asutus', 'KOV']
            ];
            cases.forEach(([input, expected]) => {
                expect(ariregisterStore.abbreviateLegalForm(input)).toBe(expected);
            });
        });

        test('(б) Tulundusühistu и неизвестное значение -> без изменений; null/"" -> null', () => {
            expect(ariregisterStore.abbreviateLegalForm('Tulundusühistu')).toBe('Tulundusühistu');
            expect(ariregisterStore.abbreviateLegalForm('Uus tundmatu vorm')).toBe('Uus tundmatu vorm');
            expect(ariregisterStore.abbreviateLegalForm(null)).toBeNull();
            expect(ariregisterStore.abbreviateLegalForm('   ')).toBeNull();
        });

        test('(в) сравнение без учёта регистра и пробелов по краям: " osaühing " -> "OÜ"', () => {
            expect(ariregisterStore.abbreviateLegalForm(' osaühing ')).toBe('OÜ');
            expect(ariregisterStore.abbreviateLegalForm('KOHALIKU OMAVALITSUSE ASUTUS')).toBe('KOV');
        });

        test('(г) toBundle для FIE-строки -> businessType "FIE"', () => {
            const b = ariregisterStore.toBundle({
                regkood: '10020162',
                nimi: 'Test FIE',
                oiguslik_vorm: 'Füüsilisest isikust ettevõtja',
                staatus_tekst: 'Registrisse kantud'
            }, 2026);
            expect(b.businessType).toBe('FIE');
        });
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
                    indeks: '50107',
                    deleted_at: null
                }]
            };
        });

        const ok = await client.getBundle('11735006', 2026);
        expect(ok.ok).toBe(true);
        expect(ok.source).toBe('ariregister');
        expect(ok.fetchedAt).toBe('2026-11-17');
        expect(ok.data.businessType).toBe('OÜ');
        expect(ok.data.address.fullAddress).toBe('Tähe tn 129b, Tartu, 50107');
        expect(ok.data.vatNumber).toBeNull();
        expect(client.getUsage()).toEqual({spent: 0, remainingYear: null});
    });
});
