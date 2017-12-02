
DROP TABLE if exists docs.tooleping;
DROP TABLE if exists libs.tooleping;

CREATE TABLE libs.tooleping
(
  id integer NOT NULL DEFAULT nextval('tooleping_id_seq'::regclass),
  parentid integer NOT NULL,
  osakondid integer NOT NULL DEFAULT 0,
  ametid integer NOT NULL DEFAULT 0,
  algab date NOT NULL DEFAULT ('now'::text)::date,
  lopp date,
  palk numeric(12,4) NOT NULL DEFAULT 0,
  palgamaar smallint NOT NULL DEFAULT 0,
  pohikoht smallint NOT NULL DEFAULT 1,
  ametnik smallint NOT NULL DEFAULT 0,
  tasuliik smallint NOT NULL DEFAULT 1,
  pank smallint NOT NULL DEFAULT 0,
  aa character varying(16) NOT NULL DEFAULT space(1),
  muud text,
  rekvid integer NOT NULL DEFAULT 0,
  resident integer NOT NULL DEFAULT 1,
  riik character varying(3) NOT NULL DEFAULT space(1),
  toend date,
  vanaid integer,
  vanakoormus numeric(12,4),
  koormus numeric(12,4),
  vanatoopaev integer,
  toopaev numeric(12,4) NOT NULL DEFAULT 0,
  CONSTRAINT tooleping_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=TRUE
);

GRANT ALL ON TABLE libs.tooleping TO vlad;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE libs.tooleping TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT ON TABLE libs.tooleping TO dbkasutaja;
GRANT ALL ON TABLE libs.tooleping TO dbadmin;
GRANT SELECT ON TABLE libs.tooleping TO dbvaatleja;
GRANT SELECT, UPDATE, INSERT ON TABLE libs.tooleping TO dbkasutaja;

-- Index: docs.parentid_idx

-- DROP INDEX docs.parentid_idx;

CREATE INDEX parentid_idx
  ON libs.tooleping
  USING btree
  (parentid);
ALTER TABLE libs.tooleping CLUSTER ON parentid_idx;

-- Index: libs.tooleping_ametid

-- DROP INDEX libs.tooleping_ametid;

CREATE INDEX tooleping_ametid
  ON libs.tooleping
  USING btree
  (ametid);

-- Index: libs.tooleping_osakondid

-- DROP INDEX libs.tooleping_osakondid;

CREATE INDEX tooleping_osakondid
  ON libs.tooleping
  USING btree
  (osakondid);

-- Index: docs."tooleping_rekvId_idx"

-- DROP INDEX docs."tooleping_rekvId_idx";

CREATE INDEX "tooleping_rekvId_idx"
  ON libs.tooleping
  USING btree
  (rekvid);



CREATE TRIGGER trigi_tooleping_before
  BEFORE INSERT
  ON libs.tooleping
  FOR EACH ROW
  EXECUTE PROCEDURE docs.trigi_check_docs_before();

  /*
select * from libs.tooleping

insert into libs.tooleping (parentId, osakondId, ametid, algab, rekvId)
	values (1, 0, 0, date(), 1)
  */
