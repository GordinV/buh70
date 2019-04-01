DROP VIEW IF EXISTS cur_mk;
DROP VIEW IF EXISTS cur_pank;

CREATE OR REPLACE VIEW cur_pank AS
  SELECT
    d.id,
    Mk.rekvid,
    Mk1.journalid,
    Mk.kpv,
    Mk.number,
    Mk.selg,
    MK.OPT,
    CASE WHEN mk.opt = 2
      THEN Mk1.summa
    ELSE 0 :: NUMERIC(14, 2) END          AS deebet,
    CASE WHEN mk.opt = 1 or coalesce(mk.opt,0) = 0
           THEN Mk1.summa
         ELSE 0 :: NUMERIC(14, 2) END          AS kreedit,
    coalesce(A.regkood,'')::varchar(20) as regkood,
    coalesce(A.nimetus,'')::VARCHAR(254) as nimetus,
    coalesce(N.kood,'')::varchar(20) as kood,
    coalesce(Aa.arve, '') :: VARCHAR(20)  AS aa,
    coalesce(jid.number, 0) :: INTEGER    AS journalnr,
    'EUR' :: VARCHAR AS valuuta,
    1 :: NUMERIC       AS kuurs
  FROM docs.doc d
    INNER JOIN docs.Mk mk ON mk.parentid = d.id
    INNER JOIN docs.Mk1 mk1 ON mk.id = mk1.parentid
    LEFT OUTER JOIN libs.Asutus a ON mk1.asutusId = a.ID
    LEFT OUTER JOIN libs.Nomenklatuur n ON mk1.nomid = n.id
    LEFT OUTER JOIN ou.Aa aa ON Mk.aaid = Aa.id
    LEFT OUTER JOIN docs.Journalid jid ON Mk1.journalid = Jid.journalid;

GRANT SELECT ON TABLE cur_pank TO dbkasutaja;
GRANT SELECT ON TABLE cur_pank TO dbvaatleja;
GRANT SELECT ON TABLE cur_pank TO dbpeakasutaja;
