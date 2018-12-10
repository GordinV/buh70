DROP TABLE IF EXISTS ou.aasta;

CREATE TABLE ou.aasta
(
  id       SERIAL                                         NOT NULL
    CONSTRAINT aasta_pkey
    PRIMARY KEY,
  rekvid   INTEGER                                        NOT NULL,
  aasta    SMALLINT DEFAULT year(('now' :: TEXT) :: DATE) NOT NULL,
  kuu      SMALLINT DEFAULT 1                             NOT NULL,
  kinni    SMALLINT DEFAULT 0                             NOT NULL,
  default_ SMALLINT DEFAULT 0                             NOT NULL,
  ajalugu  JSONB
);

CREATE INDEX aasta_rekvid
  ON ou.aasta (rekvid);



GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE ou.aasta TO dbpeakasutaja;
GRANT SELECT, INSERT ON TABLE ou.aasta TO dbkasutaja;
GRANT all ON TABLE ou.aasta TO dbadmin;
GRANT SELECT ON TABLE ou.aasta TO dbvaatleja;
GRANT SELECT ON TABLE ou.aasta TO PUBLIC ;



