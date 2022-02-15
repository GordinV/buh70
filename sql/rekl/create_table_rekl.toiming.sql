-- auto-generated definition
DROP TABLE IF EXISTS rekl.toiming;

CREATE TABLE rekl.toiming
(
  id           SERIAL                        NOT NULL
    CONSTRAINT toiming_pkey
    PRIMARY KEY,
  parentid     INTEGER                       NOT NULL,
  asutusid     INTEGER                       NOT NULL,
  lubaid       INTEGER                       NOT NULL,
  journalid    INTEGER,
  kpv          DATE DEFAULT date()           NOT NULL,
  userid       INTEGER                       NOT NULL,
  alus         TEXT,
  ettekirjutus TEXT,
  tahtaeg      DATE    DEFAULT date(),
  summa        NUMERIC(12, 2) DEFAULT 0      NOT NULL,
  staatus      DOK_STATUS                    NOT NULL,
  tyyp         REKL_TOIMING_LIIK             NOT NULL,
  muud         TEXT,
  failid       INTEGER,
  dokpropid    INTEGER,
  saadetud     DATE,
  number       INTEGER DEFAULT 0,
  deklid       INTEGER,
  lisa jsonb
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE rekl.toiming TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE rekl.toiming TO dbadmin;
GRANT SELECT ON TABLE rekl.toiming TO dbvaatleja;
GRANT SELECT, UPDATE, INSERT, DELETE, TRIGGER ON TABLE rekl.toiming TO dbkasutaja;


CREATE INDEX idx_toiming_parentid
  ON rekl.toiming (parentid);
CREATE INDEX idx_toiming_asutusid
  ON rekl.toiming (asutusid);
CREATE INDEX idx_toiming_lubaid
  ON rekl.toiming (lubaid);
CREATE INDEX idx_toiming_journalid
  ON rekl.toiming (journalid);


CREATE OR REPLACE FUNCTION rekl.trigiu_toiming_after()
  RETURNS TRIGGER AS
$BODY$
DECLARE
  l_params JSON;
BEGIN
  SELECT row_to_json(row)
  INTO l_params
  FROM (SELECT new.lubaid AS id) row;
  PERFORM rekl.sp_recalc_rekl_jaak(new.userid, l_params);

  RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION rekl.trigiu_toiming_after() TO dbkasutaja;
GRANT EXECUTE ON FUNCTION rekl.trigiu_toiming_after() TO dbpeakasutaja;


CREATE TRIGGER trigiu_toiming_after
AFTER INSERT OR UPDATE
  ON rekl.toiming
FOR EACH ROW
EXECUTE PROCEDURE rekl.trigiu_toiming_after();
