DROP TABLE IF EXISTS ou.session_users;

CREATE TABLE ou.session_users (
    id          SERIAL NOT NULL
        CONSTRAINT session_users_pkey
            PRIMARY KEY,
    session_sid TEXT,
    users       JSONB
);

CREATE INDEX session_users_sid
    ON ou.session_users (session_sid);



GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE ou.session_users TO dbpeakasutaja;
GRANT SELECT, INSERT ON TABLE ou.session_users TO dbkasutaja;
GRANT ALL ON TABLE ou.session_users TO dbadmin;
GRANT SELECT ON TABLE ou.session_users TO dbvaatleja;



