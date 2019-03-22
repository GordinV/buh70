DROP VIEW IF EXISTS cur_kulude_kassa_taitmine;

CREATE VIEW cur_kulude_kassa_taitmine AS
SELECT
  month(j.kpv)    AS kuu,
  year(j.kpv)     AS aasta,
  j.rekvid,
  rekv.nimetus    AS asutus,
  rekv.parentid,
  j1.tunnus       AS tunnus,
  sum(j1.summa)   AS summa,
  j1.kood5        AS artikkel,
  j1.kood1        AS tegev,
  j1.kood2        AS allikas,
  l.nimetus       AS nimetus,
  array_agg(d.id) AS docs_ids
FROM docs.doc d
       INNER JOIN docs.journal j ON j.parentid = d.id
       INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
       INNER JOIN ou.rekv rekv ON j.rekvid = rekv.id
       JOIN eelarve.kassa_kulud kassakulud ON ltrim(rtrim(j1.deebet)) ~~ ltrim(rtrim(kassakulud.kood))
       JOIN eelarve.kassa_kontod kassakontod ON ltrim(rtrim(j1.kreedit)) ~~ ltrim(rtrim(kassakontod.kood))
       LEFT OUTER JOIN libs.library l ON l.kood = j1.kood5 AND l.library = 'TULUDEALLIKAD'
WHERE l.tun5 = 2
GROUP BY (YEAR(j.kpv)), (MONTH(j.kpv)), j.rekvid, rekv.parentid, rekv.nimetus,
         j1.kood1, j1.kood5, j1.kood2, j1.tunnus, l.nimetus;


GRANT SELECT ON TABLE cur_kulude_kassa_taitmine TO dbpeakasutaja;
GRANT SELECT ON TABLE cur_kulude_kassa_taitmine TO dbkasutaja;
GRANT ALL ON TABLE cur_kulude_kassa_taitmine TO dbadmin;
GRANT SELECT ON TABLE cur_kulude_kassa_taitmine TO dbvaatleja;
GRANT SELECT ON TABLE cur_kulude_kassa_taitmine TO eelaktsepterja;
GRANT SELECT ON TABLE cur_kulude_kassa_taitmine TO eelallkirjastaja;
GRANT SELECT ON TABLE cur_kulude_kassa_taitmine TO eelesitaja;
GRANT SELECT ON TABLE cur_kulude_kassa_taitmine TO eelkoostaja;

