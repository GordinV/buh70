DROP TABLE IF EXISTS libs.library;

CREATE TABLE libs.library (
    id         SERIAL,
    rekvid     INTEGER        NOT NULL,
    kood       CHARACTER(20)  NOT NULL DEFAULT space(1),
    nimetus    CHARACTER(254) NOT NULL DEFAULT space(1),
    library    CHARACTER(20)  NOT NULL DEFAULT space(1),
    muud       TEXT,
    tun1       INTEGER        NOT NULL DEFAULT 0,
    tun2       INTEGER        NOT NULL DEFAULT 0,
    tun3       INTEGER        NOT NULL DEFAULT 0,
    tun4       INTEGER        NOT NULL DEFAULT 0,
    tun5       INTEGER        NOT NULL DEFAULT 0,
    vanaid     INTEGER,
    properties JSONB,
    CONSTRAINT library_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE libs.library TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT ON TABLE libs.library TO dbkasutaja;
GRANT ALL ON TABLE libs.library TO dbadmin;
GRANT SELECT ON TABLE libs.library TO dbvaatleja;

-- Index: libs.library_kood

-- DROP INDEX libs.library_kood;

CREATE INDEX library_kood
    ON libs.library
        USING btree
        (kood COLLATE pg_catalog."default");

-- Index: libs.library_library

-- DROP INDEX libs.library_library;

CREATE INDEX library_library
    ON libs.library
        USING btree
        (library COLLATE pg_catalog."default");

-- Index: libs.library_rekvid

-- DROP INDEX libs.library_rekvid;

CREATE INDEX library_rekvid
    ON libs.library
        USING btree
        (rekvid);
ALTER TABLE libs.library
    CLUSTER ON library_rekvid;

CREATE INDEX library_status
    ON libs.library
        USING btree
        (status)
    WHERE status <> 3;
ALTER TABLE libs.library
    CLUSTER ON library_rekvid;


CREATE INDEX library_pv_gruppid
    ON libs.library
        USING gin
        ((properties::JSONB -> gruppid));

DROP INDEX IF EXISTS library_docs_modules;
CREATE INDEX library_docs_modules
    ON libs.library ((properties :: JSONB ->> 'module'))
    WHERE library = 'DOK';


--ALTER TABLE libs.library CLUSTER ON library_rekvid;

DROP INDEX IF EXISTS libs.library_idx_cluster_library;

CREATE INDEX library_idx_cluster_library
    ON libs.library USING btree
        (library)
--  INCLUDE(library)
--  TABLESPACE pg_default
--    where status <> 3
;

drop index if exists libs.library_idx_lapse_grupp;

CREATE INDEX library_idx_lapse_grupp
    ON libs.library USING btree
        (id)
    WHERE status <> 3 AND library::text = 'LAPSE_GRUPP'::text
;



ALTER TABLE libs.library
    CLUSTER ON library_idx_cluster_library;



ALTER TABLE libs.library
    ADD COLUMN "timestamp" TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT LOCALTIMESTAMP;


ALTER TABLE libs.library
    ADD COLUMN status INTEGER NOT NULL DEFAULT 1;
COMMENT ON COLUMN libs.library.status
    IS '0 - draft, 1 - active, 2 - ?, 3 - deleted';

/*

select * from libs.library where library = 'DOK'
insert into libs.library (rekvId, kood, nimetus, library )
	values (1, '2', '', 'STATUS')

select * from libs.library

update libs.library set 
	properties = 'gridConfiguration: [{id: "id", name: "id", width: "50px"},{id: "number", name: "number", width: "100px"},{id: "kpv", name: "Kuupaev", width: "100px"}],
		sqlString: "select d.id, a.number, a.kpv  from docs.doc d inner join docs.arv a on a.parentId = d.id ",
		params:""}'
            where id = 1

select properties from library where id = 1

*/