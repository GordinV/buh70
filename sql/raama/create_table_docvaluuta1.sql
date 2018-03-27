
DROP TABLE if exists docs.dokvaluuta1;

CREATE TABLE docs.dokvaluuta1
(
  id serial,
  dokid integer NOT NULL,
  dokliik integer NOT NULL,
  valuuta character varying(20) NOT NULL DEFAULT space(1),
  kuurs numeric(14,4) DEFAULT 1,
  muud text,
  CONSTRAINT dokvaluuta1_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=TRUE
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.dokvaluuta1 TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT ON TABLE docs.dokvaluuta1 TO dbkasutaja;
GRANT ALL ON TABLE docs.dokvaluuta1 TO dbadmin;
GRANT SELECT ON TABLE docs.dokvaluuta1 TO dbvaatleja;


CREATE INDEX dokvaluuta1_idx1
  ON docs.dokvaluuta1
  USING btree
  (dokid, dokliik);

