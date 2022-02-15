DROP VIEW IF EXISTS cur_kulude_kassa_taitmine;

CREATE VIEW cur_kulude_kassa_taitmine AS
SELECT sum(summa)    AS summa,
       sum(kbm)      AS kbm,
       array_agg(id) AS docs_ids,
       kuu,
       aasta,
       rekvid,
       asutus,
       parentid,
       tunnus,
       artikkel,
       tegev,
       allikas,
       rahavoog,
       nimetus
FROM (
         SELECT d.id,
                month(coalesce(a.kpv, j.kpv)) AS kuu,
                year(coalesce(a.kpv, j.kpv))  AS aasta,
                j.rekvid,
                rekv.nimetus                  AS asutus,
                rekv.parentid,
                j1.tunnus                     AS tunnus,
                j1.summa                      AS summa,
                j1.kood5                      AS artikkel,
                j1.kood1                      AS tegev,
                j1.kood2                      AS allikas,
                j1.kood3                      AS rahavoog,
                l.nimetus                     AS nimetus,
                (CASE
                     WHEN (lpad(j1.deebet, 6) = '601000' OR lpad(j1.deebet, 6) = '601001') THEN j1.summa
                     ELSE 0 END):: NUMERIC    AS kbm
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id
                  INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
                  INNER JOIN ou.rekv rekv ON j.rekvid = rekv.id
                  LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                  JOIN eelarve.kassa_kulud kassakulud
                       ON ltrim(rtrim(j1.deebet)) ~~ ltrim(rtrim(kassakulud.kood))
                  JOIN eelarve.kassa_kontod kassakontod
                       ON ltrim(rtrim(j1.kreedit)) ~~ ltrim(rtrim(kassakontod.kood))
                  LEFT OUTER JOIN libs.library l ON l.kood = j1.kood5 AND l.library = 'TULUDEALLIKAD'
         WHERE j1.kood2 =
               CASE WHEN j1.kood5 = '2586' AND left(j1.kreedit, 6) IN ('100100', '999999') THEN '80' ELSE j1.kood2 END
--         WHERE l.tun5 = 2
     ) qry
GROUP BY kuu, aasta, rekvid, asutus, parentid, tunnus,
         artikkel,
         tegev,
         allikas,
         rahavoog,
         nimetus;


GRANT SELECT ON TABLE cur_kulude_kassa_taitmine TO dbpeakasutaja;
GRANT SELECT ON TABLE cur_kulude_kassa_taitmine TO dbkasutaja;
GRANT ALL ON TABLE cur_kulude_kassa_taitmine TO dbadmin;
GRANT SELECT ON TABLE cur_kulude_kassa_taitmine TO dbvaatleja;
GRANT SELECT ON TABLE cur_kulude_kassa_taitmine TO eelaktsepterja;
GRANT SELECT ON TABLE cur_kulude_kassa_taitmine TO eelallkirjastaja;
GRANT SELECT ON TABLE cur_kulude_kassa_taitmine TO eelesitaja;
GRANT SELECT ON TABLE cur_kulude_kassa_taitmine TO eelkoostaja;

/*
select sum(summa) from (
                           SELECT *
                           FROM cur_kulude_kassa_taitmine
                           WHERE artikkel = '4133'
    and rekvid = 64
                       ) qry

*/