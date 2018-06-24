DROP TABLE IF EXISTS rekl.dekltasu;

CREATE TABLE rekl.dekltasu
(
  id       SERIAL         NOT NULL
    CONSTRAINT dekltasu_pkey
    PRIMARY KEY,
  deklid   INTEGER        NOT NULL,
  tasuid   INTEGER        NOT NULL,
  tasukpv  DATE           NOT NULL,
  volgkpv  INTEGER        NOT NULL,
  summa    NUMERIC(18, 6) NOT NULL,
  asutusid INTEGER        NOT NULL
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE rekl.dekltasu TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT ON TABLE rekl.dekltasu TO dbkasutaja;
GRANT ALL ON TABLE rekl.dekltasu TO dbadmin;
GRANT SELECT ON TABLE rekl.dekltasu TO dbvaatleja;
