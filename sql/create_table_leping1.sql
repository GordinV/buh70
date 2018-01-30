drop table if exists docs.leping1;

CREATE TABLE docs.leping1
(
  id serial NOT NULL,
  parentid integer NOT NULL,
  asutusid integer NOT NULL,
  rekvid integer NOT NULL,
  doklausid integer NOT NULL,
  "number" character(20) NOT NULL,
  kpv date NOT NULL,
  tahtaeg date,
  selgitus text NOT NULL DEFAULT space(1),
  dok text,
  muud text,
  pakettid integer,
  objektid integer,
  CONSTRAINT leping1_pkey PRIMARY KEY (id)
)
WITH (OIDS=TRUE);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE leping1 TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT ON TABLE leping1 TO dbkasutaja;
GRANT ALL ON TABLE leping1 TO dbadmin;
GRANT SELECT ON TABLE leping1 TO dbvaatleja;


DROP INDEX if exists leping1_parentid;

CREATE INDEX leping1_parentid
  ON docs.leping1
  USING btree
  (parentid);

DROP INDEX if exists leping1_asutusid;

CREATE INDEX leping1_asutusid
  ON docs.leping1
  USING btree
  (asutusid);

DROP INDEX if exists leping1_rekvid;

CREATE INDEX leping1_rekvid
  ON docs.leping1
  USING btree
  (rekvid);

drop view if exists cur_lepingud;

CREATE OR REPLACE VIEW cur_lepingud AS
  SELECT d.id, l.rekvid, l.number, l.kpv, l.tahtaeg,
    l.selgitus::varchar(254) AS selgitus,
    (ltrim(rtrim(a.nimetus)) + space(1) + ltrim(rtrim(a.omvorm)))::varchar(254) AS asutus,
    l.asutusid AS asutusid, coalesce(objekt.kood, space(20))::character varying(20) AS objkood,
    coalesce(objekt.nimetus, space(254))::character varying AS objnimi,
    coalesce(obj.nait14, 0)::numeric AS maja,
    coalesce(obj.nait15, 0)::numeric AS korter,
    coalesce(pakett.kood, space(20))::character varying AS pakett
  FROM docs.doc d
    JOIN docs.leping1 l on l.parentid = d.id
    JOIN libs.asutus a ON l.asutusid = a.id
    LEFT JOIN libs.library objekt ON objekt.id = l.objektid
    LEFT JOIN libs.objekt obj ON objekt.id = obj.parentid
    LEFT JOIN libs.library pakett ON pakett.id = l.pakettid;

GRANT SELECT ON TABLE cur_lepingud TO dbpeakasutaja;
GRANT SELECT ON TABLE cur_lepingud TO dbkasutaja;
GRANT ALL ON TABLE cur_lepingud TO dbadmin;
GRANT SELECT ON TABLE cur_lepingud TO dbvaatleja;


