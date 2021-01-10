-- размещение данных по таблицам согласно дате их создания

DROP TABLE IF EXISTS "docs.doc_2020" CASCADE;
CREATE TABLE IF NOT EXISTS "docs.doc_2020" (
    aasta INTEGER DEFAULT year(date())
)
    INHERITS (docs.doc);

ALTER TABLE lapsed.liidestamine DROP CONSTRAINT if exists liidestamine_docid_fkey;

DROP RULE IF EXISTS doc_aasta_2020 ON docs.doc;
CREATE RULE doc_aasta_2020 AS ON INSERT TO docs.doc
    WHERE year(date()) = 2020
    DO INSTEAD INSERT INTO docs.doc_2020   SELECT NEW.*;


DROP RULE IF EXISTS doc_aasta_2021 ON docs.doc;
CREATE RULE doc_aasta_2021 AS ON INSERT TO docs.doc
    WHERE year(date()) = 2021
    DO INSTEAD
    INSERT INTO docs.doc_2021   SELECT new.*;



DROP TABLE IF EXISTS docs.journal_2020 CASCADE;
CREATE TABLE IF NOT EXISTS docs.journal_2020 (
    aasta INTEGER DEFAULT year(date())
)
    INHERITS (docs.journal);

DROP RULE IF EXISTS journal_aasta_2020 ON docs.journal;
CREATE RULE journal_aasta_2020 AS ON INSERT TO docs.journal
    WHERE year(DATE()) = 2020
    DO INSTEAD
    INSERT INTO docs.journal_2020
    SELECT new.*;

DROP TABLE IF EXISTS docs.journal1_2020 CASCADE;
CREATE TABLE IF NOT EXISTS docs.journal1_2020 (
    aasta INTEGER DEFAULT year(date())
)
    INHERITS (docs.journal1);

DROP RULE IF EXISTS journal1_aasta_2020 ON docs.journal1;
CREATE RULE journal1_aasta_2020 AS ON INSERT TO docs.journal1
    WHERE year(DATE()) = 2020
    DO INSTEAD
    INSERT INTO docs.journal1_2020
    SELECT new.*;

DROP TABLE IF EXISTS palk.palk_oper_2020 CASCADE;
CREATE TABLE IF NOT EXISTS palk.palk_oper_2020 (
    aasta INTEGER DEFAULT year(date())
)
    INHERITS (palk.palk_oper);

DROP RULE IF EXISTS palk_oper_aasta_2020 ON palk.palk_oper;
CREATE RULE palk_oper_aasta_2020 AS ON INSERT TO palk.palk_oper
    WHERE year(DATE()) = 2020
    DO INSTEAD
    INSERT INTO palk.palk_oper_2020
    SELECT new.*;

