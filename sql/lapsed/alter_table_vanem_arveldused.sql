ALTER TABLE lapsed.vanem_arveldus
    ADD COLUMN IF NOT EXISTS kas_email BOOLEAN;
ALTER TABLE lapsed.vanem_arveldus
    ADD COLUMN IF NOT EXISTS kas_paberil BOOLEAN;


UPDATE lapsed.vanem_arveldus
SET kas_email   = FALSE,
    kas_paberil = TRUE;

ALTER TABLE IF EXISTS lapsed.vanem_arveldus
    ALTER COLUMN kas_email SET NOT NULL;

ALTER TABLE IF EXISTS lapsed.vanem_arveldus
    ALTER COLUMN kas_paberil SET NOT NULL;
