DROP TABLE IF EXISTS tmp_viitenr_kustuta;
DROP TABLE IF EXISTS tmp_viitenr;

CREATE TABLE IF NOT EXISTS tmp_viitenr (
    asutus TEXT,
    ik     TEXT,
    yksus  TEXT,
    vn     TEXT
);

INSERT INTO tmp_viitenr (asutus, ik, yksus, vn)
SELECT t.f[1]::TEXT AS asutus
        ,
       t.f[2]::TEXT AS ik
        ,
       t.f[3]::TEXT AS yksus
        ,
       t.f[4]::TEXT AS vn
FROM (
         SELECT regexp_split_to_array(l, ',') AS f
         FROM regexp_split_to_table(
                      $$
    0951005,50401093718,HUVI-062-04,8969185
    0951005,50401093718,HUVI-084-01,8994969
    0951005,50401093718,HUVI-085-03,8988593
    0951005,50401093718,HUVI-086-01,8996129
    0951005,51103270140,HUVI-045-02,8974743
    0951005,51103270140,HUVI-046-02,8998622
    0951005,51103270140,HUVI-078-02,8999278
    0951005,51103270140,HUVI-095-01,8984131
    0951005,61205133732,HUVI-030-01,8996611
    0951005,61205133732,HUVI-031-02,8946179
    0951005,61205133732,HUVI-042-03,8972389
    0951005,61205133732,HUVI-077-01,8902126
    $$, '\n') AS l) t;

DROP FUNCTION IF EXISTS lapsed.update_multiple_vn();

CREATE FUNCTION lapsed.update_multiple_vn()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_vn      RECORD;
    v_vk      RECORD;
    l_rekv_id INTEGER;
    l_kokku   INTEGER = 0;
    l_vn      TEXT;
    l_ik      TEXT;
BEGIN
    FOR v_vn IN
        SELECT DISTINCT asutus, ik
        FROM tmp_viitenr
        WHERE ik IS NOT NULL
        LOOP
            l_rekv_id = (SELECT id FROM ou.rekv WHERE left(nimetus, 7) = left(ltrim(rtrim(v_vn.asutus)), 7) LIMIT 1);
            l_ik = v_vn.ik;

            -- убираем "старые" вн
            FOR v_vk IN SELECT lk.properties ->> 'yksus'   AS yksus,
                               lk.properties ->> 'viitenr' AS viitenr,
                               lk.id
                        FROM lapsed.lapse_kaart lk
                        WHERE staatus <> 3
                          AND rekvid = l_rekv_id
                          AND parentid IN (SELECT id FROM lapsed.laps WHERE isikukood = v_vn.ik AND laps.staatus <> 3)
                LOOP
                    UPDATE lapsed.lapse_kaart
                    SET properties = properties || ('{"viitenr":null}')::JSONB
                    WHERE id = v_vk.id;

                END LOOP;
        END LOOP;

    FOR v_vn IN
        SELECT *
        FROM tmp_viitenr
        WHERE vn IS NOT NULL
        LOOP
            l_rekv_id = (SELECT id FROM ou.rekv WHERE left(nimetus, 7) = left(ltrim(rtrim(v_vn.asutus)), 7) LIMIT 1);
            l_vn = left(replace(v_vn.vn, E'\n\r', ''), 7);
            l_ik = v_vn.ik;

            FOR v_vk IN SELECT lk.properties ->> 'yksus'   AS yksus,
                               lk.properties ->> 'viitenr' AS viitenr,
                               lk.id
                        FROM lapsed.lapse_kaart lk
                        WHERE staatus <> 3
                          AND rekvid = l_rekv_id
                          AND parentid IN (SELECT id FROM lapsed.laps WHERE isikukood = v_vn.ik AND laps.staatus <> 3)
                          AND coalesce(lk.properties ->> 'yksus', '') = v_vn.yksus
                LOOP
                    IF (coalesce(v_vk.viitenr, '') <> v_vn.vn)
                    THEN

                        IF NOT exists(SELECT id
                                      FROM lapsed.viitenr
                                      WHERE isikukood::TEXT = v_vn.ik::TEXT
                                        AND ltrim(rtriM(viitenumber))::TEXT = l_vn::TEXT)
                        THEN
                            RAISE EXCEPTION 'Puudub voi vale vn %', l_vn;
                        END IF;

                        -- неправильный код, правим
                        UPDATE lapsed.lapse_kaart
                        SET properties = properties || ('{"viitenr":"' || l_vn || '"}')::JSONB
                        WHERE id = v_vk.id;

                        RAISE NOTICE 'updated v_vk.id %, uus v_vn.vn %, vana %', v_vk.id,l_vn, v_vk.viitenr;
                        l_kokku = l_kokku + 1;
                    END IF;
                END LOOP;

            IF l_rekv_id IS NULL
            THEN
                RAISE EXCEPTION 'Puudub l_rekv_id %', v_vn;
            END IF;

        END LOOP;
    RETURN l_kokku;

END;
$$;

SELECT lapsed.update_multiple_vn();

DROP FUNCTION IF EXISTS lapsed.update_multiple_vn();

