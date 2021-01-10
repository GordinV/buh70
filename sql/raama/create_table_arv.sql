-- Table: public.arv

DROP TABLE IF EXISTS docs.arv;

CREATE TABLE docs.arv
(
  id        SERIAL,
  rekvid    INTEGER        NOT NULL,
  userid    INTEGER        NOT NULL,
  journalid INTEGER        NOT NULL DEFAULT 0,
  doklausid INTEGER        NOT NULL DEFAULT 0,
  liik      SMALLINT       NOT NULL DEFAULT 0,
  operid    INTEGER        NOT NULL DEFAULT 0,
  "number"  CHARACTER(20)  NOT NULL DEFAULT space(1),
  kpv       DATE           NOT NULL DEFAULT ('now' :: TEXT) :: DATE,
  asutusid  INTEGER        NOT NULL DEFAULT 0,
  arvid     INTEGER        NOT NULL DEFAULT 0,
  lisa      CHARACTER(120) NOT NULL DEFAULT space(1),
  tahtaeg   DATE,
  kbmta     NUMERIC(12, 4) NOT NULL DEFAULT 0,
  kbm       NUMERIC(12, 4) NOT NULL DEFAULT 0,
  summa     NUMERIC(12, 4) NOT NULL DEFAULT 0,
  tasud     DATE,
  tasudok   CHARACTER(254),
  muud      TEXT,
  jaak      NUMERIC(12, 4) NOT NULL DEFAULT 0,
  objektid  INTEGER        NOT NULL DEFAULT 0,
  objekt    CHARACTER VARYING(20),
  parentId  INTEGER,
  CONSTRAINT arv_pkey PRIMARY KEY (id)
)
WITH (
OIDS = TRUE
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.arv TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.arv TO dbkasutaja;
GRANT ALL ON TABLE docs.arv TO dbadmin;
GRANT SELECT ON TABLE docs.arv TO dbvaatleja;


CREATE INDEX idx_arv_parentid
  ON docs.arv USING BTREE (parentid);
CREATE INDEX idx_arv_rekvid
  ON docs.arv USING BTREE (rekvid);
CREATE INDEX idx_arv_asutusid
  ON docs.arv USING BTREE (asutusid);


ALTER TABLE docs.arv ADD properties JSONB NULL;
/*
insert into docs.arv
	select * from arv
*/


DROP RULE IF EXISTS arv_insert_2020 ON docs.arv;
CREATE RULE arv_insert_2020 AS ON INSERT TO docs.arv
  WHERE kpv <= '2020-12-31'
  DO INSTEAD NOTHING;
