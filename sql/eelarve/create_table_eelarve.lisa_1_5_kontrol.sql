DROP TABLE IF EXISTS eelarve.lisa_1_5_kontrol;

CREATE TABLE eelarve.lisa_1_5_kontrol (
    id                 SERIAL    NOT NULL,
    nimetus            CHARACTER VARYING,
    eelarve            NUMERIC,
    eelarve_kassa      NUMERIC,
    eelarve_taps       NUMERIC,
    eelarve_kassa_taps NUMERIC,
    kassa              NUMERIC,
    saldoandmik        NUMERIC,
    idx                INTEGER,
    kpv                DATE      NOT NULL,
    rekv_id            INTEGER,
    TIMESTAMP          TIMESTAMP NOT NULL DEFAULT now()
)
    WITH (OIDS= FALSE);


GRANT SELECT ON TABLE eelarve.lisa_1_5_kontrol TO dbvaatleja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE eelarve.lisa_1_5_kontrol TO saldoandmikkoostaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE eelarve.lisa_1_5_kontrol TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT ON TABLE eelarve.lisa_1_5_kontrol TO dbkasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE eelarve.lisa_1_5_kontrol TO eelaktsepterja;


GRANT ALL ON SEQUENCE eelarve.lisa_1_5_kontrol_id_seq TO dbadmin;
GRANT SELECT, USAGE ON SEQUENCE eelarve.lisa_1_5_kontrol_id_seq TO dbkasutaja;
GRANT SELECT, USAGE ON SEQUENCE eelarve.lisa_1_5_kontrol_id_seq TO dbpeakasutaja;
GRANT SELECT, USAGE ON SEQUENCE eelarve.lisa_1_5_kontrol_id_seq TO dbvaatleja;
GRANT ALL ON SEQUENCE eelarve.lisa_1_5_kontrol_id_seq TO eelaktsepterja;
GRANT ALL ON SEQUENCE eelarve.lisa_1_5_kontrol_id_seq TO eelallkirjastaja;
GRANT ALL ON SEQUENCE eelarve.lisa_1_5_kontrol_id_seq TO eelesitaja;
GRANT ALL ON SEQUENCE eelarve.lisa_1_5_kontrol_id_seq TO eelkoostaja;
GRANT ALL ON SEQUENCE eelarve.lisa_1_5_kontrol_id_seq TO vlad;

-- Index: ix_saldoandmik_period

-- DROP INDEX ix_saldoandmik_period;

CREATE INDEX idx_lisa_1_5_kontrol_kpv
    ON eelarve.lisa_1_5_kontrol
        USING btree
        (kpv);

CREATE INDEX idx_lisa_1_5_kontrol_rekv_id
    ON eelarve.lisa_1_5_kontrol
        USING btree
        (rekv_id);

