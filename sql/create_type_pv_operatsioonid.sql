drop type if EXISTS pv_operatsioonid;

CREATE TYPE pv_operatsioonid AS ENUM ('paigutus', 'kulum', 'parandus', 'mahakandmine', 'umberhindamine');
