drop SERVER if exists db_text CASCADE ;
CREATE SERVER db_test FOREIGN DATA WRAPPER postgres_fdw OPTIONS
    (host 'dbarh.narva.ee', dbname 'narvalv', port '5436');

CREATE USER MAPPING FOR vlad
    SERVER db_test
    OPTIONS (user 'vlad', password 'Vlad490710');


drop SERVER if exists db_lapsed CASCADE ;
CREATE SERVER db_lapsed FOREIGN DATA WRAPPER postgres_fdw OPTIONS
    (host 'dbarh.narva.ee', dbname 'narvalv', port '5436');

CREATE USER MAPPING FOR vlad
    SERVER db_lapsed
    OPTIONS (user 'vlad', password 'Vlad490710');
