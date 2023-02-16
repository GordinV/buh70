DROP TABLE IF EXISTS tmp_esindajad;
CREATE TABLE IF NOT EXISTS tmp_esindajad (
    yksus   TEXT,
    isik_ik TEXT,
    arv_ik  TEXT
);

INSERT INTO tmp_esindajad(yksus, isik_ik, arv_ik)
SELECT t.f[1]::TEXT AS yksus
        ,
       t.f[2]::TEXT AS isik_ik
        ,
       t.f[3]::TEXT AS arv_ik
FROM (
         SELECT regexp_split_to_array(l, ';') AS f
         FROM regexp_split_to_table(
                      $$0951005;60901133714;48302143717$$, '\n') AS l) t;

DROP FUNCTION IF EXISTS lapsed.check_arv_isikud();

CREATE FUNCTION lapsed.check_arv_isikud()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_vn            RECORD;
    l_count         INTEGER = 0;
    l_rekv_id       INTEGER;
    l_laps_id       INTEGER;
    l_asutus_id     INTEGER;
    l_vanem_id      INTEGER;
    v_vanem         RECORD;
    l_arv_count     INTEGER = 0;
    l_esindus_count INTEGER = 0;
    l_docs_count    INTEGER;
    l_not_exists_vn TEXT    = '';
    l_updates       BOOLEAN = FALSE;
    l_saved         INTEGER = 0;
    l_params        JSONB;
    l_user_id       INTEGER;
BEGIN
    -- Эти VN необходимо присвоить только имеющим слуги детям в своих учреждениях.
-- Если ребенка в указанном учрежд. нет, то такого надо игнорировать и не сохранять его нигде в базе не создавая мусора.
-- Если ребенок есть (имеет услуги), то присваиваем ему старый ВН
-- Если ребенок есть (имеет услуги) и имеет какой-то, ранее присвоенный ВН, то просто добавляем ему еще один ВН

    FOR v_vn IN
        SELECT regexp_replace(yksus, E'(^[\\n\\r]+)|([\\n\\r]+$)', '', 'g')   AS yksus,
               regexp_replace(isik_ik, E'(^[\\n\\r]+)|([\\n\\r]+$)', '', 'g') AS isik_ik,
               regexp_replace(arv_ik, E'(^[\\n\\r]+)|([\\n\\r]+$)', '', 'g')  AS arv_ik
        FROM tmp_esindajad
        WHERE isik_ik IS NOT NULL
--          AND isik_ik = '60803173733'
        LOOP
            l_updates = FALSE;
            RAISE NOTICE 'v_vn.yksus %, isik_ik %, arv_ik %',v_vn.yksus, v_vn.isik_ik, v_vn.arv_ik;

            l_laps_id = (SELECT id
                         FROM lapsed.laps l
                         WHERE l.isikukood = v_vn.isik_ik
                           AND l.staatus <> 3
                         LIMIT 1);

            -- ищем учреждение
            l_rekv_id = (SELECT id
                         FROM ou.rekv
                         WHERE nimetus LIKE '%' + ltrim(rtrim(v_vn.yksus)) + '%'
                         LIMIT 1);


            l_asutus_id = (
                SELECT a.id
                FROM libs.asutus a
                         INNER JOIN lapsed.vanemad v ON v.asutusid = a.id AND v.staatus <> 3
                         INNER JOIN lapsed.laps l ON l.id = v.parentid
                         INNER JOIN lapsed.vanem_arveldus va ON va.asutusid = a.id AND va.parentid = l.id AND arveldus
                WHERE a.regkood = v_vn.arv_ik
                  AND l.id = l_laps_id
                  AND va.rekvid = l_rekv_id
                ORDER BY v.id DESC
                LIMIT 1
            );

            IF l_asutus_id IS NULL
            THEN
                -- ищем котр-агента, если он не ответственный
                l_asutus_id = (
                    SELECT a.id
                    FROM libs.asutus a
                             LEFT OUTER JOIN lapsed.vanemad v ON v.asutusid = a.id AND v.staatus <> 3
                    WHERE a.regkood = v_vn.arv_ik
                      AND v.parentid = l_laps_id
                    ORDER BY v.id DESC
                    LIMIT 1
                );
            END IF;

            -- 1. laps
            -- 2. rekvid
            -- 3 esindajad


            SELECT a.id, v.id
            INTO l_asutus_id, l_vanem_id
            FROM libs.asutus a
                     INNER JOIN lapsed.vanemad v ON a.id = v.asutusid
            WHERE v.parentid = l_laps_id
              AND v.asutusid IN (SELECT id FROM libs.asutus WHERE asutus.regkood = v_vn.arv_ik)
              AND v.staatus < 3
            LIMIT 1;

            SELECT v.id,
                   v.parentid,
                   v.asutusid,
                   coalesce((va.arveldus)::BOOLEAN, FALSE)::BOOLEAN                     AS arved,
                   v.properties ->> 'suhtumine'                                         AS suhtumine,
                   coalesce((v.properties ->> 'kas_paberil')::BOOLEAN, FALSE)::BOOLEAN  AS kas_paberil,
                   coalesce((va.properties ->> 'kas_earve')::BOOLEAN, FALSE)::BOOLEAN   AS kas_earve,
                   (va.properties ->> 'pank')::TEXT                                     AS pank,
                   (va.properties ->> 'iban')::TEXT                                     AS iban,
                   coalesce((v.properties ->> 'kas_email')::BOOLEAN, FALSE)::BOOLEAN    AS kas_email,
                   coalesce((v.properties ->> 'kas_esindaja')::BOOLEAN, FALSE)::BOOLEAN AS kas_esindaja,
                   v.muud,
                   a.nimetus::TEXT                                                      AS vanem_nimi,
                   a.regkood::TEXT                                                      AS vanem_isikukood,
                   a.nimetus::TEXT                                                      AS nimi,
                   a.regkood::TEXT                                                      AS isikukood,
                   a.aadress::TEXT,
                   a.email::TEXT,
                   a.tel::TEXT
            INTO v_vanem
            FROM lapsed.vanemad v
                     INNER JOIN libs.asutus a ON a.id = v.asutusId
                     LEFT OUTER JOIN lapsed.vanem_arveldus va ON v.parentid = va.parentid
                AND va.asutusid = a.id
                AND va.rekvid = l_rekv_id
            WHERE v.id = l_vanem_id;

            l_user_id = (SELECT id FROM ou.userid WHERE rekvid = l_rekv_id AND kasutaja = 'vlad' LIMIT 1);

            IF (l_laps_id IS NULL OR l_asutus_id IS NULL OR l_vanem_id IS NULL OR l_rekv_id IS NULL)
            THEN
                RAISE EXCEPTION 'nulls found v_vn.isik_ik %, l_laps_id %, l_asutus_id %, l_vanem_id %, l_rekv_id %',v_vn.isik_ik, l_laps_id, l_asutus_id, l_vanem_id, l_rekv_id;
            END IF;

            RAISE NOTICE 'v_vanem.arved %, v_vn.isik_ik %, l_laps_id %, l_asutus_id %, l_vanem_id %, l_rekv_id %',v_vanem.arved, v_vn.isik_ik, l_laps_id, l_asutus_id, l_vanem_id, l_rekv_id;

            v_vanem.arved = false;
            IF NOT coalesce(v_vanem.arved, FALSE)
            THEN

                v_vanem.arved = TRUE;
                v_vanem.kas_paberil = TRUE;
                v_vanem.kas_email = FALSE;
                v_vanem.kas_earve = FALSE;
