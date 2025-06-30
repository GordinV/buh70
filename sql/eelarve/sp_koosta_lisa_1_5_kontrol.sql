DROP FUNCTION IF EXISTS eelarve.koosta_lisa_1_5_kontrol(INTEGER, DATE, INTEGER);
DROP FUNCTION IF EXISTS eelarve.koosta_lisa_1_5_kontrol(INTEGER, DATE);
DROP PROCEDURE IF EXISTS eelarve.koosta_lisa_1_5_kontrol(INTEGER, DATE);

CREATE OR REPLACE PROCEDURE eelarve.koosta_lisa_1_5_kontrol( user_id INTEGER,
                                                            l_kpv DATE,
                                                            rekv_id INTEGER)
    LANGUAGE plpgsql
 as
$$

DECLARE
    v_rekv RECORD;
BEGIN

/*    -- check for user_id
    IF NOT (
               SELECT
                   (roles ->> 'is_peakasutaja') :: BOOLEAN
               FROM
                   ou.userid
               WHERE
                   id = user_id
           )
    THEN
        result = 0;
        error_code = 5;
        error_message = 'Kasutaja ei leitud,  userId:' ||
                        coalesce(user_id, 0) :: TEXT;

        --        RAISE EXCEPTION 'eelarve.koosta_kond_saldoandmik, error_message %', error_message;
--        RETURN;
    END IF;

*/
-- считаем только учреждение где были изменения и его вышестоящее + фин. департамент
    FOR v_rekv IN
-- нижестоящие учреждения
        WITH
            params AS (
                          SELECT
                              l_kpv::DATE      AS kpv,
                              rekv_id::INTEGER AS rekv_id
                      ),
            rekv_ids AS (
                          SELECT
                              id
                          FROM
                              (
/*                          SELECT DISTINCT d.rekvid AS id
                          FROM docs.doc d
                                   INNER JOIN docs.journal j ON j.parentid = d.id
                                   INNER JOIN ou.rekv r ON r.id = d.rekvid,
                               params p
                          WHERE j.kpv >= make_date(year(p.kpv), month(p.kpv), 01)
                            AND j.kpv <= p.kpv
                            AND r.id NOT IN (SELECT id FROM ou.rekv WHERE parentid IN (63, 0))
*/
                                  select
                                      id
                                  from
                                      ou.rekv
                                  where
                                        parentid < 999999
                                    and id NOT IN (
                                                      SELECT
                                                          id
                                                      FROM
                                                          ou.rekv
                                                      WHERE
                                                          parentid IN (63, 0)
                                                  )
                              )      qry,
                              params p
--                          WHERE
--                              (p.rekv_id IS NULL OR qry.id = p.rekv_id)
--                 and qry.id = 66
                      )
        SELECT
            id
        FROM
            rekv_ids
        UNION ALL
-- департаменты
        SELECT
            id
        FROM
            ou.    rekv,
            params p
        WHERE
            parentid = 63
/*          AND id IN (
            SELECT r.parentid
            FROM rekv_ids
                     INNER JOIN ou.rekv r ON r.id = rekv_ids.id
        )
*/
        UNION ALL
-- город , независимые
        SELECT
            id
        FROM
            ou.    rekv,
            params p
        WHERE
             parentid = 0
          OR id = CASE WHEN p.rekv_id = 63 THEN 63 ELSE 9999 END

        LOOP
            RAISE NOTICE 'start uuedatud + v_rekv.id %', v_rekv.id;
            -- удаляем прежнюю версию
            DELETE
            FROM
                eelarve.lisa_1_5_kontrol l
            WHERE
                  kpv = l_kpv
              AND l.rekv_id = v_rekv.id;

            CREATE temporary TABLE IF NOT EXISTS tmp_andmik
            (
                idx                TEXT,
                tyyp               INTEGER,
                rekvid             INTEGER,
                tegev              VARCHAR(20),
                allikas            VARCHAR(20),
                artikkel           VARCHAR(20),
                rahavoog           VARCHAR(20),
                nimetus            VARCHAR(254),
                eelarve            NUMERIC(14, 2),
                eelarve_taps       NUMERIC(14, 2),
                eelarve_kassa      NUMERIC(14, 2),
                eelarve_kassa_taps NUMERIC(14, 2),
                tegelik            NUMERIC(14, 2),
                kassa              NUMERIC(14, 2),
                saldoandmik        NUMERIC(14, 2),
                db                 NUMERIC(14, 2),
                kr                 NUMERIC(14, 2),
                aasta              INTEGER,
                kuu                INTEGER,
                is_kulud           INTEGER DEFAULT 0,
                rekv_id            INTEGER NULL
            ) on commit drop;

            call eelarve.salvesta_lisa_1_5_kontrol(user_id, l_kpv, v_rekv.id::INTEGER);
            COMMIT;
            RAISE NOTICE 'finish, uuedatud + v_rekv.id %', v_rekv.id;

        END LOOP;
    END;
$$;

GRANT EXECUTE ON PROCEDURE eelarve.koosta_lisa_1_5_kontrol(INTEGER, DATE, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON PROCEDURE eelarve.koosta_lisa_1_5_kontrol(INTEGER, DATE, INTEGER) TO dbvaatleja;
GRANT EXECUTE ON PROCEDURE eelarve.koosta_lisa_1_5_kontrol(INTEGER, DATE, INTEGER) TO dbkasutaja;


/*

call eelarve.koosta_lisa_1_5_kontrol(2477, '2024-12-31'::DATE, 63)

*/

--select * from ou.userid where rekvid = 63 and kasutaja = 'vlad'