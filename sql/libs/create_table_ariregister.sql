-- Локальная копия открытых данных Äriregister (RIK) для ежедневной синхронизации и поиска по regkood.
CREATE TABLE IF NOT EXISTS libs.ariregister
(
    regkood                 TEXT PRIMARY KEY,
    nimi                    TEXT        NOT NULL,
    oiguslik_vorm           TEXT,
    oigusliku_vormi_alaliik TEXT,
    kmkr_nr                 TEXT,
    staatus                 TEXT,
    staatus_tekst           TEXT,
    esmakande_kpv           DATE,
    aadress                 TEXT,
    asukoht                 TEXT,
    ehak_kood               TEXT,
    ehak_tekst              TEXT,
    indeks                  TEXT,
    ads_adr_id              TEXT,
    ads_ads_oid             TEXT,
    taisaadress             TEXT,
    link                    TEXT,
    file_date               DATE,
    loaded_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at              TIMESTAMPTZ NULL
);

CREATE INDEX IF NOT EXISTS idx_ariregister_kmkr_nr
    ON libs.ariregister (kmkr_nr)
    WHERE kmkr_nr IS NOT NULL;

GRANT SELECT, INSERT, UPDATE, DELETE ON libs.ariregister TO dbkasutaja;
GRANT SELECT, INSERT, UPDATE, DELETE ON libs.ariregister TO dbpeakasutaja;

-- Буферная таблица без ограничений для быстрой загрузки CSV (очистка через DELETE перед каждой загрузкой).
CREATE UNLOGGED TABLE IF NOT EXISTS libs.ariregister_stage
(
    regkood                 TEXT,
    nimi                    TEXT,
    oiguslik_vorm           TEXT,
    oigusliku_vormi_alaliik TEXT,
    kmkr_nr                 TEXT,
    staatus                 TEXT,
    staatus_tekst           TEXT,
    esmakande_kpv           DATE,
    aadress                 TEXT,
    asukoht                 TEXT,
    ehak_kood               TEXT,
    ehak_tekst              TEXT,
    indeks                  TEXT,
    ads_adr_id              TEXT,
    ads_ads_oid             TEXT,
    taisaadress             TEXT,
    link                    TEXT,
    file_date               DATE,
    loaded_at               TIMESTAMPTZ,
    deleted_at              TIMESTAMPTZ
);

GRANT SELECT, INSERT, UPDATE, DELETE ON libs.ariregister_stage TO dbkasutaja;
GRANT SELECT, INSERT, UPDATE, DELETE ON libs.ariregister_stage TO dbpeakasutaja;

-- Метаданные последней успешной выгрузки Äriregister (одна строка id = 1).
CREATE TABLE IF NOT EXISTS libs.ariregister_meta
(
    id         INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    file_date  DATE,
    applied_at TIMESTAMPTZ,
    rows_total INTEGER
);

GRANT SELECT, INSERT, UPDATE, DELETE ON libs.ariregister_meta TO dbkasutaja;
GRANT SELECT, INSERT, UPDATE, DELETE ON libs.ariregister_meta TO dbpeakasutaja;
