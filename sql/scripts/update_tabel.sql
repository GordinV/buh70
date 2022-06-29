DROP FUNCTION IF EXISTS lapsed.update_tabel();

CREATE FUNCTION lapsed.update_tabel()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_kaart      RECORD;
    l_too_paevad INTEGER = 0;
    l_kulastused INTEGER = 0;
    l_kovid      INTEGER = 0;
    json_props   JSONB   = '{}'::JSONB;
    l_kokku      INTEGER = 0;
BEGIN

    FOR v_kaart IN
        SELECT lk.nomid,
               lk.id,
               lk.parentid,
               lk.rekvid,
               n.uhik,
               lk.kuu   AS kuu,
               lk.aasta AS aasta,
               0        AS too_paevad,
               0        AS kulastused,
               0        AS kovid,
               lk.yksus
        FROM lapsed.cur_lapse_taabel lk
                 INNER JOIN libs.nomenklatuur n ON n.id = lk.nomid
        WHERE aasta = 2022
          AND n.uhik NOT IN ('PAEV', 'PÄEV')
    --         and kuu = 1
--        and parentid = 14804
        LOOP
            SELECT (visidid_kokku + puudumised_kokku), covid_kokku
            INTO l_too_paevad, l_kulastused
            FROM (
                     WITH day_taabel AS (
                         SELECT DISTINCT dt.id, dt1.osalemine, dt1.covid
                         FROM lapsed.day_taabel dt
                                  INNER JOIN lapsed.day_taabel1 dt1 ON dt.id = dt1.parent_id
                         WHERE month(dt.kpv) = v_kaart.kuu
                           AND year(dt.kpv) = v_kaart.aasta
                           AND dt.staatus < 3
                           AND rekv_id = v_kaart.rekvid
                           AND dt1.laps_id = v_kaart.parentid
                     )

                     SELECT count(*) FILTER (WHERE osalemine = 1)               AS visidid_kokku,
                            count(*) FILTER (WHERE osalemine = 0)               AS puudumised_kokku,
                            count(*) FILTER (WHERE osalemine = 0 AND covid = 1) AS covid_kokku
                     FROM day_taabel
                 ) qry;

            l_kovid = l_too_paevad - l_kulastused;

            -- расчет кол-во табелей в группе за месяц
            l_too_paevad = (SELECT count(dt.id)
                            FROM lapsed.day_taabel dt
                                     INNER JOIN libs.library l ON l.id = dt.grupp_id
                            WHERE month(dt.kpv) = v_kaart.kuu
                              AND year(dt.kpv) = v_kaart.aasta
                              AND dt.staatus < 3
                              AND rekv_id = v_kaart.rekvid
                              AND l.nimetus = v_kaart.yksus
            );


            json_props = to_jsonb(row)
                         FROM (SELECT l_kulastused AS kulastused,
                                      l_kovid      AS kovid,
                                      l_too_paevad AS too_paevad) row;


            UPDATE lapsed.lapse_taabel
            SET properties = coalesce(properties, '{}') :: JSONB || json_props
            WHERE id = v_kaart.id;

            l_kokku = l_kokku + 1;
        END LOOP;
    RETURN l_kokku;
END;
$$;

SELECT lapsed.update_tabel();

DROP FUNCTION IF EXISTS lapsed.update_tabel();

