DROP VIEW IF EXISTS palk.cur_puudumine;

CREATE OR REPLACE VIEW palk.cur_puudumine AS
SELECT p.id,
       p.lepingid,
       p.kpv1,
       p.kpv2,
       p.paevad,
       p.summa,
       p.puudumiste_liik :: VARCHAR(20) AS pohjus,
       p.tyyp,
       amet.nimetus                     AS amet,
       t.rekvid,
       a.regkood                        AS isikukood,
       a.nimetus                        AS isik,
       tyyp.eesti :: VARCHAR(20)        AS liik,
       CASE
           WHEN p.puudumiste_liik = 'PUHKUS' AND p.tyyp <= 3 THEN TRUE
           WHEN p.puudumiste_liik = 'PUHKUS' AND p.tyyp > 4  THEN TRUE
           WHEN p.puudumiste_liik = 'HAIGUS' THEN TRUE
           ELSE FALSE END               AS kas_muutab_kalendripäevad
FROM palk.puudumine p
         INNER JOIN palk.tooleping t ON p.lepingid = t.id
         INNER JOIN libs.library amet ON t.ametid = amet.id
         INNER JOIN libs.asutus a ON t.parentid = a.id
         INNER JOIN palk.com_puudumiste_tyyp tyyp ON tyyp.liik = p.puudumiste_liik AND p.tyyp = tyyp.id
WHERE p.status <> 'deleted';

GRANT SELECT ON TABLE palk.cur_puudumine TO dbpeakasutaja;
GRANT SELECT ON TABLE palk.cur_puudumine TO dbkasutaja;
GRANT ALL ON TABLE palk.cur_puudumine TO dbadmin;
GRANT SELECT ON TABLE palk.cur_puudumine TO dbvaatleja;
GRANT ALL ON TABLE palk.cur_puudumine TO taabel;


/*
select * from palk.cur_puudumine
 */

