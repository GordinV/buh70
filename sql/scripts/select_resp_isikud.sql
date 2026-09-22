/*
drop table if exists tmp_viitenr;
create table if not EXISTS tmp_viitenr (ik text);

insert into  tmp_viitenr(ik)
SELECT
    t.f[1]::text AS ik
FROM (
         SELECT regexp_split_to_array(l, ';') AS f
         FROM regexp_split_to_table(
                      $$38211233711
45502033737
45812253721
46103122288
46106303744
46206233729
46409223721
46609073741
46702243742
46709123724
46710033728
46806247012
47007223734
47010053745
47012172745
47201243724
47203230045
47204033720
47306120305
47307300058
47404272714
47504032218
47605193719
47606043727
47708193726
47709083740
47802263717
47907212212
48105252219
48106293717
48108173729
48204233712
48302272246
48407312216
48908313723
49603113712$$, '\n') AS l) t;
*/
DROP FUNCTION IF EXISTS lapsed.check_vn();

CREATE FUNCTION lapsed.check_vn()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_vn      RECORD;
    l_count   INTEGER = 0;
    l_rekv_id INTEGER;
    l_kokku   INTEGER = 0;
    l_vn      TEXT;
    l_ik      TEXT;
    l_laps_id INTEGER;
BEGIN
    -- Эти VN необходимо присвоить только имеющим слуги детям в своих учреждениях.
-- Если ребенка в указанном учрежд. нет, то такого надо игнорировать и не сохранять его нигде в базе не создавая мусора.
-- Если ребенок есть (имеет услуги), то присваиваем ему старый ВН
-- Если ребенок есть (имеет услуги) и имеет какой-то, ранее присвоенный ВН, то просто добавляем ему еще один ВН

    FOR v_vn IN
        SELECT regexp_replace(vn, E'(^[\\n\\r]+)|([\\n\\r]+$)', '', 'g') AS vn,
               regexp_replace(ik, E'(^[\\n\\r]+)|([\\n\\r]+$)', '', 'g') as ik,
               asutus
        FROM tmp_viitenr
        WHERE vn IS NOT NULL
        LOOP
            raise notice ' rekv %', left(v_vn.asutus, 10);
            l_rekv_id = (SELECT id FROM ou.rekv WHERE left(nimetus, 10) = left(v_vn.asutus, 10) LIMIT 1);

            IF l_rekv_id IS NULL
            THEN
                RAISE notice 'Puudub l_rekv_id %', v_vn;
            END IF;
            RAISE NOTICE 'kontrollin  teenused l_rekv_id %,  %', l_rekv_id, v_vn;

            l_laps_id = (SELECT id FROM lapsed.laps WHERE isikukood = v_vn.ik ORDER BY id DESC LIMIT 1);

-- Если ребенка в указанном учрежд. нет, то такого надо игнорировать и не сохранять его нигде в базе не создавая мусора.

            IF l_rekv_id is not null and exists(SELECT id
                                                FROM lapsed.lapse_kaart
                                                WHERE parentid = l_laps_id
                                                  AND rekvid = l_rekv_id
                                                  AND staatus < 3)

                -- есть, работаем
            THEN
                -- Если ребенок есть (имеет услуги), то присваиваем ему старый ВН
                -- Если ребенок есть (имеет услуги) и имеет какой-то, ранее присвоенный ВН, то просто добавляем ему еще один ВН

                IF NOT exists(SELECT id
                              FROM lapsed.viitenr
                              WHERE ltrim(rtrim(isikukood)) = ltrim(rtrim(v_vn.ik))
                                AND rekv_id = l_rekv_id
                                AND ltrim(rtrim(viitenumber)) = ltrim(rtrim(v_vn.vn)))
                THEN
                    INSERT INTO lapsed.viitenr (isikukood, rekv_id, viitenumber)
                    VALUES (v_vn.ik, l_rekv_id, v_vn.vn);

                    l_count = l_count + 1;
                    RAISE NOTICE 'vn lisatud %', v_vn;
                ELSE
                    RAISE NOTICE 'vn juba exists %', v_vn;
                END IF;
            ELSE
                RAISE NOTICE 'Teenused puuduvad %', v_vn;
            END IF;

        END LOOP;
    RETURN l_count;

END;
$$;

SELECT lapsed.check_vn();

DROP FUNCTION IF EXISTS lapsed.check_vn();
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
