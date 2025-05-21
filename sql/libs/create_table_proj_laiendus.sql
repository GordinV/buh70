DROP TABLE if exists libs.proj_laiendus;

CREATE TABLE libs.proj_laiendus
(
    id            serial,
    rekvid        integer NOT NULL,
    proj_id       integer NOT NULL,
    leping_id       integer NOT NULL,
    summa         numeric default 0,
    kasutatud     numeric default 0,
    korrigeerimine numeric default 0,
    jaak          numeric default 0,
    properties    jsonb,
    CONSTRAINT proj_laiendus_pkey PRIMARY KEY (id),
    constraint reference_proj foreign key (proj_id) references libs.library (id) on update cascade on delete restrict,
    constraint reference_leping_id foreign key (leping_id) references palk.tooleping (id) on update cascade on delete restrict

);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE libs.proj_laiendus TO dbpeakasutaja;
GRANT ALL ON TABLE libs.proj_laiendus TO dbadmin;
GRANT SELECT ON TABLE libs.proj_laiendus TO dbvaatleja;
GRANT SELECT ON TABLE libs.proj_laiendus TO taabel;
GRANT SELECT, UPDATE, INSERT ON TABLE libs.proj_laiendus TO dbkasutaja;

-- Index: libs.asutus_nimetus

-- DROP INDEX libs.asutus_nimetus;

CREATE INDEX proj_laiendus_leping_id
    ON libs.proj_laiendus
        USING btree
        (leping_id);

CREATE INDEX proj_laiendus_proj_id
    ON libs.proj_laiendus
        USING btree
        (proj_id);

alter table libs.proj_laiendus
    add column if not exists kuu_summa numeric default 0;

alter table libs.proj_laiendus
    add column if not exists sm numeric default 0;

alter table libs.proj_laiendus
    add column if not exists sm_kasutatud numeric default 0;

alter table libs.proj_laiendus
    add column if not exists selgitus text;
