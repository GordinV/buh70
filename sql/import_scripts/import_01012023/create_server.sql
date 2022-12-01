drop SERVER if exists db_raama CASCADE ;
CREATE SERVER db_raama FOREIGN DATA WRAPPER postgres_fdw OPTIONS
    (host '80.235.127.119', dbname 'db', port '5438');

CREATE USER MAPPING FOR vlad
    SERVER db_raama
    OPTIONS (user 'vlad', password 'Vlad490710');


drop SERVER if exists db_lapsed CASCADE ;
CREATE SERVER db_lapsed FOREIGN DATA WRAPPER postgres_fdw OPTIONS
    (host 'dbarh.narva.ee', dbname 'narvalv', port '5436');

CREATE USER MAPPING FOR vlad
    SERVER db_lapsed
    OPTIONS (user 'vlad', password 'Vlad490710');
