DROP VIEW IF EXISTS hooldekodu.cur_hooettemaksud;

CREATE VIEW hooldekodu.cur_hooettemaksud AS
SELECT hette.id,
       hette.kpv,
       hette.isikid,
       hette.summa,
       hette.dokid,
       hette.doktyyp,
       hette.selg::VARCHAR(254)                  AS selg,
       hette.staatus,
       coalesce(qryJournalId.number, 0)::INTEGER AS lausend,
       hette.rekvid
FROM hooldekodu.hooettemaksud hette
         LEFT OUTER JOIN cur_journal qryJournalId ON hette.dokid = qryJournalId.id
    AND hette.doktyyp = 'LAUSEND'
WHERE hette.staatus < 3;

GRANT SELECT ON TABLE hooldekodu.cur_hooettemaksud TO hkametnik;
GRANT SELECT ON TABLE hooldekodu.cur_hooettemaksud TO soametnik;


SELECT *
FROM hooldekodu.cur_hooettemaksud
