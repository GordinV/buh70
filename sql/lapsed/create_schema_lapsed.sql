
-- DROP SCHEMA docs ;

CREATE SCHEMA IF NOT EXISTS lapsed
    AUTHORIZATION postgres;

GRANT USAGE ON SCHEMA lapsed TO arvestaja;
GRANT USAGE ON SCHEMA lapsed TO dbpeakasutaja;
GRANT USAGE ON SCHEMA lapsed TO dbadmin;
GRANT USAGE ON SCHEMA lapsed TO dbvaatleja;
