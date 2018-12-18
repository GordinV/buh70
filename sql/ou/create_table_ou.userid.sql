-- auto-generated definition
CREATE TABLE ou.userid (
  id           SERIAL                  NOT NULL
    CONSTRAINT userid_pkey
      PRIMARY KEY,
  rekvid       INTEGER                 NOT NULL,
  kasutaja     CHAR(50)                NOT NULL,
  ametnik      CHAR(254)               NOT NULL,
  parool       TEXT,
  kasutaja_    INTEGER   DEFAULT 1     NOT NULL,
  peakasutaja_ INTEGER   DEFAULT 0     NOT NULL,
  admin        INTEGER   DEFAULT 0     NOT NULL,
  muud         TEXT,
  last_login   TIMESTAMP DEFAULT now() NOT NULL,
  properties   JSONB,
  roles        JSONB,
  ajalugu      JSONB,
  status       INTEGER   DEFAULT 0
);

CREATE INDEX userid_rekvid
  ON ou.userid (rekvid, kasutaja);


GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE ou.userid TO dbpeakasutaja;
GRANT SELECT, UPDATE  ON TABLE ou.userid TO dbkasutaja;
GRANT all ON TABLE ou.userid TO dbadmin;
GRANT SELECT, UPDATE ON TABLE ou.userid TO dbvaatleja;


