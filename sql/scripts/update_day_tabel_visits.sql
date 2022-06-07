DROP TABLE IF EXISTS tmp_dt;
CREATE TABLE IF NOT EXISTS tmp_dt (
    asutus TEXT,
    aasta  TEXT,
    kuu    TEXT,
    yksus  TEXT,
    ik     TEXT,
    kogus  TEXT
);

INSERT INTO tmp_dt(asutus, aasta, kuu, yksus, ik, kogus)
SELECT t.f[1]::TEXT AS asutus
        ,
       t.f[2]::TEXT AS aasta
        ,
       t.f[3]::TEXT AS kuu
        ,
       t.f[4]::TEXT AS yksus
        ,
       t.f[5]::TEXT AS ik
        ,
       t.f[6]::TEXT AS kogus
FROM (
         SELECT regexp_split_to_array(l, ';') AS f
         FROM regexp_split_to_table(
                      $$Учреждение;Год;Месяц;Код группы;IK ребенка;Дополнит. не посещал дней
0911012;2022;1;LAED-001-01;62004240124;3
0911012;2022;1;LAED-001-01;61908290018;3
0911012;2022;1;LAED-001-01;51908150038;2
0911012;2022;1;LAED-001-01;51909260110;1
0911012;2022;1;LAED-001-01;51906110109;4
0911012;2022;1;LAED-001-01;51911110252;2
0911012;2022;1;LAED-001-02;61909030144;3
0911012;2022;1;LAED-001-02;51901280128;2
0911012;2022;1;LAED-001-02;61810210077;1
0911012;2022;1;LAED-001-02;61806210026;1
0911012;2022;1;LAED-001-02;51902230115;1
0911012;2022;1;LAED-001-02;51909150098;3
0911012;2022;1;LAED-001-02;52001300032;2
0911012;2022;1;LAED-001-02;51804250141;1
0911012;2022;1;LAED-002-03;51710240115;2
0911012;2022;1;LAED-002-03;61710040050;2
0911012;2022;1;LAED-002-03;51801210011;2
0911012;2022;1;LAED-002-03;51602080145;5
0911012;2022;1;LAED-002-03;61805160104;1
0911012;2022;1;LAED-002-03;51603250130;1
0911012;2022;1;LAED-002-03;61703080045;3
0911012;2022;1;LAED-002-03;51708240064;3
0911012;2022;1;LAED-002-03;61801220150;1
0911012;2022;1;LAED-002-03;61705160101;4
0911012;2022;1;LAED-002-03;61706230059;2
0911012;2022;1;LAED-002-03;61705100114;1
0911012;2022;1;LAED-002-03;61704110160;2
0911012;2022;1;LAED-002-03;61609180056;1
0911012;2022;1;LAED-002-04;61412020157;1
0911012;2022;1;LAED-002-04;51412180171;5
0911012;2022;1;LAED-002-04;61606240117;2
0911012;2022;1;LAED-002-04;51503280040;1
0911012;2022;1;LAED-002-04;51510260178;2
0911012;2022;1;LAED-002-04;51509090249;2
0911012;2022;1;LAED-002-04;51509030153;2
0911012;2022;1;LAED-002-04;51608290052;1
0911012;2022;1;LAED-002-04;51602270150;2
0911012;2022;1;LAED-002-04;61606110101;6
0911012;2022;1;LAED-002-04;51506200133;3
0911012;2022;1;LAED-002-04;61411170149;1
0911012;2022;1;LAED-002-04;51512080200;1
0911012;2022;2;LAED-001-01;62004240124;1
0911012;2022;2;LAED-001-01;61908290018;1
0911012;2022;2;LAED-001-01;51908150038;2
0911012;2022;2;LAED-001-01;51906110099;3
0911012;2022;2;LAED-001-01;51906110109;3
0911012;2022;2;LAED-001-01;51911110252;1
0911012;2022;2;LAED-001-02;61909030144;2
0911012;2022;2;LAED-001-02;51901280128;3
0911012;2022;2;LAED-001-02;61805130116;3
0911012;2022;2;LAED-001-02;61901310102;1
0911012;2022;2;LAED-001-02;61807310157;2
0911012;2022;2;LAED-001-02;61810210077;1
0911012;2022;2;LAED-001-02;61806210026;4
0911012;2022;2;LAED-001-02;51902230115;1
0911012;2022;2;LAED-001-02;51909150098;2
0911012;2022;2;LAED-001-02;52001300032;4
0911012;2022;2;LAED-001-02;51804250141;1
0911012;2022;2;LAED-002-03;51710240115;2
0911012;2022;2;LAED-002-03;61710040050;4
0911012;2022;2;LAED-002-03;51801210011;1
0911012;2022;2;LAED-002-03;51602080145;5
0911012;2022;2;LAED-002-03;61805160104;1
0911012;2022;2;LAED-002-03;51603250130;3
0911012;2022;2;LAED-002-03;61703080045;2
0911012;2022;2;LAED-002-03;51708240064;3
0911012;2022;2;LAED-002-03;61801220150;1
0911012;2022;2;LAED-002-03;61705160101;4
0911012;2022;2;LAED-002-03;61706230059;1
0911012;2022;2;LAED-002-03;61705100114;1
0911012;2022;2;LAED-002-03;51805030077;3
0911012;2022;2;LAED-002-03;51704120100;4
0911012;2022;2;LAED-002-03;51805100138;1
0911012;2022;2;LAED-002-03;61804050174;2
0911012;2022;2;LAED-002-03;61609180056;3
0911012;2022;2;LAED-002-04;51412180171;3
0911012;2022;2;LAED-002-04;61606240117;1
0911012;2022;2;LAED-002-04;51503280040;1
0911012;2022;2;LAED-002-04;51608290052;1
0911012;2022;2;LAED-002-04;51602270150;1
0911012;2022;2;LAED-002-04;61606110101;3
0911012;2022;2;LAED-002-04;51506200133;2
0911012;2022;2;LAED-002-04;61411170149;2
0911012;2022;3;LAED-001-01;62004240124;2
0911012;2022;3;LAED-001-01;51906110099;7
0911012;2022;3;LAED-001-01;51906110109;7
0911012;2022;3;LAED-001-01;51911110252;2
0911012;2022;3;LAED-001-02;61909030144;2
0911012;2022;3;LAED-001-02;61807310157;1
0911012;2022;3;LAED-001-02;61810210077;1
0911012;2022;3;LAED-001-02;61806210026;3
0911012;2022;3;LAED-001-02;52001300032;3
0911012;2022;3;LAED-001-02;51804250141;1
0911012;2022;3;LAED-002-03;51710240115;3
0911012;2022;3;LAED-002-03;51801210011;2
0911012;2022;3;LAED-002-03;51602080145;4
0911012;2022;3;LAED-002-03;51603250130;1
0911012;2022;3;LAED-002-03;61703080045;4
0911012;2022;3;LAED-002-03;51708240064;1
0911012;2022;3;LAED-002-03;61801220150;1
0911012;2022;3;LAED-002-03;61705160101;6
0911012;2022;3;LAED-002-03;61706230059;5
0911012;2022;3;LAED-002-03;61705100114;1
0911012;2022;3;LAED-002-03;51704120100;3
0911012;2022;3;LAED-002-03;61705070037;1
0911012;2022;3;LAED-002-03;61804050174;2
0911012;2022;3;LAED-002-03;61609180056;1
0911012;2022;3;LAED-002-04;61412020157;1
0911012;2022;3;LAED-002-04;51412180171;5
0911012;2022;3;LAED-002-04;61603130177;2
0911012;2022;3;LAED-002-04;61606240117;3
0911012;2022;3;LAED-002-04;51503280040;2
0911012;2022;3;LAED-002-04;51510260178;1
0911012;2022;3;LAED-002-04;51412110057;2
0911012;2022;3;LAED-002-04;51608290052;2
0911012;2022;3;LAED-002-04;51602270150;3
0911012;2022;3;LAED-002-04;51605130055;2
0911012;2022;3;LAED-002-04;51505250039;2
0911012;2022;3;LAED-002-04;61606110101;2
0911012;2022;3;LAED-002-04;51506200133;1
0911012;2022;3;LAED-002-04;61411170149;3
0911012;2022;3;LAED-002-04;51512080200;3$$, '\n') AS l) t;


