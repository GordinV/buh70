DROP VIEW IF EXISTS cur_avans3;
DROP VIEW IF EXISTS cur_avans_tasud;

CREATE VIEW cur_avans_tasud AS
  SELECT
    a1.number as dok_number,
    a1.kpv as dok_kpv,
    a.nimetus as isik,
    a.regkood as isikukood,
    a3.*,
    j.kpv,
    j.selg,
    jid.number,
    j.rekvid
  FROM docs.avans3 a3
    inner join docs.avans1 a1 on a1.id = a3.parentid
    inner join libs.asutus as a on a.id = a1.asutusid
    LEFT OUTER JOIN docs.journal j ON j.parentid = a3.dokid
    LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id;

/*
select * from cur_avans_tasud
 */