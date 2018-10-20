drop table if exists ou.config;

CREATE TABLE ou.config
(
  id        SERIAL                                                                                        NOT NULL
    CONSTRAINT config__pkey
    PRIMARY KEY,
  rekvid    INTEGER                                                                                       NOT NULL,
  keel      INTEGER DEFAULT 1                                                                             NOT NULL,
  toolbar1  INTEGER DEFAULT 0                                                                             NOT NULL,
  toolbar2  INTEGER DEFAULT 0                                                                             NOT NULL,
  toolbar3  INTEGER DEFAULT 0                                                                             NOT NULL,
  number    VARCHAR(20) DEFAULT space(1)                                                                  NOT NULL,
  arvround  NUMERIC(5, 2) DEFAULT 0.1                                                                     NOT NULL,
  viga      VARCHAR(254) DEFAULT 'raama.vigad@avpsoft.ee' :: CHARACTER VARYING                            NOT NULL,
  www       VARCHAR(254) DEFAULT 'http://www.avpsoft.ee/downloads/buh50/uuendus.dbf' :: CHARACTER VARYING NOT NULL,
  asutusid  INTEGER DEFAULT 0                                                                             NOT NULL,
  tahtpaev  INTEGER      DEFAULT 0,
  www1      VARCHAR(254) DEFAULT '' :: CHARACTER VARYING,
  dokprop1  INTEGER      DEFAULT 0,
  dokprop2  INTEGER      DEFAULT 0,
  propertis JSONB
);


GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE ou.config TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT ON TABLE ou.config TO dbkasutaja;
GRANT all ON TABLE ou.config TO dbadmin;
GRANT SELECT ON TABLE ou.config TO dbvaatleja;


insert into ou.config (rekvid, keel)
  select id, 2 from ou.rekv where parentid < 999

/*
select * from ou.config
 */