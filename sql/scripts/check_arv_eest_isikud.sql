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
                      $$951002;61109150195;48908250111
951002;60503243764;48112063712
951002;50509253723;47207062214
951002;60407162225;47208133735
951002;60504143719;47105093715
951002;60403023735;38105212278
951002;60403143733;37903012278
951002;60312153714;47508183746
951002;51008220073;48509053715
951002;60606223713;47204262233
951002;61011023719;47909072219
951002;60607117116;47801160029
951002;60607033713;46706022227
951002;60907153720;48212273712
951002;60707043745;48609253719
951002;45906293746;45906293746
951002;60605073720;48509282217
951002;60307310018;47406110092
951002;60111093714;47504203718
951002;61306010076;49004113710
951002;50407283742;45001213737
951002;39901133713;36410223723
951002;60209023715;46906153736
951002;61202043739;48511033718
951002;61401230145;49010023717
951002;60802013735;47301083710
951002;60905253727;48803053727
951002;60703043714;48106163723
951002;61105033712;47903293724
951002;60304010251;47607273732
951002;50704233712;38106313737
951002;60712193743;48211273718
951002;49606283749;49606283749
951002;50402053717;48003303722
951002;60709122216;48703272224
951002;61306200070;49105133721
951002;60609023716;47803063710
951002;60508233716;48106133713
951002;60606053733;48310122210
951002;60505083713;48501103723
951002;60512263711;46912293721
951002;51311070063;48506013716
951002;60605153734;48303113712
951002;60603273722;47504203718
951002;61304220150;49104143712
951002;60605153745;37307073710
951002;60304293743;37511073712
951002;60406223740;46306152242
951002;61112083725;48303133726
951002;50507223714;48109273718
951002;50409163743;47904283711
951002;60505203768;46802212215
951002;51510220085;48804192235
951002;61405290087;49309244713
951002;49607313722;49607313722
951002;48709062219;48709062219
951002;48302123725;48302123725
951002;46509212241;46509212241
951002;61210153736;38710183717
951002;61111033735;48312253712
951002;61306040129;38604043718
951002;51304120034;48006062238
951002;60611103727;48003303722
951002;60112243729;47401233723
951002;61309300123;47901223713
951002;61003163737;46004192240
951002;61311290166;49109263713
951002;61505190062;48408052275
951002;51105183728;49005293711
951002;61001122212;48403052245
951002;61101113739;48212142220
951002;60806263736;37803143712
951002;60706233712;47803233712
951002;60812183740;37710273714
951002;61109020200;48811120051
951002;61004193719;47004113728
951002;60301273714;47505063722
951002;50512303718;47705313722
951002;60608077065;48309293727
951002;50203110246;47604163715
951002;60610103722;48109192217
951002;60605263747;47909073717
951002;60501253717;48501043734
951002;51303010060;39011033717
951002;60610277133;46812023745
951002;60512193715;48105293723
951002;61007210084;48801227010
951002;60510293744;48507283716
951002;60602213741;47612133710
951002;60504203720;46912033722
951002;60504220884;38312047016
951002;61212310173;48909213722
951002;50908313719;38404130045
951002;61301284710;48108143727
951002;50911033728;47906183715
951002;50912093715;49112182214
951002;60306073738;47207263724
951002;60501063723;47904203721
951002;60508183723;46708113723
951002;50509223757;35812033716
951002;60612043754;47710203710
951002;61211223748;49107072255
951002;60511233718;47609043720
951002;61006303711;48101242214
951002;60801147026;47112242210
951002;61010050076;48707033719
951002;60609270020;47605040012
951002;60903143748;48607093725
951002;51108293725;48012072218
951002;61103103710;48005062211
951002;61006173726;48504013728
951002;61012083722;48612253721
951002;61203163721;48601060019
951002;60710153716;48412142259
951002;60405203710;47810072219
951002;50207203724;45806293743
951002;50601313729;46908163742
951002;60301267010;36003157017
951002;60107103716;37103253726
951002;60604193713;47608203710
951002;60910163733;48804203715
951002;60712243714;49006103713
951002;61208223713;37110112260
951002;61207050062;48302210079
951002;51203183723;48605102270
951002;60910182212;48303292221
951002;61002013713;49005047010
951002;61010193725;48608293720
951002;60909233722;38710223725
951002;51008243720;36301013735
951002;60409053720;48107223717
951002;50807113710;37905103719
951002;60810162738;48305282257
951002;50802173727;48903022222
951002;60605233715;47105182254
951002;50409293726;47503153711
951002;61008180109;48204283736
951002;60911043725;45412173717
951002;61102072739;46207193715
951002;61109193736;48709063728
951002;50810107040;48403130019
951002;50810107051;48403130019
951002;61403010107;48901132225
951002;51405130191;38110280050
951002;61411020119;49311023720
951002;61401200092;47903282230
951002;61401290132;48012143734
951002;61305230195;48005153721
951002;60201173749;47403083723
951002;60311210021;47012090051
951002;60511153726;37504183714
951002;60506103723;47801013731
951002;50706073716;47808064213
951002;60512133717;47110222229
951002;60501313728;48010273731
951002;60308123726;47511192213
951002;60802013724;46603222210
951002;60505053736;47710073714
951002;60809077124;46211143720
951002;60912153732;48912063747
951002;61209103731;48910013713
951002;46702043721;46702043721
951002;60507303718;47609012267
951002;50911157050;47810312245$$, '\n') AS l) t;

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

            IF NOT coalesce(v_vanem.arved, FALSE)
            THEN
                RAISE NOTICE 'v_vn.isik_ik %, l_laps_id %, l_asutus_id %, l_vanem_id %, l_rekv_id %',v_vn.isik_ik, l_laps_id, l_asutus_id, l_vanem_id, l_rekv_id;

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
