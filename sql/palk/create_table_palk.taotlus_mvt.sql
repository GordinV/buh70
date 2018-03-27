DROP TABLE if exists palk.taotlus_mvt;

CREATE TABLE palk.taotlus_mvt
(
  id serial NOT NULL,
  parentid integer,
  rekvid integer NOT NULL,
  userid integer NOT NULL,
  kpv date NOT NULL,
  alg_kpv date NOT NULL,
  lopp_kpv date NOT NULL,
  lepingid integer NOT NULL,
  summa numeric(14,4) NOT NULL DEFAULT 0,
  muud text

)
WITH (
OIDS=FALSE
);

GRANT ALL ON TABLE palk.taotlus_mvt TO dbkasutaja;
GRANT ALL ON TABLE palk.taotlus_mvt TO dbpeakasutaja;
GRANT select ON TABLE palk.taotlus_mvt TO dbvaatleja;


CREATE INDEX taotlus_mvt_kpv
  ON palk.taotlus_mvt
  USING btree
  (alg_kpv, lopp_kpv);



CREATE INDEX taotlus_mvt_lepingid
  ON palk.taotlus_mvt
  USING btree
  (lepingid);


CREATE INDEX taotlus_mvt_rekvid
  ON palk.taotlus_mvt
  USING btree
  (rekvid);
