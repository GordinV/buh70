
CREATE SCHEMA ladu
  AUTHORIZATION postgres;

GRANT ALL ON SCHEMA ladu TO dbadmin;
GRANT USAGE ON SCHEMA ladu TO dbkasutaja;
GRANT USAGE ON SCHEMA ladu TO dbpeakasutaja;
GRANT USAGE ON SCHEMA ladu TO dbvaatleja;
COMMENT ON SCHEMA ladu
  IS 'Here we keep all warehouse objects';
