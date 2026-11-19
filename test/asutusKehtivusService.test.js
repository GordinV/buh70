'use strict';

const db = require('../libs/db');
db.queryDb = jest.fn();

const kehtivusService = require('../libs/asutusKehtivusService');

describe('libs/asutusKehtivusService', () => {
    const freshMeta = {
        file_date: '2026-11-19',
        applied_at: '2026-11-19T06:32:00+02:00',
        rows_total: 381641
    };

    test('(а, б, в) findClosedCandidates: deleted_at -> deleted_from_registry; 1/8/9+эст.адрес -> not_in_registry; 7x и иностранные отсекаются', async () => {
        const queryFn = jest.fn(async () => ({
            result: 1,
            data: [
                {
                    asutus_id: 1,
                    regkood: '10000001',
                    nimetus: 'Deleted OÜ',
                    aadress: 'Tallinn',
                    old_kehtivus: '',
                    in_registry: true,
                    deleted_date: '2026-11-18'
                },
                {
                    asutus_id: 2,
                    regkood: '10035608',
                    nimetus: 'Missing Est OÜ',
                    aadress: 'Peetri 3, Narva 20308',
                    old_kehtivus: '2099-12-31',
                    in_registry: false,
                    deleted_date: null
                },
                {
                    asutus_id: 3,
                    regkood: '75026902',
                    nimetus: 'Narva Lasteaed',
                    aadress: 'Narva 20308',
                    old_kehtivus: '',
                    in_registry: false,
                    deleted_date: null
                },
                {
                    asutus_id: 4,
                    regkood: '10247291',
                    nimetus: 'Foreign GmbH',
                    aadress: 'Neumarkt Galerie,D-50667,Koln-Germany',
                    old_kehtivus: '',
                    in_registry: false,
                    deleted_date: null
                },
                {
                    asutus_id: 5,
                    regkood: '10185632',
                    nimetus: 'Bad Checksum OÜ',
                    aadress: 'Tallinn 10111',
                    old_kehtivus: '',
                    in_registry: false,
                    deleted_date: null
                },
                {
                    asutus_id: 6,
                    regkood: '10247291',
                    nimetus: 'Empty Addr AS',
                    aadress: '',
                    old_kehtivus: '',
                    in_registry: false,
                    deleted_date: null
                }
            ]
        }));

        const list = await kehtivusService.findClosedCandidates(queryFn, '2026-11-19');
        expect(list.length).toBe(3);
        expect(list[0]).toMatchObject({
            asutus_id: 1,
            regkood: '10000001',
            reason: 'deleted_from_registry',
            kehtivus: '2026-11-18',
            old_kehtivus: null
        });
        expect(list[1]).toMatchObject({
            asutus_id: 2,
            regkood: '10035608',
            reason: 'not_in_registry',
            kehtivus: '2026-11-19',
            old_kehtivus: '2099-12-31'
        });
        expect(list[2]).toMatchObject({
            asutus_id: 6,
            regkood: '10247291',
            reason: 'not_in_registry',
            kehtivus: '2026-11-19'
        });

        // SQL не выбирает Likvideerimisel/Pankrotis без deleted_at и отсекает 7x
        const sql = queryFn.mock.calls[0][0];
        expect(sql).toContain('r.deleted_at IS NOT NULL');
        expect(sql).toContain("^[189]");
    });

    test('(г) meta вчерашняя или rows_total < 300000 -> skipped registry_stale, set_asutuse_kehtivus не вызывается', async () => {
        const queryYesterday = jest.fn(async () => ({
            result: 1,
            data: [{file_date: '2026-11-18', applied_at: '2026-11-18T06:32:00+02:00', rows_total: 381641}]
        }));
        const res1 = await kehtivusService.runKehtivusCheck({
            dryRun: false,
            queryFn: queryYesterday,
            now: '2026-11-19T06:40:00+02:00'
        });
        expect(res1.status).toBe('skipped');
        expect(res1.reason).toBe('registry_stale');
        expect(queryYesterday).toHaveBeenCalledTimes(1);

        const querySmall = jest.fn(async () => ({
            result: 1,
            data: [{file_date: '2026-11-19', applied_at: '2026-11-19T06:32:00+02:00', rows_total: 100}]
        }));
        const res2 = await kehtivusService.runKehtivusCheck({
            dryRun: false,
            queryFn: querySmall,
            now: '2026-11-19T06:40:00+02:00'
        });
        expect(res2.status).toBe('skipped');
        expect(res2.reason).toBe('registry_stale');
        expect(querySmall).toHaveBeenCalledTimes(1);
    });

    test('(д) dryRun -> set_asutuse_kehtivus не вызывается, would_close заполнен', async () => {
        const queryFn = jest.fn(async (sql) => {
            if (sql.indexOf('ariregister_meta') !== -1) return {result: 1, data: [freshMeta]};
            return {
                result: 1,
                data: [{asutus_id: 10, regkood: '10035608', nimetus: 'Old OÜ', aadress: 'Tallinn 10111', old_kehtivus: '', in_registry: false}]
            };
        });

        const res = await kehtivusService.runKehtivusCheck({
            dryRun: true,
            queryFn: queryFn,
            now: '2026-11-19T06:40:00+02:00'
        });
        expect(res.status).toBe('success');
        expect(res.dry_run).toBe(true);
        expect(res.candidates_total).toBe(1);
        expect(res.would_close.length).toBe(1);
        expect(res.closed).toEqual([]);
        expect(res.totalClosed).toBe(0);
        expect(queryFn).toHaveBeenCalledTimes(2);
    });

    test('(е) кандидатов > maxClose и не dryRun -> ни одного вызова set_asutuse_kehtivus, failed too_many_candidates', async () => {
        const queryFn = jest.fn(async (sql) => {
            if (sql.indexOf('ariregister_meta') !== -1) return {result: 1, data: [freshMeta]};
            return {
                result: 1,
                data: [
                    {asutus_id: 1, regkood: '10000001', nimetus: 'A OÜ', aadress: 'Tallinn 10111', old_kehtivus: '', in_registry: false},
                    {asutus_id: 2, regkood: '10035608', nimetus: 'B OÜ', aadress: 'Tartu 50090', old_kehtivus: '', in_registry: false},
                    {asutus_id: 3, regkood: '10247291', nimetus: 'C OÜ', aadress: 'Narva 20308', old_kehtivus: '', in_registry: false}
                ]
            };
        });

        const res = await kehtivusService.runKehtivusCheck({
            dryRun: false,
            maxClose: 2,
            queryFn: queryFn,
            now: '2026-11-19T06:40:00+02:00'
        });
        expect(res.status).toBe('failed');
        expect(res.reason).toBe('too_many_candidates');
        expect(res.retryable).toBe(false);
        expect(res.candidates_total).toBe(3);
        expect(res.closed).toEqual([]);
        expect(res.would_close.length).toBe(3);
        expect(queryFn).toHaveBeenCalledTimes(2);
    });

    test('(ж) ошибка одной карточки не останавливает остальные; "pole õigused" останавливает сразу', async () => {
        const queryFn = jest.fn(async (sql, params) => {
            if (sql.indexOf('ariregister_meta') !== -1) return {result: 1, data: [freshMeta]};
            if (sql.indexOf('FROM libs.asutus') !== -1) {
                return {
                    result: 1,
                    data: [
                        {asutus_id: 1, regkood: '10000001', nimetus: 'Err OÜ', aadress: 'Tallinn 10111', old_kehtivus: '', in_registry: false},
                        {asutus_id: 2, regkood: '10035608', nimetus: 'Skip OÜ', aadress: 'Tartu 50090', old_kehtivus: '', in_registry: false},
                        {asutus_id: 3, regkood: '10247291', nimetus: 'Fallback Name', aadress: 'Narva 20308', old_kehtivus: '', in_registry: false}
                    ]
                };
            }
            if (params[0] === 1) return {error_code: 9, error_message: 'DB error on row 1'};
            if (params[0] === 2) return {result: 1, data: [{res: []}]};
            return {result: 1, data: [{res: [{asutus_id: 3, regkood: '10035608', nimetus: 'Osaühing H.Uuetalu', staatus: 'suletatud', kehtivus: '2026-11-19', old_kehtivus: null}]}]};
        });

        const res = await kehtivusService.runKehtivusCheck({
            dryRun: false,
            userId: 11770,
            queryFn: queryFn,
            now: '2026-11-19T06:40:00+02:00'
        });
        expect(res.status).toBe('success');
        expect(res.totalErrors).toBe(1);
        expect(res.totalClosed).toBe(1);
        expect(res.skipped_already.length).toBe(1);
        // (р) regkood и nimetus берутся из ответа функции
        expect(res.closed[0].regkood).toBe('10035608');
        expect(res.closed[0].nimetus).toBe('Osaühing H.Uuetalu');
        expect(res.closed[0].aadress).toBe('Narva 20308');

        // 'pole õigused' -> остановка на первой карточке
        const noRightsFn = jest.fn(async (sql) => {
            if (sql.indexOf('ariregister_meta') !== -1) return {result: 1, data: [freshMeta]};
            if (sql.indexOf('FROM libs.asutus') !== -1) {
                return {
                    result: 1,
                    data: [
                        {asutus_id: 1, regkood: '10000001', nimetus: 'A OÜ', aadress: 'Tallinn 10111', old_kehtivus: '', in_registry: false},
                        {asutus_id: 2, regkood: '10035608', nimetus: 'B OÜ', aadress: 'Tartu 50090', old_kehtivus: '', in_registry: false}
                    ]
                };
            }
            return {error_code: 9, error_message: 'Viga: pole õigused'};
        });

        const resNoRights = await kehtivusService.runKehtivusCheck({
            dryRun: false,
            userId: 11770,
            queryFn: noRightsFn,
            now: '2026-11-19T06:40:00+02:00'
        });
        expect(resNoRights.status).toBe('failed');
        expect(resNoRights.reason).toBe('no_rights');
        expect(resNoRights.retryable).toBe(false);
        expect(noRightsFn).toHaveBeenCalledTimes(3); // meta + candidates + 1 call
    });
});