--                v_vanem.kas_esindaja = TRUE;

                l_updates = TRUE;

                -- arved
                SELECT count(id)
                INTO l_docs_count
                FROM (
                         SELECT a.id
                         FROM lapsed.cur_laste_arved a
                         WHERE a.asutusid = v_vanem.asutusid
                           AND a.rekvid = l_rekv_id
                           AND a.kpv >= '2022-12-31'
                         UNION ALL
                         SELECT id
                         FROM lapsed.cur_lapsed_mk m
                         WHERE m.maksja_id = v_vanem.asutusid
                           AND m.rekvid = l_rekv_id
                           AND m.kpv >= '2022-12-31') docs;

                UPDATE docs.journal
                SET asutusid = l_asutus_id
                WHERE rekvid = l_rekv_id
                  AND kpv >= '2022-12-31'
                  AND parentid IN (
                    SELECT a.journalid
                    FROM lapsed.cur_laste_arved a
                    WHERE a.rekvid = l_rekv_id
                      AND a.laps_id = l_laps_id
                      AND a.kpv >= '2022-12-31'
                );

                UPDATE docs.arv
                SET asutusid = l_asutus_id
                WHERE rekvid = l_rekv_id
                  AND kpv >= '2022-12-31'
                  AND parentid IN (
                    SELECT a.id
                    FROM lapsed.cur_laste_arved a
                    WHERE a.rekvid = l_rekv_id
                      AND a.laps_id = l_laps_id
                      AND a.kpv >= '2022-12-31'
                );

                UPDATE docs.journal
                SET asutusid = l_asutus_id
                WHERE rekvid = l_rekv_id
                  AND kpv >= '2022-12-31'
                  AND parentid IN (
                    SELECT a.journalid
                    FROM lapsed.cur_lapsed_mk a
                    WHERE a.rekvid = l_rekv_id
                      AND a.laps_id = l_laps_id
                      AND a.kpv >= '2022-12-31'
                );


                RAISE NOTICE 'vale isik coalesce(v_vanem.arved, FALSE) % %, l_docs_count %',coalesce(v_vanem.arved, FALSE), v_vn.arv_ik, l_docs_count;

                SELECT row_to_json(row)
                INTO l_params
                FROM (SELECT 0                            AS id,
                             (SELECT to_jsonb(v_vanem.*)) AS data) row;


                l_saved = lapsed.sp_salvesta_vanem(l_params,
                                                   l_user_id,
                                                   l_rekv_id);
                RAISE NOTICE 'saved %', l_saved;

                l_arv_count = l_arv_count + 1;
            END IF;

            l_count = l_count + 1;
        END LOOP;
    RAISE NOTICE 'l_arv_count %',l_arv_count;
    RETURN l_count;

END;
$$;

SELECT lapsed.check_arv_isikud();

DROP FUNCTION IF EXISTS lapsed.check_arv_isikud();

--DROP TABLE IF EXISTS tmp_esindajad;
/*
 select trim(replace(vn,E'\n',''),'"'), vn, ik, asutus from tmp_viitenr_kustuta

SELECT id FROM ou.rekv WHERE left(nimetus, 10) = left(trim('"0911027 Narva Lasteaed Pongerjas T"','"'), 10) LIMIT 1

          FROM lapsed.viitenr
            WHERE isikukood = v_vn.ik
              AND rekv_id = l_rekv_id
              AND viitenumber = trim(replace(v_vn.vn,E'\n',''),'"');

select * from tmp_viitenr_kustuta
 where vn = '9366554'

 */


