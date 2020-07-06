DROP FUNCTION IF EXISTS eelarve.koosta_kond_saldoandmik(INTEGER, DATE);

CREATE OR REPLACE FUNCTION eelarve.koosta_kond_saldoandmik(IN user_id INTEGER,
                                                           IN l_kpv DATE,
                                                           OUT error_code INTEGER,
                                                           OUT result INTEGER,
                                                           OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_oma_tp    TEXT        = fnc_getomatp(63, year(l_kpv)); -- ainult rahandus võib koosta kond
    v_omatp     RECORD;
    v_tp        RECORD;
    l_tulemus   INTEGER;
    l_timestamp VARCHAR(20) = left(now() :: TEXT, 20);
    l_rekvid    INTEGER     = 63; -- rahandusamet
BEGIN

    -- check for user_id
    IF NOT (SELECT (roles ->> 'is_peakasutaja') :: BOOLEAN
            FROM ou.userid
            WHERE id = user_id)
    THEN
        error_code = 5;
        error_message = 'Kasutaja ei leitud,  userId:' ||
                        coalesce(user_id, 0) :: TEXT;
        result = 0;

        RAISE NOTICE 'eelarve.koosta_kond_saldoandmik, error_message %', error_message;
        RETURN;
    END IF;


    DELETE
    FROM eelarve.saldoandmik
    WHERE aasta = year(l_kpv)
      AND kuu = month(l_kpv)
      AND rekvid = 999;

    -- koostame kond saldoandmik
    DELETE
    FROM tmp_saldoandmik
    WHERE rekvid = l_rekvid;

    -- kond
    FOR v_omatp IN
        SELECT DISTINCT omatp
        FROM eelarve.saldoandmik
        WHERE aasta = year(l_kpv)
          AND kuu = month(l_kpv)
          AND left(omatp, 4) = left(l_oma_tp, 4)
        LOOP
            RAISE NOTICE 'v_omatp %', v_omatp.omatp;
            INSERT INTO tmp_saldoandmik (nimetus, db, kr, konto, tegev, tp, allikas, rahavoo, timestamp, kpv, rekvid)
            SELECT coalesce(s.nimetus, ''),
                   CASE
                       WHEN kontod.tyyp IS NULL OR kontod.tyyp IN (1, 3)
                           THEN s.db - s.kr
                       ELSE 0 :: NUMERIC END AS db,
                   CASE
                       WHEN kontod.tyyp IS NOT NULL AND kontod.tyyp IN (2, 4)
                           THEN s.kr - s.db
                       ELSE 0 :: NUMERIC END AS kr,
                   s.konto,
                   s.tegev,
                   s.tp,
                   s.allikas,
                   s.rahavoo,
                   l_timestamp,
                   date(),
                   l_rekvid
            FROM eelarve.saldoandmik s
                     LEFT OUTER JOIN com_kontoplaan kontod ON (ltrim(rtrim(kontod.kood)) = ltrim(rtrim(s.konto)))
            WHERE s.aasta = year(l_kpv)
              AND s.kuu = month(l_kpv)
              AND ltrim(rtrim(s.omatp)) = ltrim(rtrim(v_omatp.omatp));

            FOR v_tp IN
                SELECT DISTINCT tp
                FROM eelarve.saldoandmik
                WHERE aasta = year(l_kpv)
                  AND kuu = month(l_kpv)
                  AND ltrim(rtrim(omatp)) = ltrim(rtrim(v_omatp.omatp))
                  AND ltrim(rtrim(tp)) <> ltrim(rtrim(omatp))
                  AND left(ltrim(rtrim(tp)), 4) = left(ltrim(rtrim(l_Oma_tp)), 4)
                LOOP

                    -- kirjutame miinus summad
                    -- deebet

                    INSERT INTO tmp_saldoandmik (nimetus, db, kr, konto, tegev, tp, allikas, rahavoo, timestamp, kpv,
                                                 rekvid)
                    SELECT coalesce(nimetus, ''),
                           kr,
                           db,
                           konto,
                           tegev,
                           tp,
                           allikas,
                           rahavoo,
                           l_timestamp,
                           date(),
                           l_rekvid
                    FROM eelarve.saldoandmik
                    WHERE aasta = year(l_Kpv)
                      AND kuu = month(l_Kpv)
                      AND ltrim(rtrim(omatp)) = ltrim(rtrim(v_omatp.OmaTp))
                      AND ltrim(rtrim(tp)) = ltrim(rtrim(v_tp.tp))
                      AND left(konto, 1) = '1';

                    -- kreedit
                    INSERT INTO tmp_saldoandmik (nimetus, db, kr, konto, tegev, tp, allikas, rahavoo, timestamp, kpv,
                                                 rekvid)
                    SELECT coalesce(nimetus, ''),
                           kr,
                           db,
                           konto,
                           tegev,
                           tp,
                           allikas,
                           rahavoo,
                           l_timestamp,
                           date(),
                           l_rekvId
                    FROM eelarve.saldoandmik
                    WHERE aasta = year(l_Kpv)
                      AND kuu = month(l_Kpv)
                      AND ltrim(rtrim(omatp)) = ltrim(rtrim(v_tp.tp))
                      AND left(omatp, 4) = left(l_oma_tp, 4)
                      AND ltrim(rtrim(tp)) = ltrim(rtrim(v_omatp.omatp))
                      AND left(konto, 1) = '2';

                    -- (võrreldava saldoandmik (kõik kontod algusega 4 kuni 6, mille esitaja kood on TP kood on aruande koostaja kood (deebet miinus kreedit,
                    --	välja arvatud kontod 601000 ja 601001, mida ei võeta üldse arvesse olenemata TP koodist)))
                    INSERT INTO tmp_saldoandmik (nimetus, db, kr, konto, tegev, tp, allikas, rahavoo, timestamp, kpv,
                                                 rekvid)
                    SELECT coalesce(nimetus, ''),
                           kr,
                           db,
                           konto,
                           tegev,
                           tp,
                           allikas,
                           rahavoo,
                           l_timestamp,
                           date(),
                           l_rekvId
                    FROM eelarve.saldoandmik
                    WHERE aasta = year(l_Kpv)
                      AND kuu = month(l_Kpv)
                      AND ltrim(rtrim(omatp)) = ltrim(rtrim(v_omatp.OmaTp))
                      AND ltrim(rtrim(tp)) = ltrim(rtrim(v_tp.tp))
                      AND left(konto, 1) IN ('4', '5', '6')
                      AND konto NOT IN ('601000', '601001');

                    --(esitaja saldoandmik sum (kõik kontod algusega 3, mille TP kood on võrreldava kood (kreedit miinus deebet)))

                    INSERT INTO tmp_saldoandmik (nimetus, db, kr, konto, tegev, tp, allikas, rahavoo, timestamp, kpv,
                                                 rekvid)
                    SELECT coalesce(nimetus, ''),
                           kr,
                           db,
                           konto,
                           tegev,
                           tp,
                           allikas,
                           rahavoo,
                           l_timestamp,
                           date(),
                           l_rekvId
                    FROM eelarve.saldoandmik
                    WHERE aasta = year(l_Kpv)
                      AND kuu = month(l_Kpv)
                      AND ltrim(rtrim(omatp)) = ltrim(rtrim(v_tp.tp))
                      AND left(omatp, 4) = left(l_oma_tp, 4)
                      AND ltrim(rtrim(tp)) = ltrim(rtrim(v_omatp.omatp))
                      AND left(konto, 1) = '3';

                    --(esitaja saldoandmik sum (kõik kontod algusega 7, mille TP kood on võrreldava kood (deebet miinus kreedit)))
                    INSERT INTO tmp_saldoandmik (nimetus, db, kr, konto, tegev, tp, allikas, rahavoo, timestamp, kpv,
                                                 rekvid)
                    SELECT coalesce(nimetus, ''),
                           kr,
                           db,
                           konto,
                           tegev,
                           tp,
                           allikas,
                           rahavoo,
                           l_timestamp,
                           date(),
                           l_rekvId
                    FROM eelarve.saldoandmik
                    WHERE aasta = year(l_Kpv)
                      AND kuu = month(l_Kpv)
                      AND ltrim(rtrim(omatp)) = ltrim(rtrim(v_omatp.OmaTp))
                      AND ltrim(rtrim(tp)) = ltrim(rtrim(v_tp.tp))
                      AND left(konto, 2) = '70';

                    --(võrreldava saldoandmik (kõik kontod algusega 7, mille TP kood on aruande koostaja kood (kreedit miinus deebet)))
                    INSERT INTO tmp_saldoandmik (nimetus, db, kr, konto, tegev, tp, allikas, rahavoo, timestamp, kpv,
                                                 rekvid)
                    SELECT coalesce(nimetus, ''),
                           kr,
                           db,
                           konto,
                           tegev,
                           tp,
                           allikas,
                           rahavoo,
                           l_timestamp,
                           date(),
                           l_rekvId
                    FROM eelarve.saldoandmik
                    WHERE aasta = year(l_Kpv)
                      AND kuu = month(l_Kpv)
                      AND left(omatp, 4) = left(l_oma_tp, 4)
                      AND ltrim(rtrim(omatp)) = ltrim(rtrim(v_tp.tp))
                      AND ltrim(rtrim(tp)) = ltrim(rtrim(v_omatp.omatp))
                      AND left(konto, 2) = '71';

                END LOOP;
        END LOOP;


    IF (
           SELECT round(sum(db)) - round(sum(kr))
           FROM tmp_saldoandmik
           WHERE ltrim(rtrim(timestamp)) = ltrim(rtrim(l_timestamp))
             AND tyyp = 0
             AND left(tp, 4) = left(l_oma_tp, 4)
             AND left(konto, 1) = '7'
       ) = 0
    THEN
        DELETE
        FROM tmp_saldoandmik
        WHERE timestamp = l_timestamp
          AND left(ltrim(rtrim(konto)), 1) = '7';

    END IF;

    -- parandame kassa nimetus sest need oli tehtud 3 erinevad
    UPDATE tmp_saldoandmik
    SET nimetus = 'Kassa'
    WHERE konto = '100000'
      AND ltrim(rtrim(timestamp)) = ltrim(rtrim(l_timestamp));

    -- salvestame kond saldoandmik

    INSERT INTO eelarve.saldoandmik (nimetus, db, kr, konto, tegev, tp, allikas, rahavoo, kpv, aasta, kuu, rekvid,
                                     omatp)
    SELECT nimetus,
           sum(db),
           sum(kr),
           konto,
           tegev,
           tp,
           allikas,
           rahavoo,
           l_kpv,
           year(l_Kpv),
           month(l_Kpv),
           999,
           l_oma_tp
    FROM (
             SELECT coalesce(nimetus, '') AS nimetus,
                    sum(db)               AS db,
                    sum(kr)               AS kr,
                    konto,
                    tegev,
                    tp,
                    allikas,
                    rahavoo
             FROM (
                      SELECT ltrim(rtrim(tmp_saldoandmik.nimetus))     AS nimetus,
                             CASE
                                 WHEN kontod.tyyp IS NULL OR kontod.tyyp IN (1, 3)
                                     THEN tmp_saldoandmik.db - tmp_saldoandmik.kr
                                 ELSE 0 :: NUMERIC END                 AS db,
                             CASE
                                 WHEN kontod.tyyp IS NOT NULL AND kontod.tyyp IN (2, 4)
                                     THEN tmp_saldoandmik.kr - tmp_saldoandmik.db
                                 ELSE 0 :: NUMERIC END                 AS kr,
                             ltrim(rtrim(tmp_saldoandmik.konto))       AS konto,
                             ltrim(rtrim(tmp_saldoandmik.tegev))       AS tegev,
                             left(ltrim(rtrim(tmp_saldoandmik.tp)), 6) AS tp,
                             ltrim(rtrim(tmp_saldoandmik.allikas))     AS allikas,
                             ltrim(rtrim(tmp_saldoandmik.rahavoo))     AS rahavoo
                      FROM tmp_saldoandmik
                               LEFT OUTER JOIN com_kontoplaan kontod
                                               ON (ltrim(rtrim(kontod.kood)) = ltrim(rtrim(tmp_saldoandmik.konto)))
                      WHERE timestamp = l_timestamp
                        AND (tmp_saldoandmik.tyyp <> 1 OR (tmp_saldoandmik.db = tmp_saldoandmik.kr))
                  ) tmp
             GROUP BY konto, nimetus, tegev, tp, allikas, rahavoo
         ) qry
    GROUP BY konto, nimetus, tegev, tp, allikas, rahavoo;

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

GRANT EXECUTE ON FUNCTION eelarve.koosta_kond_saldoandmik(INTEGER, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.koosta_kond_saldoandmik(INTEGER, DATE) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION eelarve.koosta_kond_saldoandmik(INTEGER, DATE) TO dbkasutaja;


/*
select error_code, result, error_message from eelarve.koosta_kond_saldoandmik(70,'2020-03-31')
*/