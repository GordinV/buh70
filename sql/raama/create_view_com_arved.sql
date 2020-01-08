DROP VIEW IF EXISTS com_arved;

CREATE VIEW com_arved AS
SELECT d.id,
       arv.id                                                               AS arv_id,
       Arv.number,
       to_char(Arv.kpv, 'DD.MM.YYYY')::TEXT                                 AS kpv,
       Arv.summa,
       ARV.LIIK,
       RTRIM(Asutus.nimetus) || ' ' || RTRIM(Asutus.omvorm) :: VARCHAR(120) AS asutus,
       Arv.asutusid,
       Arv.arvid,
       Arv.tasudok,
       Arv.tasud,
       arv.rekvid,
       arv.jaak
FROM docs.doc d
         INNER JOIN docs.Arv arv ON d.id = arv.parentid
         INNER JOIN libs.Asutus asutus ON Asutus.id = Arv.asutusid
ORDER BY Arv.number;

GRANT SELECT ON TABLE com_arved TO dbkasutaja;
GRANT SELECT ON TABLE com_arved TO dbvaatleja;
GRANT SELECT ON TABLE com_arved TO dbpeakasutaja;

