-- auto-generated definition
CREATE TABLE rekl.luba1
(
  id          SERIAL                   NOT NULL
    CONSTRAINT luba1_pkey
    PRIMARY KEY,
  parentid    INTEGER                  NOT NULL,
  nomid       INTEGER                  NOT NULL,
  kogus       NUMERIC(12, 2) DEFAULT 0 NOT NULL,
  maksumaar   NUMERIC(12, 2) DEFAULT 0 NOT NULL,
  soodus_tyyp SMALLINT,
  soodus      NUMERIC(12, 2),
  summa       NUMERIC(12, 2) DEFAULT 0 NOT NULL,
  staatus     INTEGER DEFAULT 1        NOT NULL,
  muud        TEXT
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE rekl.luba1 TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE rekl.luba1 TO dbkasutaja;
GRANT ALL ON TABLE rekl.luba1 TO dbadmin;
GRANT SELECT ON TABLE rekl.luba1 TO dbvaatleja;

ALTER TABLE rekl.luba1
  ADD CONSTRAINT "luba_rekl.luba1_parentid_fk"
FOREIGN KEY (parentid) REFERENCES rekl.luba (id)
ON DELETE CASCADE ON UPDATE CASCADE;