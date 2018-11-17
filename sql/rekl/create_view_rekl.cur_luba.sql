DROP VIEW IF EXISTS cur_luba;

CREATE VIEW cur_luba AS
  SELECT
    d.id,
    to_char(d.created, 'DD.MM.YYYY HH:MM' :: TEXT)                   AS created,
    to_char(d.lastupdate, 'DD.MM.YYYY HH:MM' :: TEXT)                AS lastupdate,
    d.rekvid,
    luba.id                                                          AS lubaid,
    luba.asutusid,
    luba.number,
    luba.algkpv,
    luba.loppkpv,
    luba.summa,
    luba.jaak,
    luba.volg,
    a.nimetus                                                        AS asutus,
    a.regkood                                                        AS regkood,
    CASE WHEN luba.staatus > 0
      THEN ' Kehtiv'
    ELSE 'Anulleritud' END :: VARCHAR(20)                            AS status,
    luba.staatus,
    (SELECT sum(summa)
     FROM rekl.ettemaksud
     WHERE parentid = luba.asutusid)                                 AS ettemaks,
    luba.parentid,
    (SELECT sum(dekl - tasu)
     FROM rekl.dekl_jaak
     WHERE asutusid = luba.asutusid AND tyyp = 'INTRESS') :: NUMERIC AS IntrJaak
  FROM docs.doc d
    INNER JOIN rekl.luba luba ON d.id = luba.parentid
    INNER JOIN libs.asutus a ON a.id = luba.asutusid;

GRANT SELECT ON TABLE cur_luba TO dbvaatleja;
