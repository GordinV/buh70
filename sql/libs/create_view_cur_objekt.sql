DROP VIEW IF EXISTS cur_objekt;

CREATE VIEW cur_objekt AS
SELECT l.id,
       l.rekvid,
       l.kood,
       l.nimetus,
       COALESCE(a.nimetus, '' :: BPCHAR)               AS asutus,
       (l.properties :: JSONB ->> 'nait14') :: NUMERIC AS nait14,
       (l.properties :: JSONB ->> 'nait15') :: NUMERIC AS nait15,
       (l.properties :: JSONB ->> 'valid') ::DATE      AS valid
FROM libs.library l
         LEFT JOIN libs.asutus a ON (l.properties :: JSONB ->> 'asutusid') :: INTEGER = a.id
WHERE l.library = 'OBJEKT'
  AND l.status <> 3;