DROP FUNCTION IF EXISTS lapsed.update_day_tabel_visits();

CREATE FUNCTION lapsed.update_day_tabel_visits()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_dt       RECORD;
    v_tabel    RECORD;
    v_tabel1   RECORD;
    l_count    INTEGER = 0;
    l_rekv_id  INTEGER;
    l_yksus_id INTEGER;
    l_kogus    INTEGER;
    l_dt_id    INTEGER;
    l_kokku    INTEGER = 0;
    l_vn       TEXT;
    l_ik       TEXT;
    l_laps_id  INTEGER;
BEGIN
    -- Эти VN необходимо присвоить только имеющим слуги детям в своих учреждениях.
-- Если ребенка в указанном учрежд. нет, то такого надо игнорировать и не сохранять его нигде в базе не создавая мусора.
-- Если ребенок есть (имеет услуги), то присваиваем ему старый ВН
-- Если ребенок есть (имеет услуги) и имеет какой-то, ранее присвоенный ВН, то просто добавляем ему еще один ВН

    FOR v_dt IN
        SELECT regexp_replace(asutus, E'(^[\\n\\r]+)|([\\n\\r]+$)', '', 'g') AS asutus,
               ik,
               regexp_replace(kogus, E'(^[\\n\\r]+)|([\\n\\r]+$)', '', 'g')  AS kogus,
               aasta,
               kuu,
               yksus
        FROM tmp_dt
        WHERE regexp_match(kogus, '[0-9]') IS NOT NULL
        and ik not in ('61901310102')
        LOOP
            RAISE NOTICE ' rekv %', left(v_dt.asutus, 7);
            l_rekv_id = (SELECT id FROM ou.rekv WHERE nimetus LIKE trim(v_dt.asutus) || '%' LIMIT 1);

            IF l_rekv_id IS NULL
            THEN
                RAISE NOTICE 'Puudub l_rekv_id %', v_dt;
            END IF;
            RAISE NOTICE 'kontrollin  teenused l_rekv_id %,  %', l_rekv_id, v_dt;

            l_laps_id = (SELECT id
                         FROM lapsed.laps
                         WHERE trim(isikukood) = trim(v_dt.ik) AND staatus <> 3
                         ORDER BY id DESC
                         LIMIT 1);

            l_yksus_id = (SELECT id
                          FROM libs.library l
                          WHERE l.rekvid = l_rekv_id
                            AND l.kood = trim(v_dt.yksus)
                            AND l.status <> 3
                            AND l.library = 'LAPSE_GRUPP'
                          LIMIT 1);

            IF (l_rekv_id IS NULL OR l_laps_id IS NULL OR l_yksus_id IS NULL)
            THEN
                RAISE EXCEPTION 'Puudub vajaliku andmed l_rekv_id %, l_laps_id %, v_dt.ik %, l_yksus_id %', l_rekv_id, l_laps_id,v_dt.ik, l_yksus_id;
            END IF;

            -- дневных табелей в части изменения количества посещений?  завтраки/обеды/полдники не изменять

            -- вернем прежние значения
            FOR v_tabel1 IN
                SELECT dt1.*
                FROM lapsed.day_taabel1 dt1
                         INNER JOIN lapsed.day_taabel dt ON dt.id = dt1.parent_id
                WHERE rekv_id = l_rekv_id
                  AND dt.grupp_id = l_yksus_id
                  AND year(kpv) = v_dt.aasta::INTEGER
                  AND month(kpv) = v_dt.kuu::INTEGER
                  AND dt1.laps_id = l_laps_id
                  AND dt1.muud IS NOT NULL
                LOOP
                    -- запоминаем прежнее значение
                    IF v_tabel1.muud IS NOT NULL
                    THEN
                        UPDATE lapsed.day_taabel1 SET osalemine = muud::INTEGER WHERE id = v_tabel1.id;
                    END IF;
                END LOOP;

            l_kogus = v_dt.kogus::INTEGER;


            IF l_kogus > 0
            THEN
                -- ищем табель и посещения
                FOR v_tabel1 IN
                    SELECT MAX(dt1.osalemine) AS osalemine, dt1.parent_id
                    FROM lapsed.day_taabel1 dt1
                             INNER JOIN lapsed.day_taabel dt ON dt.id = dt1.parent_id
                    WHERE rekv_id = l_rekv_id
                      AND dt.grupp_id = l_yksus_id
                      AND year(kpv) = v_dt.aasta::INTEGER
                      AND month(kpv) = v_dt.kuu::INTEGER
                      AND dt1.laps_id = l_laps_id
                      AND osalemine > 0
                    GROUP BY dt1.parent_id
                    LOOP
                        -- запоминаем прежнее значение
                        UPDATE lapsed.day_taabel1
                        SET muud = osalemine::TEXT
                        WHERE parent_id = v_tabel1.parent_id
                          AND laps_id = l_laps_id
                          AND osalemine = 1
                          AND muud IS NULL;

                        -- уменьшаем посещение
                        IF l_kogus > 0
                        THEN
                            UPDATE lapsed.day_taabel1
                            SET osalemine = 0
                            WHERE parent_id = v_tabel1.parent_id
                              AND laps_id = l_laps_id
                              AND osalemine = 1;
                            l_kogus = l_kogus - 1;
                        END IF;
                        IF (empty(l_kogus))
                        THEN
                            EXIT;
                        END IF;

                    END LOOP;
            END IF;


        END LOOP;
    RETURN l_count;

END;
$$;

SELECT lapsed.update_day_tabel_visits();

DROP FUNCTION IF EXISTS lapsed.update_day_tabel_visits();
--DROP TABLE IF EXISTS tmp_viitenr;
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
