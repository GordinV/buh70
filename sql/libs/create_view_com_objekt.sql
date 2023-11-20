DROP VIEW IF EXISTS com_objekt;

CREATE VIEW com_objekt AS
SELECT qry.id,
       qry.kood,
       qry.nimetus,
       qry.rekvid,
       qry.valid
FROM (SELECT 0                         AS id,
             ''::CHARACTER VARYING(20) AS kood,
             ''::CHARACTER VARYING(20) AS nimetus,
             NULL::INTEGER             AS rekvid,
             NULL::DATE                AS valid
      UNION
      SELECT l.id,
             l.kood,
             l.nimetus,
             l.rekvid,
             (l.properties::JSON ->> 'valid')::DATE AS valid
      FROM libs.library l
      WHERE ((l.library = 'OBJEKT'::BPCHAR) AND (l.status <> 3))) qry
ORDER BY qry.kood;

GRANT SELECT ON TABLE com_objekt TO dbkasutaja;
GRANT SELECT ON TABLE com_objekt TO dbpeakasutaja;
GRANT INSERT, SELECT, UPDATE, DELETE, REFERENCES, TRIGGER ON TABLE com_objekt TO dbvaatleja;
