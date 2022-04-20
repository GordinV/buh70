DROP FUNCTION IF EXISTS eelarve.sp_koosta_saldoandmik(INTEGER, JSON);

CREATE OR REPLACE FUNCTION eelarve.sp_koosta_saldoandmik(IN user_id INTEGER,
                                                         IN params JSON,
                                                         OUT error_code INTEGER,
                                                         OUT result INTEGER,
                                                         OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_rekvid     INTEGER = coalesce((params ->> 'rekvid') :: INTEGER, (SELECT rekvid
                                                                       FROM ou.userid
                                                                       WHERE id = user_id));
    l_kpv        DATE    = params ->> 'kpv';
    l_kpv1       DATE    = date(year(l_kpv), month(l_kpv), 1);
    l_kpv2       DATE    = gomonth(l_kpv1, 1) - 1;
    kas_delete   INTEGER = coalesce((params ->> 'tyyp') :: INTEGER, 1);
    l_kond       INTEGER = coalesce((params ->> 'kond') :: INTEGER, 1); -- koosta kond aruanne
    v_rekv       RECORD;
    l_oma_tp     TEXT    = fnc_getomatp(L_rekvid, year(l_kpv));
    l_asutuse_tp TEXT;
    l_params     JSON;
    l_tulemus    INTEGER;
BEGIN

    RAISE NOTICE 'kond l_rekvid %', l_rekvid;

    IF NOT empty(kas_delete)
    THEN

        -- re-arvesta saldoandmik
        DELETE
        FROM eelarve.saldoandmik
        WHERE aasta = year(l_kpv)
          AND kuu = month(l_kpv)
          AND rekvid IN (SELECT rekv_id
                         FROM get_asutuse_struktuur(l_rekvid));

        IF NOT empty(l_kond) AND l_rekvid = 63
        THEN

            DELETE
            FROM eelarve.saldoandmik
            WHERE aasta = year(l_kpv)
              AND kuu = month(l_kpv)
              AND rekvid = 999;

        END IF;
    END IF;

    -- Kontrolin kas arvestame saldoandmik uuesti

    IF NOT exists(SELECT id
                  FROM eelarve.saldoandmik
                  WHERE aasta = year(l_kpv)
                    AND kuu = month(l_kpv)
                    AND (rekvid IN (SELECT rekv_id
                                    FROM get_asutuse_struktuur(l_rekvid)
                  )
                      )
        )

    THEN

        FOR v_rekv IN
            SELECT id
            FROM ou.rekv
            WHERE parentid < 999
              AND id NOT IN (123, 116, 122)
              AND id IN (SELECT rekv_id
                         FROM get_asutuse_struktuur(l_rekvid))
            LOOP


                SELECT tp INTO l_asutuse_tp
                FROM ou.aa
                WHERE parentid = v_rekv.id
                  AND kassa = 2
                LIMIT 1;

                RAISE NOTICE 'rekvid -> %, l_kpv %, l_asutuse_tp %', v_rekv.id, l_kpv, l_asutuse_tp;


                INSERT INTO eelarve.saldoandmik (nimetus, db, kr, konto, tegev, tp, allikas, rahavoo, kpv, aasta, kuu,
                                                 rekvid, omatp,
                                                 tyyp)
                SELECT coalesce(l.nimetus, ''),
                       qry.deebet,
                       qry.kreedit,
                       qry.konto,
                       qry.tegev,
                       qry.tp,
                       qry.allikas,
                       qry.rahavoog,
                       l_kpv,
                       year(l_kpv),
                       month(l_kpv),
                       v_rekv.id,
                       l_asutuse_tp,
                       0
                FROM eelarve.saldoandmik_aruanne(l_kpv2, v_rekv.id, NULL) qry
                         LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(l.kood)) = ltrim(rtrim(qry.konto))
                WHERE qry.rekv_id = v_rekv.id;

                -- kassakulud
                l_params = row_to_json(row)
                           FROM (SELECT l_kpv     AS kpv,
                                        v_rekv.id AS rekvid) ROW;

                l_tulemus = (SELECT qry.result
                             FROM eelarve.sp_koosta_kassakulud(user_id, l_params :: JSON) AS qry);

            END LOOP;
    END IF;

    IF NOT empty(l_kond) AND l_rekvid = 63 -- only for Rahandusamet
    THEN
        RAISE NOTICE 'start arv kond';
        -- koostame kond saldoandmik
        PERFORM eelarve.koosta_kond_saldoandmik(user_id, l_kpv);
    END IF;

    result = 1;
    RETURN;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_message = SQLERRM;
            result = 0;
            RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION eelarve.sp_koosta_saldoandmik(INTEGER, JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.sp_koosta_saldoandmik(INTEGER, JSON) TO dbpeakasutaja;


/*
select error_code, result, error_message from eelarve.sp_koosta_saldoandmik(2477,'{"kpv":"2022-03-31","tyyp":1,"kond":1, "rekvid":63}'::json)

select * from pg_stat_activity
where usename in ('vlad','postgres')

*/