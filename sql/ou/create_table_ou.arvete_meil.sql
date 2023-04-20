DROP TABLE IF EXISTS ou.arvete_meil;

CREATE TABLE ou.arvete_meil
(
    id       SERIAL                                         NOT NULL
        CONSTRAINT arvete_meil_pkey
            PRIMARY KEY,
    rekvid   INTEGER                                        NOT NULL,
    user_id   INTEGER                                        NOT NULL,
    kas_alusta BOOLEAN not null default false,
    alg_kpv date,
    lopp_kpv date,
    ajalugu  JSONB,
    muud text
);

CREATE INDEX arvete_meil_rekvid
    ON ou.arvete_meil (rekvid);

CREATE UNIQUE INDEX arvete_meil_period
    ON ou.arvete_meil (rekvid, alg_kpv, lopp_kpv);

alter TABLE ou.arvete_meil add COLUMN if not exists muud text;

alter TABLE ou.arvete_meil add COLUMN if not exists alusta_ametnik integer,
    add COLUMN if not exists kas_alusta_timestamp TIMESTAMP ;

alter TABLE ou.arvete_meil add column if not exists paus BOOLEAN default false not null;

alter TABLE ou.arvete_meil add column if not exists paus_ametnik integer, add column if not exists paus_timestamp timestamp;



GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE ou.arvete_meil TO dbpeakasutaja;
GRANT SELECT, INSERT ON TABLE ou.arvete_meil TO dbkasutaja;
GRANT all ON TABLE ou.arvete_meil TO dbadmin;
GRANT SELECT ON TABLE ou.arvete_meil TO dbvaatleja;
GRANT SELECT ON TABLE ou.arvete_meil TO PUBLIC ;


/*
 select * from ou.arvete_meil
insert into ou.arvete_meil (rekvid, user_id, kas_alusta, alg_kpv, lopp_kpv)
values (63, 2477, true, '2023-03-01', '2023-03-31')

 */
