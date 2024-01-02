
/*CREATE ROLE  hkametnik
    NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE;
*/
CREATE SCHEMA hooldekodu
    AUTHORIZATION postgres;

GRANT ALL ON SCHEMA hooldekodu TO postgres;
GRANT USAGE ON SCHEMA hooldekodu TO dbkasutaja;
GRANT USAGE ON SCHEMA hooldekodu TO dbpeakasutaja;
GRANT USAGE ON SCHEMA hooldekodu TO dbvaatleja;
GRANT USAGE ON SCHEMA hooldekodu TO hkametnik;
GRANT USAGE ON SCHEMA hooldekodu TO soametnik;
GRANT ALL ON SCHEMA hooldekodu TO dbadmin;

