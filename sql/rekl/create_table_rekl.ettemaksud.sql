-- auto-generated definition
DROP TABLE IF EXISTS ekl.ettemaksud;

CREATE TABLE rekl.ettemaksud
(
  id        SERIAL                   NOT NULL,
  rekvid    INTEGER                  NOT NULL,
  kpv       DATE                     NOT NULL,
  summa     NUMERIC(18, 6) DEFAULT 0 NOT NULL,
  number    INTEGER DEFAULT 0        NOT NULL,
  asutusid  INTEGER                  NOT NULL,
  dokid     INTEGER                  NULL,
  doktyyp   REKL_ETTEMAKS_LIIK       NOT NULL,
  selg      TEXT,
  muud      TEXT,
  staatus   DOK_STATUS               NOT NULL,
  journalid INTEGER                  NULL
);
