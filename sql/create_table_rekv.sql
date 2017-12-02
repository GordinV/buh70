
CREATE TABLE ou.rekv
(
  id serial,
  parentid integer,
  regkood character(20) NOT NULL,
  nimetus text NOT NULL,
  kbmkood character(20),
  aadress text,
  haldus text,
  tel text,
  faks text,
  email text,
  juht text,
  raama text,
  muud text,
  CONSTRAINT rekv_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=TRUE
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE ou.rekv TO dbpeakasutaja;
GRANT SELECT, UPDATE  ON TABLE ou.rekv TO dbkasutaja;
GRANT ALL ON TABLE ou.rekv TO dbadmin;
GRANT SELECT ON TABLE ou.rekv TO dbvaatleja;



