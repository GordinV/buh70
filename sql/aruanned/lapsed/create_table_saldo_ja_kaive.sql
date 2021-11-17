CREATE TABLE lapsed.saldo_ja_kaive (
    id              BIGINT,
    period          DATE,
    kulastatavus    TEXT,
    lapse_nimi      TEXT,
    lapse_isikukood TEXT,
    yksus           TEXT,
    viitenumber     TEXT,
    alg_saldo       NUMERIC(14, 4),
    arvestatud      NUMERIC(14, 4),
    soodustus       NUMERIC(14, 4),
    laekumised      NUMERIC(14, 4),
    mahakantud      NUMERIC(14, 4),
    tagastused      NUMERIC(14, 4),
    jaak            NUMERIC(14, 4),
    rekvid          INTEGER,
    created         TIMESTAMP DEFAULT now(),
    params          JSONB
);


GRANT all ON TABLE lapsed.saldo_ja_kaive TO arvestaja;

drop INDEX if EXISTS sald_ja_kaive_uniq_idx;
create INDEX sald_ja_kaive_uniq_idx on lapsed.saldo_ja_kaive (rekvid, (params->>'kpv_start'), (params->>'kpv_end'))

