DROP VIEW IF EXISTS cur_tulude_taitmine;

CREATE VIEW cur_tulude_taitmine AS
SELECT month(coalesce(a.kpv, j.kpv)) AS kuu,
       year(coalesce(a.kpv, j.kpv))  AS aasta,
       j.rekvid,
       rekv.nimetus                  AS asutus,
       rekv.parentid,
       j1.tunnus                     AS tunnus,
       sum(j1.summa)                 AS summa,
       j1.kood5                      AS artikkel,
       j1.kood1                      AS tegev,
       j1.kood2                      AS allikas,
       l.nimetus                     AS nimetus,
       array_agg(d.id)               AS docs_ids
FROM docs.doc d
         INNER JOIN docs.journal j ON j.parentid = d.id
         INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
         INNER JOIN ou.rekv rekv ON j.rekvid = rekv.id
    -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
         LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
         LEFT OUTER JOIN libs.library l ON l.kood = j1.kood5 AND l.library = 'TULUDEALLIKAD' AND l.tun5 = 1
         JOIN eelarve.fakt_tulud fakttulud
              ON ((ltrim(rtrim((j1.kreedit) :: TEXT)) ~~ ltrim(rtrim((fakttulud.kood) :: TEXT))))
GROUP BY (year(coalesce(a.kpv, j.kpv))), (month(coalesce(a.kpv, j.kpv))), j.rekvid, rekv.parentid, rekv.nimetus,
         j1.kood1, j1.kood5, j1.kood2, j1.tunnus, l.nimetus;

GRANT SELECT ON TABLE cur_tulude_taitmine TO dbpeakasutaja;
GRANT SELECT ON TABLE cur_tulude_taitmine TO dbkasutaja;
GRANT ALL ON TABLE cur_tulude_taitmine TO dbadmin;
GRANT SELECT ON TABLE cur_tulude_taitmine TO dbvaatleja;


/*
select * from cur_tulude_taitmine
 */