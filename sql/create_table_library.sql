DROP TABLE if exists libs.library;

CREATE TABLE libs.library
(
  id serial,
  rekvid integer NOT NULL,
  kood character(20) NOT NULL DEFAULT space(1),
  nimetus character(254) NOT NULL DEFAULT space(1),
  library character(20) NOT NULL DEFAULT space(1),
  muud text,
  tun1 integer NOT NULL DEFAULT 0,
  tun2 integer NOT NULL DEFAULT 0,
  tun3 integer NOT NULL DEFAULT 0,
  tun4 integer NOT NULL DEFAULT 0,
  tun5 integer NOT NULL DEFAULT 0,
  vanaid integer,
  properties jsonb,
  CONSTRAINT library_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=TRUE
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE libs.library TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT ON TABLE libs.library TO dbkasutaja;
GRANT ALL ON TABLE libs.library TO dbadmin;
GRANT SELECT ON TABLE libs.library TO dbvaatleja;

-- Index: libs.library_kood

-- DROP INDEX libs.library_kood;

CREATE INDEX library_kood
  ON libs.library
  USING btree
  (kood COLLATE pg_catalog."default");

-- Index: libs.library_library

-- DROP INDEX libs.library_library;

CREATE INDEX library_library
  ON libs.library
  USING btree
  (library COLLATE pg_catalog."default");

-- Index: libs.library_rekvid

-- DROP INDEX libs.library_rekvid;

CREATE INDEX library_rekvid
  ON libs.library
  USING btree
  (rekvid);
ALTER TABLE libs.library CLUSTER ON library_rekvid;


ALTER TABLE libs.library
  ADD COLUMN "timestamp" timestamp without time zone NOT NULL DEFAULT LOCALTIMESTAMP;


ALTER TABLE libs.library
  ADD COLUMN status integer NOT NULL DEFAULT 1;
COMMENT ON COLUMN libs.library.status
IS '0 - draft, 1 - active, 2 - ?, 3 - deleted';

/*

select * from libs.library where library = 'DOK'
insert into libs.library (rekvId, kood, nimetus, library )
	values (1, '2', '', 'STATUS')

select * from libs.library

update libs.library set 
	properties = 'gridConfiguration: [{id: "id", name: "id", width: "50px"},{id: "number", name: "number", width: "100px"},{id: "kpv", name: "Kuupaev", width: "100px"}],
		sqlString: "select d.id, a.number, a.kpv  from docs.doc d inner join docs.arv a on a.parentId = d.id ",
		params:""}'
            where id = 1

select properties from library where id = 1

*/