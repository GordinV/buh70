DROP TABLE if exists libs.dokprop;

CREATE TABLE libs.dokprop
(
  id serial,
  parentid integer NOT NULL, -- libs.library (doc types)
  registr smallint NOT NULL DEFAULT 1, -- konteerimine
  vaatalaus smallint NOT NULL DEFAULT 0, 
  selg text NOT NULL DEFAULT space(1),
  muud text,
  asutusid integer NOT NULL DEFAULT 0,
  details jsonb,
  proc_ text,
  tyyp integer NOT NULL DEFAULT 1,
  CONSTRAINT dokprop_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=TRUE
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE libs.dokprop TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE libs.dokprop TO dbkasutaja;
GRANT ALL ON TABLE libs.dokprop TO dbadmin;
GRANT SELECT ON TABLE libs.dokprop TO dbvaatleja;
GRANT SELECT ON TABLE libs.dokprop TO ladukasutaja;

DROP INDEX if exists libs.dokprop_parentId_idx;

CREATE INDEX dokprop_parentId_idx
  ON libs.dokprop
  USING btree
  (parentid);


ALTER TABLE libs.dokprop ADD CONSTRAINT dokprop_parent FOREIGN KEY (parentid) REFERENCES libs.library (id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;
COMMENT ON CONSTRAINT dokprop_parent ON libs.dokprop IS 'Сылка на тип документа';


/*
select *  from libs.library where library = 'DOK'

select * from libs.dokprop

insert into libs.dokprop (parentId, registr, vaatalaus, selg, details) 
	values (1, 1, 1, 'Arved', '{"konto":"103000"}')


*/
  

