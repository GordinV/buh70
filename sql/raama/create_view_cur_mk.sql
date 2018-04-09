DROP VIEW IF EXISTS cur_mk;

CREATE OR REPLACE VIEW cur_mk AS
  SELECT
    d.id,
    Mk.rekvid,
    Mk1.journalid,
    Mk.kpv,
    Mk.number,
    Mk.selg,
    MK.OPT,
    CASE WHEN mk.opt = 0
      THEN Mk1.summa
    ELSE 0 :: NUMERIC(14, 2) END          AS kreedit,
    CASE WHEN mk.opt = 1
      THEN Mk1.summa
    ELSE 0 :: NUMERIC(14, 2) END          AS deebet,
    A.regkood,
    A.nimetus,
    N.kood,
    coalesce(Aa.arve, '') :: VARCHAR(20)  AS aa,
    coalesce(jid.number, 0) :: INTEGER    AS journalnr,
    coalesce(v.valuuta, 'EUR') :: VARCHAR AS valuuta,
    coalesce(v.kuurs, 1) :: NUMERIC       AS kuurs
  FROM docs.doc d
    INNER JOIN docs.Mk mk ON mk.parentid = d.id
    INNER JOIN docs.Mk1 mk1 ON mk.id = mk1.parentid
    INNER JOIN libs.Asutus a ON mk1.asutusId = a.ID
    INNER JOIN libs.Nomenklatuur n ON mk1.nomid = n.id
    LEFT OUTER JOIN ou.Aa aa ON Mk.aaid = Aa.id
    LEFT OUTER JOIN docs.Journalid jid ON Mk1.journalid = Jid.journalid
    LEFT OUTER JOIN docs.dokvaluuta1 v
      ON (v.dokid = mk1.id AND v.dokliik = array_position((enum_range(NULL :: DOK_VALUUTA)), 'mk1'));


GRANT SELECT ON TABLE cur_mk TO dbkasutaja;
GRANT SELECT ON TABLE cur_mk TO dbvaatleja;
GRANT SELECT ON TABLE cur_mk TO dbpeakasutaja;
