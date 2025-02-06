drop EXTENSION postgres_fdw  CASCADE ;

CREATE EXTENSION postgres_fdw;

CREATE SERVER dbuus_narva_ee FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '80.235.127.119', dbname 'db', port '5438');

--CREATE SERVER test_narva_ee FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '213.184.47.198', dbname 'narvalv', port '5436');


CREATE USER MAPPING FOR vlad
SERVER dbuus_narva_ee
OPTIONS (user 'vlad', password 'Vlad490710');

/*CREATE USER MAPPING FOR vlad
  SERVER dbarch_narva_ee
  OPTIONS (user 'vlad', password 'Vlad490710');
*/


CREATE FOREIGN TABLE remote_doc (
    id integer ,
    created timestamp,
    lastupdate timestamp,
    doc_type_id integer,
    bpm jsonb,
    history jsonb,
    status integer DEFAULT 0,
    docs_ids integer[],
    rigths jsonb,
    rekvid integer
)
SERVER dbuus_narva_ee
OPTIONS (schema_name 'docs', table_name 'doc');

CREATE FOREIGN TABLE remote_pv_oper (
    id integer ,
    parentid integer ,
    pv_kaart_id integer,
    nomid integer,
    liik integer,
    kpv date,
    summa numeric(12,4),
    muud text ,
    kood1 character varying(20) ,
    kood2 character varying(20) ,
    kood3 character varying(20) ,
    kood4 character varying(20),
    kood5 character varying(20),
    konto character varying(20),
    tp character varying(20),
    asutusid integer ,
    tunnus character varying(20),
    proj character varying(20),
    journalid integer,
    doklausid integer,
    properties jsonb
    )
    SERVER dbuus_narva_ee
    OPTIONS (schema_name 'docs', table_name 'pv_oper');



/*select * from remote_pv_oper
         where pv_kaart_id =203305
         limit 10
*/
