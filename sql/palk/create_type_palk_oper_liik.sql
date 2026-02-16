drop type if EXISTS palk_oper_liik;

CREATE TYPE palk_oper_liik AS ENUM ('+', '-', '%');

SELECT
    e.enumlabel AS value
FROM pg_enum e
         JOIN pg_type t ON e.enumtypid = t.oid
WHERE t.typname = 'palk_oper_liik'
ORDER BY e.enumsortorder;