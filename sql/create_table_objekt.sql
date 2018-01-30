-- Table: objekt

-- DROP TABLE objekt;

CREATE TABLE libs.objekt
(
  id       SERIAL         NOT NULL,
  libid    INTEGER        NOT NULL,
  asutusid INTEGER        NOT NULL,
  parentid INTEGER        NOT NULL,
  nait01   NUMERIC(14, 4) NOT NULL DEFAULT 0,
  nait02   NUMERIC(14, 4) NOT NULL DEFAULT 0,
  nait03   NUMERIC(14, 4) NOT NULL DEFAULT 0,
  nait04   NUMERIC(14, 4) NOT NULL DEFAULT 0,
  nait05   NUMERIC(14, 4) NOT NULL DEFAULT 0,
  nait06   NUMERIC(14, 4) NOT NULL DEFAULT 0,
  nait07   NUMERIC(14, 4) NOT NULL DEFAULT 0,
  nait08   NUMERIC(14, 4) NOT NULL DEFAULT 0,
  nait09   NUMERIC(14, 4) NOT NULL DEFAULT 0,
  nait10   NUMERIC(14, 4) NOT NULL DEFAULT 0,
  nait11   NUMERIC(14, 4) NOT NULL DEFAULT 0,
  nait12   NUMERIC(14, 4) NOT NULL DEFAULT 0,
  nait13   NUMERIC(14, 4) NOT NULL DEFAULT 0,
  nait14   NUMERIC(14, 4) NOT NULL DEFAULT 0,
  nait15   NUMERIC(14, 4) NOT NULL DEFAULT 0,
  muud     TEXT,
  CONSTRAINT objekt_pkey PRIMARY KEY (id)
)
WITH (OIDS = FALSE
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE libs.objekt TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE libs.objekt TO dbkasutaja;
GRANT ALL ON TABLE libs.objekt TO dbadmin;
GRANT SELECT ON TABLE libs.objekt TO dbvaatleja;

DROP INDEX IF EXISTS objekt_asutusid;

CREATE INDEX objekt_asutusid
  ON libs.objekt
  USING BTREE
  (asutusid);

DROP INDEX IF EXISTS objekt_libid;

CREATE INDEX objekt_libid
  ON libs.objekt
  USING BTREE
  (libid);

DROP INDEX IF EXISTS objekt_parentid;

CREATE INDEX objekt_parentid
  ON libs.objekt
  USING BTREE
  (parentid);

DROP VIEW IF EXISTS cur_objekt;

CREATE OR REPLACE VIEW cur_objekt AS
  SELECT
    l.id,
    l.rekvid,
    l.kood,
    l.nimetus,
    coalesce(a.nimetus, '') AS asutus,
    o.nait14,
    o.nait15
  FROM libs.library l
    INNER JOIN libs.objekt o ON l.id = o.libid
    LEFT OUTER JOIN libs.asutus a ON o.asutusId = a.id
  WHERE status <> 3;

GRANT SELECT ON TABLE cur_objekt TO dbpeakasutaja;
GRANT SELECT ON TABLE cur_objekt TO dbkasutaja;
GRANT ALL ON TABLE cur_objekt TO dbadmin;
GRANT SELECT ON TABLE cur_objekt TO dbvaatleja;


