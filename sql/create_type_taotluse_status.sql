drop type if EXISTS taotluse_status;

CREATE TYPE taotluse_status AS ENUM ('allkirjastatud', 'esitatud', 'aktsepteeritud','tagastatud');
