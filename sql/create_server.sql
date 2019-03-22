CREATE EXTENSION postgres_fdw;

CREATE SERVER dbarch_narva_ee FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '213.184.47.198', dbname 'narvalv', port '5436');

CREATE USER MAPPING FOR vlad
SERVER db_narva_ee
OPTIONS (user 'vlad', password 'Vlad490710');

CREATE USER MAPPING FOR vlad
  SERVER dbarch_narva_ee
  OPTIONS (user 'vlad', password 'Vlad490710');


/*
CREATE FOREIGN TABLE remote_objekt (
  id serial NOT NULL,
  libid integer NOT NULL,
  asutusid integer NOT NULL,
  parentid integer NOT NULL,
  nait01 numeric(14,4) NOT NULL DEFAULT 0,
  nait02 numeric(14,4) NOT NULL DEFAULT 0,
  nait03 numeric(14,4) NOT NULL DEFAULT 0,
  nait04 numeric(14,4) NOT NULL DEFAULT 0,
  nait05 numeric(14,4) NOT NULL DEFAULT 0,
  nait06 numeric(14,4) NOT NULL DEFAULT 0,
  nait07 numeric(14,4) NOT NULL DEFAULT 0,
  nait08 numeric(14,4) NOT NULL DEFAULT 0,
  nait09 numeric(14,4) NOT NULL DEFAULT 0,
  nait10 numeric(14,4) NOT NULL DEFAULT 0,
  nait11 numeric(14,4) NOT NULL DEFAULT 0,
  nait12 numeric(14,4) NOT NULL DEFAULT 0,
  nait13 numeric(14,4) NOT NULL DEFAULT 0,
  nait14 numeric(14,4) NOT NULL DEFAULT 0,
  nait15 numeric(14,4) NOT NULL DEFAULT 0,
  muud text
)
SERVER db_narva_ee
OPTIONS (schema_name 'public', table_name 'objekt');




select * from remote_objekt

*/