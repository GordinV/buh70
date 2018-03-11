drop type if EXISTS status;
drop type if EXISTS dok_status;

CREATE TYPE dok_status AS ENUM ('active', 'closed', 'deleted');
