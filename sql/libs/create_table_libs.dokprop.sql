DROP TABLE IF EXISTS libs.dokprop;

CREATE TABLE libs.dokprop
(
  id        SERIAL,
  parentid  INTEGER  NOT NULL, -- libs.library (doc types)
  registr   SMALLINT NOT NULL DEFAULT 1, -- konteerimine
  vaatalaus SMALLINT NOT NULL DEFAULT 0,
  selg      TEXT     NOT NULL DEFAULT space(1),
  muud      TEXT,
  asutusid  INTEGER,
  details   JSONB,
  proc_     TEXT,
  tyyp      INTEGER  NOT NULL DEFAULT 1,
  status    INTEGER  NOT NULL DEFAULT 0,
  rekvid    INTEGER,
  CONSTRAINT dokprop_pkey PRIMARY KEY (id)
)
WITH (
OIDS = TRUE
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE libs.dokprop TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE libs.dokprop TO dbkasutaja;
GRANT ALL ON TABLE libs.dokprop TO dbadmin;
GRANT SELECT ON TABLE libs.dokprop TO dbvaatleja;
GRANT SELECT ON TABLE libs.dokprop TO ladukasutaja;

DROP INDEX IF EXISTS libs.dokprop_parentId_idx;

CREATE INDEX dokprop_parentId_idx
  ON libs.dokprop
  USING BTREE
  (parentid);


ALTER TABLE libs.dokprop
  ADD CONSTRAINT dokprop_parent FOREIGN KEY (parentid) REFERENCES libs.library (id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;
COMMENT ON CONSTRAINT dokprop_parent
ON libs.dokprop IS 'Сылка на тип документа';


/*
select *  from libs.library where library = 'DOK'

select * from libs.dokprop

insert into libs.dokprop (parentId, registr, vaatalaus, selg, details) 
	values (1, 1, 1, 'Arved', '{"konto":"103000"}')


*/
  

