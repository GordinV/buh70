DROP VIEW IF EXISTS cur_tunnus;

CREATE VIEW cur_tunnus(id, kood, nimetus, rekvid) AS
SELECT l.id,
       l.kood,
       l.nimetus,
       l.rekvid,
       (l.properties::JSONB ->> 'valid')::DATE AS valid,
       l.muud
FROM libs.library l
WHERE ((l.library = 'TUNNUS'::BPCHAR) AND (l.status <> 3));

ALTER TABLE cur_tunnus
    OWNER TO postgres;


GRANT SELECT ON cur_tunnus TO dbpeakasutaja;
GRANT SELECT ON cur_tunnus TO dbkasutaja;
GRANT SELECT ON cur_tunnus TO dbvaatleja;