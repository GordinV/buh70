DROP TABLE IF EXISTS docs.pv_oper;

CREATE TABLE docs.pv_oper (
    id          SERIAL,
    parentid    INTEGER               NOT NULL,
    pv_kaart_id INTEGER               NOT NULL,
    nomid       INTEGER,
    liik        INTEGER               NOT NULL DEFAULT 0,
    kpv         DATE                  NOT NULL DEFAULT ('now'::TEXT)::DATE,
    summa       NUMERIC(12, 4)        NOT NULL DEFAULT 0,
    muud        TEXT,
    kood1       CHARACTER VARYING(20) NOT NULL DEFAULT space(20),
    kood2       CHARACTER VARYING(20) NOT NULL DEFAULT space(20),
    kood3       CHARACTER VARYING(20) NOT NULL DEFAULT space(20),
    kood4       CHARACTER VARYING(20) NOT NULL DEFAULT space(20),
    kood5       CHARACTER VARYING(20) NOT NULL DEFAULT space(20),
    konto       CHARACTER VARYING(20) NOT NULL DEFAULT space(20),
    tp          CHARACTER VARYING(20) NOT NULL DEFAULT space(20),
    asutusid    INTEGER               NOT NULL DEFAULT 0,
    tunnus      CHARACTER VARYING(20) NOT NULL DEFAULT space(20),
    proj        CHARACTER VARYING(20) NOT NULL DEFAULT space(1),
    CONSTRAINT pv_oper_pkey PRIMARY KEY (id)
);

ALTER TABLE docs.pv_oper
    ALTER COLUMN nomid DROP NOT NULL;

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.pv_oper TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT ON TABLE docs.pv_oper TO dbkasutaja;
GRANT ALL ON TABLE docs.pv_oper TO dbadmin;
GRANT SELECT ON TABLE public.pv_oper TO dbvaatleja;

CREATE INDEX pv_oper_parentid_idx
    ON docs.pv_oper
        USING btree
        (parentid);

CREATE INDEX pv_oper_kaart_id_idx
    ON docs.pv_oper
        USING btree
        (pv_kaart_id);

CREATE INDEX pv_oper_nomid_idx
    ON docs.pv_oper
        USING btree
        (nomid);


CREATE INDEX pv_oper_journalid_idx
    ON docs.pv_oper USING btree (journalid);

CREATE TRIGGER trigi_pv_oper_before
    BEFORE INSERT
    ON docs.pv_oper
    FOR EACH ROW
EXECUTE PROCEDURE docs.trigi_check_docs_before();


ALTER TABLE docs.pv_oper add COLUMN if not exists properties jsonb;

/*
select * from docs.pv_oper

insert into docs.pv_oper (pv_kaart_id, nomid, liik, kpv, summa, asutusId)
	values (1, 1, 1, date(), 100, 1)
*/