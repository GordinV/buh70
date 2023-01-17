DROP TABLE IF EXISTS palk.palk_config;
-- auto-generated definition
CREATE TABLE palk.palk_config (
    id         SERIAL                      NOT NULL
        CONSTRAINT palk_config_pkey
            PRIMARY KEY,
    rekvid     INTEGER                     NOT NULL,
    minpalk    NUMERIC(12, 4) DEFAULT 0    NOT NULL,
    tulubaas   NUMERIC(12, 4) DEFAULT 0    NOT NULL,
    round      NUMERIC(12, 4) DEFAULT 0.01 NOT NULL,
    jaak       SMALLINT       DEFAULT 0    NOT NULL,
    genlausend INTEGER        DEFAULT 1,
    suurasu    INTEGER        DEFAULT 0,
    tm         NUMERIC(14, 2),
    pm         NUMERIC(14, 2),
    tka        NUMERIC(14, 2),
    tki        NUMERIC(14, 2),
    sm         NUMERIC(14, 2),
    muud1      NUMERIC(14, 2),
    muud2      NUMERIC(14, 2),
    ajalugu    JSONB,
    properties JSONB,
    timestamp  TIMESTAMP,
    status     DOK_STATUS                  NOT NULL DEFAULT 'active'
);

CREATE INDEX ix_palk_config
    ON palk.palk_config (rekvid);

ALTER TABLE palk.palk_config
    ADD COLUMN IF NOT EXISTS pensionari_tulubaas NUMERIC(12, 2) DEFAULT 704 NOT NULL; 
