-- auto-generated definition
CREATE TABLE rekl.luba
(
  id       SERIAL                                             NOT NULL
    CONSTRAINT luba_pkey
    PRIMARY KEY,
  parentid INTEGER                                            NOT NULL,
  asutusid INTEGER                                            NOT NULL,
  rekvid   INTEGER                                            NOT NULL,
  algkpv   DATE DEFAULT date()                                NOT NULL,
  loppkpv  DATE,
  number   VARCHAR(20)                                        NOT NULL,
  summa    NUMERIC(12, 2) DEFAULT 0                           NOT NULL,
  jaak     NUMERIC(12, 2) DEFAULT 0                           NOT NULL,
  volg     NUMERIC(12, 2) DEFAULT 0                           NOT NULL,
  alus     VARCHAR(254) DEFAULT space(1)                      NOT NULL,
  staatus  INTEGER DEFAULT 1                                  NOT NULL,
  muud     TEXT,
  kord     VARCHAR(20) DEFAULT 'KVARTAL' :: CHARACTER VARYING NOT NULL,
  intress  NUMERIC(12, 2) DEFAULT 0                           NOT NULL
);


GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE rekl.luba TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE rekl.luba TO dbadmin;
GRANT SELECT ON TABLE rekl.luba TO dbvaatleja;
GRANT SELECT, UPDATE, INSERT, DELETE, TRIGGER ON TABLE rekl.luba TO dbkasutaja;
