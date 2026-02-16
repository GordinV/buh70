DROP TABLE IF EXISTS ou.task;

CREATE TABLE ou.task
(
    id        SERIAL  NOT NULL
        CONSTRAINT task__pkey
            PRIMARY KEY,
    user_id   INTEGER NOT NULL,
    created   TIMESTAMP DEFAULT now(),
    finished  TIMESTAMP,
    sql       text,
    tulemused text,
    status    integer   default 0
);

GRANT SELECT, UPDATE, INSERT ON TABLE ou.task TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT ON TABLE ou.task TO dbkasutaja;
GRANT ALL ON TABLE ou.task TO dbadmin;

alter table ou.task add column if not exists nimetus text;
