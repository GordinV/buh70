
CREATE SCHEMA rekl
  AUTHORIZATION postgres;

GRANT ALL ON SCHEMA rekl TO postgres;
GRANT USAGE ON SCHEMA rekl TO dbkasutaja;
GRANT USAGE ON SCHEMA rekl TO dbpeakasutaja;
GRANT USAGE ON SCHEMA rekl TO dbvaatleja;
GRANT ALL ON SCHEMA rekl TO dbadmin;

