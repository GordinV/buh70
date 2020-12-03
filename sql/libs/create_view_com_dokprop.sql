DROP VIEW IF EXISTS com_dokprop;

CREATE OR REPLACE VIEW com_dokprop AS

  SELECT
    d.id,
    d.selg                                             AS nimetus,
    l.nimetus                                          AS dok,
    l.kood,
    (d.details :: JSONB ->> 'konto') :: VARCHAR(20)    AS konto,
    (d.details :: JSONB ->> 'kbmkonto') :: VARCHAR(20) AS kbmkonto,
    (d.details :: JSONB ->> 'kood1') :: VARCHAR(20)    AS kood1,
    (d.details :: JSONB ->> 'kood2') :: VARCHAR(20)    AS kood2,
    (d.details :: JSONB ->> 'kood3') :: VARCHAR(20)    AS kood3,
    (d.details :: JSONB ->> 'kood5') :: VARCHAR(20)    AS kood5,
    d.asutusid,
    d.rekvid,
    (l.properties::JSONB ->> 'valid')::DATE as valid
  FROM libs.library l
    INNER JOIN libs.dokprop d ON l.id = d.parentId
  WHERE l.library = 'DOK'
        AND d.status <> 3
  ORDER BY kood;

GRANT SELECT ON TABLE com_dokprop TO dbkasutaja;
GRANT SELECT ON TABLE com_dokprop TO dbvaatleja;
GRANT SELECT ON TABLE com_dokprop TO dbpeakasutaja;
GRANT ALL ON TABLE com_dokprop TO dbadmin;

select * from com_dokprop
