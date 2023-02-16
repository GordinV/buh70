DROP TABLE IF EXISTS tmp_vordlemine_asutus;

CREATE TABLE IF NOT EXISTS tmp_vordlemine_asutus (
    ik              TEXT,
    maksja_ik       TEXT,
    arv             BOOLEAN,
    soodustus       BOOLEAN,
    laekumised      BOOLEAN,
    umberarvestatud BOOLEAN,
    algsaldo        BOOLEAN,
    arv_isik        BOOLEAN,
    lopp_saldo      BOOLEAN,
    arv_diff        NUMERIC,
    soodustus_diff  NUMERIC,
    laekumised_diff NUMERIC,
    umber_diff      NUMERIC,
    alg_diff        NUMERIC,
    lopp_diff       NUMERIC
);

DROP FUNCTION IF EXISTS lapsed.arvete_vordlemine_asutus_();

CREATE FUNCTION lapsed.arvete_vordlemine_asutus_()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_vn          RECORD;
    l_count       INTEGER = 0;
    l_arv         NUMERIC = 0;
    v_kaived      RECORD;
    l_asutus      TEXT;
    l_soodustused NUMERIC = 0;
    l_lopp        NUMERIC = 0;
    l_lopp_saldo  NUMERIC = 0;
    l_vale_ik     BOOLEAN;
    l_asutus_ik   TEXT;
    kas_vanem     BOOLEAN;
    l_kehtiv_vk   TEXT;
    l_maksja_ik   TEXT;

BEGIN
    -- Эти VN необходимо присвоить только имеющим слуги детям в своих учреждениях.
-- Если ребенка в указанном учрежд. нет, то такого надо игнорировать и не сохранять его нигде в базе не создавая мусора.
-- Если ребенок есть (имеет услуги), то присваиваем ему старый ВН
-- Если ребенок есть (имеет услуги) и имеет какой-то, ранее присвоенный ВН, то просто добавляем ему еще один ВН

    -- делаем отчет и сохраняем его данные

    FOR v_vn IN
        SELECT sum(regexp_replace(arvestatud, ',', '.')::NUMERIC)      AS arvestatud,
               sum(regexp_replace(alg_salod, ',', '.')::NUMERIC)       AS alg_salod,
               sum(regexp_replace(umberarvestatud, ',', '.')::NUMERIC) AS umberarvestatud,
               sum(regexp_replace(soodustus, ',', '.')::NUMERIC)       AS soodustus,
               sum(regexp_replace(laekumised, ',', '.')::NUMERIC)      AS laekumised,
               sum(regexp_replace(lopp_saldo, ',', '.')::NUMERIC)      AS lopp_saldo,
               sum(regexp_replace(tagastatud, ',', '.')::NUMERIC)      AS tagastatud,
               ik,
               maksja_ik
        FROM (
                 SELECT a.asutus,
                        CASE WHEN empty(a.alg_salod) THEN '0' ELSE alg_salod END             AS alg_salod,
                        CASE WHEN empty(a.umberarvestatud) THEN '0' ELSE umberarvestatud END AS umberarvestatud,
                        CASE WHEN empty(a.laekumised) THEN '0' ELSE laekumised END           AS laekumised,
                        CASE WHEN empty(a.soodustus) THEN '0' ELSE soodustus END             AS soodustus,
                        CASE WHEN empty(a.arvestatud) THEN '0' ELSE arvestatud END           AS arvestatud,
                        CASE WHEN empty(a.lopp_saldo) THEN '0' ELSE lopp_saldo END           AS lopp_saldo,
                        CASE WHEN empty(a.tagastatud) THEN '0' ELSE tagastatud END           AS tagastatud,
                        a.arv_kokku,
                        a.maksja_ik,
                        a.ik
                 FROM tmp_arved a
--                 WHERE                        left(a.asutus, 3) in ('071', '073','077')
             ) qry
        GROUP BY ik, maksja_ik
        ORDER BY ik
    --WHERE vn IS NOT NULL
--          AND vn = '9389337'
        LOOP

            SELECT sum(alg_saldo)     AS alg_saldo,
                   sum(arvestatud)    AS arvestatud,
                   sum(umberarvestus) AS umberarvestus,
                   sum(soodustus)     AS soodustus,
                   sum(laekumised)    AS laekumised,
                   sum(mahakantud)    AS mahakantud,
                   sum(tagastused)    AS tagastused,
                   sum(jaak)          AS jaak
            INTO v_kaived
            FROM tmp_kaived_m
            WHERE lapse_isikukood = v_vn.ik
              AND maksja_isikukood = v_vn.maksja_ik;

            l_lopp_saldo = ((coalesce(v_kaived.alg_saldo, 0) + coalesce(v_kaived.arvestatud, 0)
                - coalesce(v_kaived.soodustus, 0) - coalesce(v_kaived.laekumised, 0)) +
                            coalesce(v_kaived.umberarvestus, 0) + coalesce(v_kaived.tagastused, 0));


            RAISE NOTICE 'l_arv %,v_kaived.arvestatud %, l_soodustused %, v_kaived.soodustus %, l_lopp_saldo %, l_lopp %',l_arv,v_kaived.arvestatud, l_soodustused, v_kaived.soodustus, l_lopp_saldo, l_lopp;

            INSERT INTO tmp_vordlemine_asutus (ik, maksja_ik, arv, soodustus,
                                               laekumised,
                                               umberarvestatud,
                                               algsaldo, lopp_saldo, arv_diff, soodustus_diff, laekumised_diff,
                                               umber_diff, alg_diff, lopp_diff)
            VALUES (v_vn.ik,
                    v_vn.maksja_ik,
                    (v_vn.arvestatud = coalesce(v_kaived.arvestatud, 0)),
                    (v_vn.soodustus = -1 * coalesce(v_kaived.soodustus, 0)),
                    (v_vn.laekumised = coalesce(v_kaived.laekumised, 0)),
                    (v_vn.umberarvestatud = coalesce(v_kaived.umberarvestus, 0)),
                    (v_vn.alg_salod = coalesce(v_kaived.alg_saldo, 0)),
                    (v_vn.lopp_saldo = l_lopp_saldo),
                    v_vn.arvestatud - coalesce(v_kaived.arvestatud, 0),
                    v_vn.soodustus - (-1 * coalesce(v_kaived.soodustus, 0)),
                    v_vn.laekumised - coalesce(v_kaived.laekumised, 0),
                    v_vn.umberarvestatud - coalesce(v_kaived.umberarvestus, 0),
                    v_vn.alg_salod - coalesce(v_kaived.alg_saldo, 0),
                    v_vn.lopp_saldo - l_lopp_saldo);

            l_count = l_count + 1;

        END LOOP;
    RETURN l_count;

END;
$$;

SELECT lapsed.arvete_vordlemine_asutus_();

--DROP FUNCTION IF EXISTS lapsed.arvete_vordlemine();

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
