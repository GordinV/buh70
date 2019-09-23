
CREATE ROLE arvestaja WITH
    NOLOGIN
    NOSUPERUSER
    INHERIT
    NOCREATEDB
    NOCREATEROLE
    NOREPLICATION;


-- DROP SCHEMA docs ;

CREATE SCHEMA IF NOT EXISTS lapsed
    AUTHORIZATION postgres;

GRANT USAGE ON SCHEMA lapsed TO arvestaja;
GRANT USAGE ON SCHEMA lapsed TO dbpeakasutaja;
GRANT USAGE ON SCHEMA lapsed TO dbadmin;
GRANT USAGE ON SCHEMA lapsed TO dbvaatleja;


DROP TABLE IF EXISTS lapsed.lapse_kaart;

CREATE TABLE lapsed.lapse_kaart (
    id         SERIAL,
    parentid   INTEGER NOT NULL REFERENCES lapsed.laps (id) ON DELETE CASCADE ON UPDATE CASCADE,
    rekvid     INTEGER NOT NULL REFERENCES ou.rekv (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    nomid      INTEGER NOT NULL REFERENCES libs.nomenklatuur (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    hind       NUMERIC(14, 4)   DEFAULT 0,
    tunnus     VARCHAR(20),
    properties JSONB,
    ajalugu    JSONB,
    TIMESTAMP  TIMESTAMP        DEFAULT now(),
    staatus    INTEGER NOT NULL DEFAULT 1,
    muud       TEXT,
    CONSTRAINT lapse_kaart_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE lapsed.lapse_kaart TO dbpeakasutaja;
GRANT SELECT, INSERT, UPDATE ON TABLE lapsed.lapse_kaart TO arvestaja;
GRANT ALL ON TABLE lapsed.lapse_kaart TO dbadmin;
GRANT SELECT ON TABLE lapsed.lapse_kaart TO dbvaatleja;


DROP INDEX IF EXISTS lapse_kaart_parentid_idx;
CREATE INDEX IF NOT EXISTS lapse_kaart_parentid_idx ON lapsed.lapse_kaart (parentid);

DROP INDEX IF EXISTS lapse_kaart_rekvid_idx;
CREATE INDEX IF NOT EXISTS lapse_kaart_rekvid_idx ON lapsed.lapse_kaart (rekvid);

DROP INDEX IF EXISTS lapse_kaart_nomid_idx;
CREATE INDEX IF NOT EXISTS lapse_kaart_nomid_idx ON lapsed.lapse_kaart (nomid);


DROP TABLE IF EXISTS lapsed.lapse_taabel;

CREATE TABLE lapsed.lapse_taabel (
    id         SERIAL,
    parentid   INTEGER NOT NULL REFERENCES lapsed.laps (id) ON DELETE CASCADE ON UPDATE CASCADE,
    rekvid     INTEGER NOT NULL REFERENCES ou.rekv (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    nomid      INTEGER NOT NULL REFERENCES libs.nomenklatuur (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    kuu        INTEGER NOT NULL,
    aasta      INTEGER NOT NULL,
    kogus      NUMERIC(14, 4)   DEFAULT 0,
    tunnus     VARCHAR(20),
    properties JSONB,
    ajalugu    JSONB,
    TIMESTAMP  TIMESTAMP        DEFAULT now(),
    staatus    INTEGER NOT NULL DEFAULT 1,
    muud       TEXT,
    CONSTRAINT lapse_taabel_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE lapsed.lapse_taabel TO dbpeakasutaja;
GRANT SELECT, INSERT, UPDATE ON TABLE lapsed.lapse_taabel TO arvestaja;
GRANT ALL ON TABLE lapsed.lapse_taabel TO dbadmin;
GRANT SELECT ON TABLE lapsed.lapse_taabel TO dbvaatleja;


DROP INDEX IF EXISTS lapse_taabel_parentid_idx;
CREATE INDEX IF NOT EXISTS lapse_taabel_parentid_idx ON lapsed.lapse_taabel (parentid);

DROP INDEX IF EXISTS lapse_taabel_rekvid_idx;
CREATE INDEX IF NOT EXISTS lapse_taabel_rekvid_idx ON lapsed.lapse_taabel (rekvid);

DROP INDEX IF EXISTS lapse_taabel_nomid_idx;
CREATE INDEX IF NOT EXISTS lapse_taabel_nomid_idx ON lapsed.lapse_taabel (nomid);

DROP INDEX IF EXISTS lapse_taabel_period_idx;
CREATE INDEX IF NOT EXISTS lapse_taabel_period_idx ON lapsed.lapse_taabel (kuu, aasta);

ALTER TABLE lapsed.lapse_taabel
    ADD CONSTRAINT check_kuu CHECK ((kuu >= 1 AND kuu < 13) OR kuu = 0);

ALTER TABLE lapsed.lapse_taabel
    drop CONSTRAINT if exists check_aasta;


ALTER TABLE lapsed.lapse_taabel
    ADD CONSTRAINT check_aasta CHECK (aasta >= date_part('year', now()) - 1 );


DROP TABLE IF EXISTS lapsed.laps;

CREATE TABLE lapsed.laps (
    id         SERIAL,
    isikukood  CHAR(11) NOT NULL,
    nimi       TEXT     NOT NULL,
    properties JSONB,
    ajalugu    JSONB,
    TIMESTAMP  TIMESTAMP         DEFAULT now(),
    staatus    INTEGER  NOT NULL DEFAULT 1,
    muud       TEXT,
    CONSTRAINT lapsed_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE lapsed.laps TO dbpeakasutaja;
GRANT SELECT, INSERT, UPDATE ON TABLE lapsed.laps TO arvestaja;
GRANT ALL ON TABLE lapsed.laps TO dbadmin;
GRANT SELECT ON TABLE lapsed.laps TO dbvaatleja;

CREATE UNIQUE INDEX CONCURRENTLY laps_isikukood_idx ON lapsed.laps (isikukood);

ALTER TABLE lapsed.laps ADD CONSTRAINT
    unique_laps_isikukood UNIQUE USING INDEX laps_isikukood_idx;


DROP TABLE IF EXISTS lapsed.liidestamine;

CREATE TABLE lapsed.liidestamine (
    id         SERIAL,
    parentid   INTEGER NOT NULL REFERENCES lapsed.laps (id) ON DELETE CASCADE ON UPDATE CASCADE,
    docid     INTEGER NOT NULL REFERENCES docs.doc (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT liidestamine_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE lapsed.liidestamine TO dbpeakasutaja;
GRANT SELECT, INSERT, UPDATE ON TABLE lapsed.liidestamine TO arvestaja;
GRANT ALL ON TABLE lapsed.liidestamine TO dbadmin;
GRANT SELECT ON TABLE lapsed.liidestamine TO dbvaatleja;


DROP INDEX IF EXISTS liidestamine_parentid_idx;
CREATE INDEX IF NOT EXISTS liidestamine_parentid_idx ON lapsed.liidestamine (parentid);

DROP INDEX IF EXISTS liidestamine_docid_idx;
CREATE INDEX IF NOT EXISTS liidestamine_docid_idx ON lapsed.liidestamine (docid);

DROP TABLE IF EXISTS lapsed.vanemad;

CREATE TABLE lapsed.vanemad (
    id         SERIAL,
    parentid   INTEGER NOT NULL REFERENCES lapsed.laps (id) ON DELETE CASCADE ON UPDATE CASCADE,
    asutusid   INTEGER NOT NULL REFERENCES libs.asutus (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    properties JSONB,
    ajalugu    JSONB,
    TIMESTAMP  TIMESTAMP        DEFAULT now(),
    staatus    INTEGER NOT NULL DEFAULT 1,
    muud       TEXT,
    CONSTRAINT vanemad_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE lapsed.vanemad TO dbpeakasutaja;
GRANT SELECT, INSERT, UPDATE ON TABLE lapsed.vanemad TO arvestaja;
GRANT ALL ON TABLE lapsed.vanemad TO dbadmin;
GRANT SELECT ON TABLE lapsed.vanemad TO dbvaatleja;


DROP INDEX IF EXISTS vanemad_parentid_idx;

CREATE INDEX IF NOT EXISTS vanemad_parentid_idx ON lapsed.vanemad (parentid);

DROP INDEX IF EXISTS vanemad_asutudid_idx;

CREATE INDEX IF NOT EXISTS vanemad_asutusid_idx ON lapsed.vanemad (asutusid);

DROP INDEX IF EXISTS vanemad_asutudid_idx;

ALTER TABLE lapsed.vanemad
    ADD UNIQUE (asutusid, parentid);

DROP VIEW IF EXISTS lapsed.cur_lapse_taabel;

CREATE OR REPLACE VIEW lapsed.cur_lapse_taabel AS

SELECT lt.id,
       lt.parentid,
       lt.rekvid,
       lt.nomid,
       lt.kuu,
       lt.aasta,
       lt.kogus,
       l.isikukood,
       l.nimi,
       n.kood,
       n.nimetus AS teenus
FROM lapsed.lapse_taabel lt
         INNER JOIN lapsed.laps l ON l.id = lt.parentid
         INNER JOIN libs.nomenklatuur n ON n.id = lt.nomid
WHERE lt.staatus <> 3
ORDER BY aasta, kuu, nimi, kood;

GRANT SELECT ON TABLE lapsed.cur_lapse_taabel TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_lapse_taabel TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_lapse_taabel TO dbpeakasutaja;

DROP VIEW IF EXISTS lapsed.cur_teenused;
DROP VIEW IF EXISTS lapsed.cur_lapse_kaart;

CREATE OR REPLACE VIEW lapsed.cur_lapse_kaart AS

SELECT l.id as lapsid,
       lk.id,
       l.isikukood,
       l.nimi,
       lk.rekvid,
       lk.hind,
       lk.properties ->> 'yksus' AS yksus,
       n.kood,
       n.nimetus
FROM lapsed.laps l
         INNER JOIN lapsed.lapse_kaart lk ON lk.parentid = l.id
         INNER JOIN libs.nomenklatuur n ON lk.nomid = n.id
WHERE lk.staatus <> 3;

GRANT SELECT ON TABLE lapsed.cur_lapse_kaart TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_lapse_kaart TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_lapse_kaart TO dbpeakasutaja;

DROP VIEW IF EXISTS lapsed.cur_lapsed;

CREATE OR REPLACE VIEW lapsed.cur_lapsed AS

SELECT l.id,
       l.isikukood,
       l.nimi,
       l.properties,
       btrim(lk.yksused::TEXT, '[]')::TEXT AS yksused,
       lk.rekv_ids
FROM lapsed.laps l
         JOIN (SELECT parentid,
                      json_agg((k.properties -> 'yksus')) AS yksused,
                      array_agg(rekvid)                   AS rekv_ids
               FROM lapsed.lapse_kaart k
               WHERE k.staatus <> 3
               GROUP BY parentid
) lk ON lk.parentid = l.id
WHERE l.staatus <> 3
ORDER BY nimi;

GRANT SELECT ON TABLE lapsed.cur_lapsed TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_lapsed TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_lapsed TO dbpeakasutaja;

DROP VIEW IF EXISTS lapsed.cur_laste_arved;

CREATE OR REPLACE VIEW lapsed.cur_laste_arved AS
SELECT d.id                                         AS id,
       d.docs_ids,
       trim(a.number)                               AS number,
       a.rekvid,
       a.kpv                                        AS kpv,
       a.summa,
       a.tahtaeg                                    AS tahtaeg,
       a.jaak,
       a.tasud :: DATE                              AS tasud,
       a.tasudok,
       a.userid,
       a.asutusid,
       a.journalid,
       a.lisa,
       trim(asutus.nimetus)                         AS asutus,
       trim(asutus.regkood)                         AS vanem_isikukood,
       jid.number                                   AS lausnr,
       a.muud                                       AS markused,
       (a.properties ->> 'aa') :: VARCHAR(120)      AS arve,
       (a.properties ->> 'viitenr') :: VARCHAR(120) AS viitenr,
       l.isikukood                                  AS isikukood,
       l.nimi                                       AS nimi
FROM docs.doc d
         INNER JOIN docs.arv a ON a.parentId = d.id
         INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
         INNER JOIN lapsed.laps l ON l.id = ld.parentid
         INNER JOIN libs.asutus asutus ON a.asutusid = asutus.id
         LEFT OUTER JOIN docs.journal j ON j.parentid = a.journalid
         LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
ORDER BY d.lastupdate DESC;

GRANT SELECT ON TABLE lapsed.cur_laste_arved TO dbpeakasutaja;
GRANT SELECT ON TABLE lapsed.cur_laste_arved TO dbkasutaja;
GRANT SELECT ON TABLE lapsed.cur_laste_arved TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_laste_arved TO arvestaja;

GRANT ALL ON TABLE lapsed.cur_laste_arved TO dbadmin;

DROP VIEW IF EXISTS lapsed.cur_vanemad;

CREATE OR REPLACE VIEW lapsed.cur_vanemad AS

SELECT a.id                                      AS vanem_id,
       v.id                                      AS id,
       a.regkood                                 AS isikukood,
       a.nimetus                                 AS nimi,
       btrim(json_agg(l.nimi)::TEXT, '[]')::TEXT AS lapsed,
       array_agg(lk.rekvid)                      AS rekv_ids
FROM lapsed.vanemad v
         INNER JOIN libs.asutus a ON a.id = v.asutusid
         INNER JOIN (
    SELECT l.id, l.nimi
    FROM lapsed.laps l
    WHERE l.staatus <> 3

    GROUP BY l.id, l.nimi
) l ON l.id = v.parentid
         INNER JOIN (SELECT DISTINCT lk.parentid, lk.rekvid FROM lapsed.lapse_kaart lk WHERE lk.staatus <> 3) lk
                    ON lk.parentid = v.parentid

GROUP BY a.id, v.id, a.regkood, a.nimetus
ORDER BY a.nimetus;

GRANT SELECT ON TABLE lapsed.cur_vanemad TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_vanemad TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_vanemad TO dbpeakasutaja;

DROP FUNCTION IF EXISTS lapsed.lapse_saldod(l_laps_Id INTEGER, l_kpv DATE);
DROP FUNCTION IF EXISTS lapsed.lapse_saldod(l_kpv DATE);

CREATE OR REPLACE FUNCTION lapsed.lapse_saldod(l_kpv DATE DEFAULT now())
    RETURNS TABLE (
        jaak     NUMERIC(14, 2),
        laps_id  INTEGER,
        rekv_id  INTEGER,
        docs_ids INTEGER[]
    ) AS
$BODY$


SELECT sum(a.jaak)::NUMERIC(14, 2) AS jaak,
       l.parentid                  AS laps_id,
       a.rekvid                    AS rekv_id,
       array_agg(d.id)             AS docs_ids
FROM docs.doc d
         INNER JOIN docs.arv a ON a.parentid = d.id
         INNER JOIN lapsed.liidestamine l ON l.docid = d.id
WHERE a.kpv < l_kpv
  AND a.jaak <> 0
  AND d.status <> 3

GROUP BY a.rekvid, l.parentid;
$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.lapse_saldod(l_kpv DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.lapse_saldod(l_kpv DATE) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.lapse_saldod(l_kpv DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.lapse_saldod(l_kpv DATE) TO arvestaja;


INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'LAPS'                                    AS kood,
       'Lapsed'                                  AS nimetus,
       'DOK'                                     AS library,
       '{"type":"library", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'LAPS');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'VANEM'                                    AS kood,
       'Vanemate register'                                  AS nimetus,
       'DOK'                                     AS library,
       '{"type":"library", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'VANEM');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'LAPSE_KAART'                                    AS kood,
       'Teenused lastele'                                  AS nimetus,
       'DOK'                                     AS library,
       '{"type":"library", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'LAPSE_KAART');

INSERT INTO libs.library (rekvid, kood, nimetus, library, properties)
SELECT 1::INTEGER,
       'LAPSE_TAABEL'                                    AS kood,
       'Teenuste taabel lastele'                                  AS nimetus,
       'DOK'                                     AS library,
       '{"type":"library", "module":["Lapsed"]}' AS properties
WHERE NOT exists(SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'LAPSE_TAABEL');

-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.sp_delete_laps(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_delete_laps(IN user_id INTEGER,
                                                 IN doc_id INTEGER,
                                                 OUT error_code INTEGER,
                                                 OUT result INTEGER,
                                                 OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    v_doc        RECORD;
    json_ajalugu JSONB;
    DOC_STATUS   INTEGER = 3; -- документ удален
BEGIN

    SELECT l.*,
           u.ametnik::TEXT                      AS kasutaja,
           (u.roles -> 'is_arvestaja')::BOOLEAN AS is_arvestaja
           INTO v_doc
    FROM lapsed.laps l
             JOIN ou.userid u ON u.id = user_id
    WHERE l.id = doc_id;

    -- проверка на пользователя и его соответствие учреждению

    IF v_doc IS NULL
    THEN
        error_code = 6;
        error_message = 'Dokument ei leitud, docId: ' || coalesce(doc_id, 0) :: TEXT;
        result = 0;
        RETURN;

    END IF;

    IF (v_doc.kasutaja IS NULL
        )
    THEN

        error_code = 5;
        error_message = 'Kasutaja ei leitud: ' || ', userId:' ||
                        coalesce(user_id, 0) :: TEXT;
        result = 0;
        RETURN;

    END IF;

    -- проверка на права. Предполагает наличие прописанных прав на удаление для данного пользователя в поле rigths


    --	ids =  v_doc.rigths->'delete';
    IF (v_doc.is_arvestaja IS NULL OR NOT v_doc.is_arvestaja)
    THEN
        RAISE NOTICE 'У пользователя нет прав на удаление';
        error_code = 4;
        error_message = 'Ei saa kustuta dokument. Puudub õigused';
        result = 0;
        RETURN;

    END IF;

    -- Проверка на наличие связанных документов и их типов (если тип не проводка, то удалять нельзя кроме проводки)
/*
            IF exists(
            SELECT d.id
            FROM docs.doc d
                     INNER JOIN libs.library l ON l.id = d.doc_type_id
            WHERE d.id IN (SELECT unnest(v_doc.docs_ids))
              AND l.kood IN (
                SELECT kood
                FROM libs.library
                WHERE library = 'DOK'
                  AND kood NOT IN ('JOURNAL')
                  AND (properties IS NULL OR properties :: JSONB @> '{"type":"document"}')
            ))
    THEN

        RAISE NOTICE 'Есть связанные доку менты. удалять нельзя';
        error_code = 3; -- Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid
        error_message = 'Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid';
        result = 0;
        RETURN;
    END IF;
*/
    -- Логгирование удаленного документа

    SELECT to_jsonb(row) INTO json_ajalugu
    FROM (SELECT now()          AS deleted,
                 v_doc.kasutaja AS user) row;

    UPDATE lapsed.laps
    SET staatus = DOC_STATUS,
        ajalugu = coalesce(ajalugu, '[]')::JSONB || json_ajalugu
    WHERE id = doc_id;

    result = 1;
    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.sp_delete_laps(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.sp_delete_laps(INTEGER, INTEGER) TO dbpeakasutaja;


-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.sp_delete_lapse_kaart(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_delete_lapse_kaart(IN user_id INTEGER,
                                                        IN doc_id INTEGER,
                                                        OUT error_code INTEGER,
                                                        OUT result INTEGER,
                                                        OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    v_doc        RECORD;
    json_ajalugu JSONB;
    DOC_STATUS   INTEGER = 3; -- документ удален
BEGIN

    SELECT v.*,
           u.ametnik::TEXT                      AS kasutaja,
           (u.roles -> 'is_arvestaja')::BOOLEAN AS is_arvestaja
           INTO v_doc
    FROM lapsed.vanemad v
             JOIN ou.userid u ON u.id = user_id
    WHERE v.id = doc_id;

    -- проверка на пользователя и его соответствие учреждению

    IF v_doc IS NULL
    THEN
        error_code = 6;
        error_message = 'Dokument ei leitud, docId: ' || coalesce(doc_id, 0) :: TEXT;
        result = 0;
        RETURN;

    END IF;

    IF (v_doc.kasutaja IS NULL
        )
    THEN

        error_code = 5;
        error_message = 'Kasutaja ei leitud: ' || ', userId:' ||
                        coalesce(user_id, 0) :: TEXT;
        result = 0;
        RETURN;

    END IF;

    -- проверка на права. Предполагает наличие прописанных прав на удаление для данного пользователя в поле rigths


    --	ids =  v_doc.rigths->'delete';
    IF (v_doc.is_arvestaja IS NULL OR NOT v_doc.is_arvestaja)
    THEN
        RAISE NOTICE 'У пользователя нет прав на удаление';
        error_code = 4;
        error_message = 'Ei saa kustuta dokument. Puudub õigused';
        result = 0;
        RETURN;

    END IF;

    -- Логгирование удаленного документа

    SELECT to_jsonb(row) INTO json_ajalugu
    FROM (SELECT now()          AS deleted,
                 v_doc.kasutaja AS user) row;

    UPDATE lapsed.lapse_kaart
    SET staatus = DOC_STATUS,
        ajalugu = coalesce(ajalugu, '[]')::JSONB || json_ajalugu
    WHERE id = doc_id;

    result = 1;
    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.sp_delete_lapse_kaart(INTEGER, INTEGER) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.sp_delete_lapse_kaart(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.sp_delete_lapse_kaart(INTEGER, INTEGER) TO dbpeakasutaja;


-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.sp_delete_lapse_taabel(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_delete_lapse_taabel(IN user_id INTEGER,
                                                         IN doc_id INTEGER,
                                                         OUT error_code INTEGER,
                                                         OUT result INTEGER,
                                                         OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    v_doc        RECORD;
    json_ajalugu JSONB;
    DOC_STATUS   INTEGER = 3; -- документ удален
BEGIN

    SELECT l.*,
           u.ametnik::TEXT                      AS kasutaja,
           (u.roles -> 'is_arvestaja')::BOOLEAN AS is_arvestaja
           INTO v_doc
    FROM lapsed.lapse_taabel l
             JOIN ou.userid u ON u.id = user_id
    WHERE l.id = doc_id;

    -- проверка на пользователя и его соответствие учреждению

    IF v_doc IS NULL
    THEN
        error_code = 6;
        error_message = 'Dokument ei leitud, docId: ' || coalesce(doc_id, 0) :: TEXT;
        result = 0;
        RETURN;

    END IF;

    IF (v_doc.kasutaja IS NULL
        )
    THEN

        error_code = 5;
        error_message = 'Kasutaja ei leitud: ' || ', userId:' ||
                        coalesce(user_id, 0) :: TEXT;
        result = 0;
        RETURN;

    END IF;

    -- проверка на права. Предполагает наличие прописанных прав на удаление для данного пользователя в поле rigths


    --	ids =  v_doc.rigths->'delete';
    IF (v_doc.is_arvestaja IS NULL OR NOT v_doc.is_arvestaja)
    THEN
        RAISE NOTICE 'У пользователя нет прав на удаление';
        error_code = 4;
        error_message = 'Ei saa kustuta dokument. Puudub õigused';
        result = 0;
        RETURN;

    END IF;

    -- Логгирование удаленного документа

    SELECT to_jsonb(row) INTO json_ajalugu
    FROM (SELECT now()          AS deleted,
                 v_doc.kasutaja AS user) row;

    UPDATE lapsed.lapse_taabel
    SET staatus = DOC_STATUS,
        ajalugu = coalesce(ajalugu, '[]')::JSONB || json_ajalugu
    WHERE id = doc_id;

    result = 1;
    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.sp_delete_lapse_taabel(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.sp_delete_lapse_taabel(INTEGER, INTEGER) TO dbpeakasutaja;

-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.sp_delete_vanem(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_delete_vanem(IN user_id INTEGER,
                                                  IN doc_id INTEGER,
                                                  OUT error_code INTEGER,
                                                  OUT result INTEGER,
                                                  OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    v_doc        RECORD;
    json_ajalugu JSONB;
    DOC_STATUS   INTEGER = 3; -- документ удален
BEGIN

    SELECT v.*,
           u.ametnik::TEXT                      AS kasutaja,
           (u.roles -> 'is_arvestaja')::BOOLEAN AS is_arvestaja
           INTO v_doc
    FROM lapsed.vanemad v
             JOIN ou.userid u ON u.id = user_id
    WHERE v.id = doc_id;

    -- проверка на пользователя и его соответствие учреждению

    IF v_doc IS NULL
    THEN
        error_code = 6;
        error_message = 'Dokument ei leitud, docId: ' || coalesce(doc_id, 0) :: TEXT;
        result = 0;
        RETURN;

    END IF;

    IF (v_doc.kasutaja IS NULL
        )
    THEN

        error_code = 5;
        error_message = 'Kasutaja ei leitud: ' || ', userId:' ||
                        coalesce(user_id, 0) :: TEXT;
        result = 0;
        RETURN;

    END IF;

    -- проверка на права. Предполагает наличие прописанных прав на удаление для данного пользователя в поле rigths


    --	ids =  v_doc.rigths->'delete';
    IF (v_doc.is_arvestaja IS NULL OR NOT v_doc.is_arvestaja)
    THEN
        RAISE NOTICE 'У пользователя нет прав на удаление';
        error_code = 4;
        error_message = 'Ei saa kustuta dokument. Puudub õigused';
        result = 0;
        RETURN;

    END IF;

    -- Логгирование удаленного документа

    SELECT to_jsonb(row) INTO json_ajalugu
    FROM (SELECT now()          AS deleted,
                 v_doc.kasutaja AS user) row;

    UPDATE lapsed.vanemad
    SET staatus = DOC_STATUS,
        ajalugu = coalesce(ajalugu, '[]')::JSONB || json_ajalugu
    WHERE id = doc_id;

    result = 1;
    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.sp_delete_vanem(INTEGER, INTEGER) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.sp_delete_vanem(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.sp_delete_vanem(INTEGER, INTEGER) TO dbpeakasutaja;

DROP FUNCTION IF EXISTS docs.sp_salvesta_arv(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_salvesta_arv(data JSON,
                                                userid INTEGER,
                                                user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    arv_id         INTEGER;
    arv1_id        INTEGER;
    userName       TEXT;
    doc_id         INTEGER        = data ->> 'id';
    doc_data       JSON           = data ->> 'data';
    doc_details    JSON           = coalesce(doc_data ->> 'gridData', doc_data ->> 'griddata');
    doc_number     TEXT           = doc_data ->> 'number';
    doc_summa      NUMERIC(14, 4) = coalesce((doc_data ->> 'summa') :: NUMERIC, 0);
    doc_liik       INTEGER        = doc_data ->> 'liik';
    doc_operid     INTEGER        = doc_data ->> 'operid';
    doc_asutusid   INTEGER        = doc_data ->> 'asutusid';
    doc_lisa       TEXT           = doc_data ->> 'lisa';
    doc_kpv        DATE           = doc_data ->> 'kpv';
    doc_tahtaeg    DATE           = doc_data ->> 'tahtaeg';
    doc_kbmta      NUMERIC(14, 4) = coalesce((doc_data ->> 'kbmta') :: NUMERIC, 0);
    doc_kbm        NUMERIC(14, 4) = coalesce((doc_data ->> 'kbm') :: NUMERIC, 0);
    doc_muud       TEXT           = doc_data ->> 'muud';
    doc_objektid   INTEGER        = doc_data ->> 'objektid'; -- считать или не считать (если не пусто) интресс
    doc_objekt     TEXT           = doc_data ->> 'objekt';
    tnDokLausId    INTEGER        = coalesce((doc_data ->> 'doklausid') :: INTEGER, 1);
    doc_lepingId   INTEGER        = doc_data ->> 'leping_id';
    doc_aa         TEXT           = doc_data ->> 'aa'; -- eri arve
    doc_viitenr    TEXT           = doc_data ->> 'viitenr'; -- viite number
    doc_lapsid     INTEGER        = doc_data ->> 'lapsid'; -- kui arve salvestatud lapse modulis
    dok_props      JSONB          = (SELECT row_to_json(row)
                                     FROM (SELECT doc_aa AS aa, doc_viitenr AS viitenr) row);
    json_object    JSON;
    json_record    RECORD;
    new_history    JSONB;
    new_rights     JSONB;
    ids            INTEGER[];
    l_json_arve_id JSONB;
    is_import      BOOLEAN        = data ->> 'import';
    l_doc_ids      INTEGER[];
BEGIN

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    RAISE NOTICE 'doc_id: %', doc_id;

    IF doc_number IS NULL OR doc_number = ''
    THEN
        -- присвоим новый номер
        doc_number = docs.sp_get_number(user_rekvid, 'ARV', YEAR(doc_kpv), tnDokLausId);
    END IF;

    SELECT kasutaja INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;

    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    -- проверка на номер
/*
  SELECT row_to_json(row)
         INTO json_object
  FROM (SELECT
          doc_liik      AS tyyp,
          doc_number    AS number,
          year(doc_kpv) AS aasta,
          doc_asutusid  AS asutus) row;
  IF NOT docs.check_arv_number(user_rekvid::INTEGER, json_object::JSON)::BOOLEAN
  THEN
    RAISE NOTICE 'Number not valid';
    RETURN 0;
  END IF;
*/

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        SELECT row_to_json(row) INTO new_history
        FROM (SELECT now()    AS created,
                     userName AS user) row;

        SELECT row_to_json(row) INTO new_rights
        FROM (SELECT ARRAY [userId] AS "select",
                     ARRAY [userId] AS "update",
                     ARRAY [userId] AS "delete") row;

        IF doc_lepingId IS NOT NULL
        THEN
            -- will add reference to leping
            ids = array_append(ids, doc_lepingId);
        END IF;

        INSERT INTO docs.doc (doc_type_id, history, rigths, rekvId, docs_ids)
        VALUES (doc_type_id, '[]' :: JSONB || new_history, new_rights, user_rekvid, ids) RETURNING id
            INTO doc_id;

        ids = NULL;

        INSERT INTO docs.arv (parentid, rekvid, userid, liik, operid, number, kpv, asutusid, lisa, tahtaeg, kbmta, kbm,
                              summa, muud, objektid, objekt, doklausid, properties)
        VALUES (doc_id, user_rekvid, userId, doc_liik, doc_operid, doc_number, doc_kpv, doc_asutusid, doc_lisa,
                doc_tahtaeg,
                doc_kbmta, doc_kbm, doc_summa,
                doc_muud, doc_objektid, doc_objekt, tnDokLausId, dok_props) RETURNING id
                   INTO arv_id;

    ELSE
        -- history
        SELECT row_to_json(row) INTO new_history
        FROM (SELECT now()    AS updated,
                     userName AS user) row;


        UPDATE docs.doc
        SET lastupdate = now(),
            history    = coalesce(history, '[]') :: JSONB || new_history,
            rekvid     = user_rekvid
        WHERE id = doc_id;

        IF doc_lepingId IS NOT NULL
        THEN
            -- will add reference to leping
            UPDATE docs.doc
            SET docs_ids = array_append(docs_ids, doc_lepingId)
            WHERE id = doc_id;
        END IF;

        UPDATE docs.arv
        SET liik       = doc_liik,
            operid     = doc_operid,
            number     = doc_number,
            kpv        = doc_kpv,
            asutusid   = doc_asutusid,
            lisa       = doc_lisa,
            tahtaeg    = doc_tahtaeg,
            kbmta      = coalesce(doc_kbmta, 0),
            kbm        = coalesce(doc_kbm, 0),
            summa      = coalesce(doc_summa, 0),
            muud       = doc_muud,
            objektid   = doc_objektid,
            objekt     = doc_objekt,
            doklausid  = tnDokLausId,
            properties = dok_props
        WHERE parentid = doc_id RETURNING id
            INTO arv_id;

    END IF;

    -- вставка в таблицы документа
    FOR json_object IN
        SELECT *
        FROM json_array_elements(doc_details)
        LOOP
            SELECT * INTO json_record
            FROM json_to_record(
                         json_object) AS x (id TEXT, nomId INTEGER, kogus NUMERIC(14, 4), hind NUMERIC(14, 4),
                                            kbm NUMERIC(14, 4),
                                            kbmta NUMERIC(14, 4),
                                            summa NUMERIC(14, 4), kood TEXT, nimetus TEXT, kood1 TEXT, kood2 TEXT,
                                            kood3 TEXT,
                                            kood4 TEXT, kood5 TEXT,
                                            konto TEXT, tunnus TEXT, tp TEXT, proj TEXT, arve_id INTEGER, muud TEXT,
                                            km TEXT);

            IF json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW'
            THEN

                INSERT INTO docs.arv1 (parentid, nomid, kogus, hind, kbm, kbmta, summa, kood1, kood2, kood3, kood4,
                                       kood5,
                                       konto, tunnus, tp, proj, muud, kbm_maar)
                VALUES (arv_id, json_record.nomid,
                        coalesce(json_record.kogus, 1),
                        coalesce(json_record.hind, 0),
                        coalesce(json_record.kbm, 0),
                        coalesce(json_record.kbmta, coalesce(json_record.kogus, 1) * coalesce(json_record.hind, 0)),
                        coalesce(json_record.summa, (coalesce(json_record.kogus, 1) * coalesce(json_record.hind, 0)) +
                                                    coalesce(json_record.kbm, 0)),
                        coalesce(json_record.kood1, ''),
                        coalesce(json_record.kood2, ''),
                        coalesce(json_record.kood3, ''),
                        coalesce(json_record.kood4, ''),
                        coalesce(json_record.kood5, ''),
                        coalesce(json_record.konto, ''),
                        coalesce(json_record.tunnus, ''),
                        coalesce(json_record.tp, ''),
                        coalesce(json_record.proj, ''),
                        coalesce(json_record.muud, ''),
                        coalesce(json_record.km, '')) RETURNING id
                           INTO arv1_id;

                -- add new id into array of ids
                ids = array_append(ids, arv1_id);

            ELSE
                UPDATE docs.arv1
                SET parentid = arv_id,
                    nomid    = json_record.nomid,
                    kogus    = coalesce(json_record.kogus, 0),
                    hind     = coalesce(json_record.hind, 0),
                    kbm      = coalesce(json_record.kbm, 0),
                    kbmta    = coalesce(json_record.kbmta, kogus * hind),
                    summa    = coalesce(json_record.summa, (kogus * hind) + kbm),
                    kood1    = coalesce(json_record.kood1, ''),
                    kood2    = coalesce(json_record.kood2, ''),
                    kood3    = coalesce(json_record.kood3, ''),
                    kood4    = coalesce(json_record.kood4, ''),
                    kood5    = coalesce(json_record.kood5, ''),
                    konto    = coalesce(json_record.konto, ''),
                    tunnus   = coalesce(json_record.tunnus, ''),
                    tp       = coalesce(json_record.tp, ''),
                    kbm_maar = coalesce(json_record.km, ''),
                    muud     = json_record.muud
                WHERE id = json_record.id :: INTEGER RETURNING id
                    INTO arv1_id;

                -- add new id into array of ids
                ids = array_append(ids, arv1_id);

            END IF;

            IF (arv1_id IS NOT NULL AND NOT empty(arv1_id) AND json_record.arve_id IS NOT NULL)
            THEN
                -- в параметрах есть ссылки на другие счета
                l_json_arve_id = (SELECT row_to_json(row) FROM (SELECT json_record.arve_id AS arve_id) row)::JSONB;
                UPDATE docs.arv1
                SET properties = coalesce(properties::JSONB, '{}'::JSONB)::JSONB || l_json_arve_id
                WHERE id = arv1_id;

                -- установим связь со счетом , на который выписан интрес
                UPDATE docs.doc
                SET docs_ids = array_append(docs_ids, doc_id)
                WHERE id = json_record.arve_id;

            END IF;

        END LOOP;

    -- delete record which not in json
    IF array_length(ids, 1) > 0
    THEN
        -- проверить на наличие ссылок на другие счета и снять ссылку
        IF exists(
                SELECT d.id
                FROM docs.doc d
                WHERE d.id IN (
                    SELECT (properties ->> 'arve_id')::INTEGER
                    FROM docs.arv1 a1
                    WHERE a1.parentid = arv_id
                      AND a1.id NOT IN (SELECT unnest(ids))))
        THEN
            -- есть ссылка, надо снять
            UPDATE docs.doc
            SET docs_ids = array_remove(docs_ids, doc_id)
            WHERE id IN (
                SELECT (a1.properties ->> 'arve_id')::INTEGER
                FROM docs.arv1 a1
                         INNER JOIN docs.arv a ON a.id = a1.parentid
                WHERE a.parentid = doc_id
                  AND a1.id NOT IN (SELECT unnest(ids)));
        END IF;

        DELETE
        FROM docs.arv1
        WHERE parentid = arv_id
          AND id NOT IN (SELECT unnest(ids));
    END IF;
    -- update arv summad
    SELECT sum(summa) AS summa,
           sum(kbm)   AS kbm
           INTO doc_summa, doc_kbm
    FROM docs.arv1
    WHERE parentid = arv_id;

    UPDATE docs.arv
    SET kbmta = coalesce(doc_summa, 0) - coalesce(doc_kbm, 0),
        kbm   = coalesce(doc_kbm, 0),
        summa = coalesce(doc_summa, 0)
    WHERE parentid = doc_id;

    PERFORM docs.sp_update_arv_jaak(doc_id);

    IF doc_lepingId IS NOT NULL
    THEN
        -- will add ref.id to leping
        UPDATE docs.doc
        SET docs_ids = array_append(docs_ids, doc_id)
        WHERE id = doc_lepingId;
    END IF;

    -- lapse module

    IF doc_lapsid IS NOT NULL
    THEN
        IF NOT exists(SELECT id FROM lapsed.liidestamine WHERE parentid = doc_lapsid AND docid = doc_id)
        THEN
            INSERT INTO lapsed.liidestamine (parentid, docid) VALUES (doc_lapsid, doc_id);
        END IF;

    END IF;


    RETURN doc_id;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_salvesta_arv(JSON, INTEGER, INTEGER) TO ladukasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_arv(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_arv(JSON, INTEGER, INTEGER) TO dbpeakasutaja;

DROP FUNCTION IF EXISTS lapsed.sp_salvesta_lapsed(JSONB, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS lapsed.sp_salvesta_laps(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_salvesta_laps(data JSONB,
                                                   userid INTEGER,
                                                   user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName         TEXT;
    doc_data         JSON    = data ->> 'data';
    doc_id           INTEGER = doc_data ->> 'id';
    doc_isikukood    TEXT    = doc_data ->> 'isikukood';
    doc_nimi         TEXT    = doc_data ->> 'nimi';
    doc_viitenr      TEXT    = doc_data ->> 'viitenumber';
    doc_vanemId      INTEGER = doc_data ->> 'vanemid';
    doc_muud         TEXT    = doc_data ->> 'muud';
    v_vanem          RECORD;
    json_props       JSONB;
    json_props_vanem JSONB;
    json_ajalugu     JSONB;
BEGIN

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    SELECT kasutaja INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;
    IF userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    json_props = to_jsonb(row)
                 FROM (SELECT doc_viitenr AS viitenumber) row;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS created,
                                    userName AS user) row;

        INSERT INTO lapsed.laps (isikukood, nimi, muud, properties, ajalugu)
        VALUES (doc_isikukood, doc_nimi, doc_muud, json_props, '[]' :: JSONB || json_ajalugu) RETURNING id
            INTO doc_id;


        IF doc_id > 0 AND doc_vanemId IS NOT NULL
        THEN
            -- will save parents

            SELECT 0                          AS id,
                   doc_id                     AS parentid,
                   asutusId,
                   properties ->> 'arved'     AS arved,
                   properties ->> 'suhtumine' AS suhtumine
                   INTO v_vanem
            FROM lapsed.vanemad v
            WHERE id = doc_vanemId;

            json_props_vanem = to_jsonb(row)
                               FROM (SELECT v_vanem AS data) row;

            PERFORM lapsed.sp_salvesta_vanem(json_props_vanem::JSONB, userid::INTEGER, user_rekvid::INTEGER) AS id;


        END IF;

    ELSE

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS updated,
                                    userName AS user,
                                    l.*      AS data
                             FROM lapsed.laps l
                             WHERE id = doc_id
                            ) row;

        UPDATE lapsed.laps
        SET isikukood  = doc_isikukood,
            nimi       = doc_nimi,
            properties = properties || json_props,
            muud       = doc_muud,
            ajalugu    = coalesce(ajalugu, '[]') :: JSONB || json_ajalugu
        WHERE id = doc_id RETURNING id
            INTO doc_id;

    END IF;


    RETURN doc_id;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            RETURN 0;


END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_laps(JSONB, INTEGER, INTEGER) TO arvestaja;


DROP FUNCTION IF EXISTS lapsed.sp_salvesta_lapse_kaart(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_salvesta_lapse_kaart(data JSONB,
                                                          userid INTEGER,
                                                          user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName         TEXT;
    doc_data         JSON    = data ->> 'data';
    doc_id           INTEGER = doc_data ->> 'id';
    doc_parentid     INTEGER = doc_data ->> 'parentid';
    doc_nomid        INTEGER = doc_data ->> 'nomid';
    doc_tunnus       TEXT    = doc_data ->> 'tunnus';
    doc_hind         NUMERIC = doc_data ->> 'hind';
    doc_yksus        TEXT    = doc_data ->> 'yksus';
    doc_soodus       NUMERIC = doc_data ->> 'soodus';
    doc_kas_protsent BOOLEAN = doc_data ->> 'kas_protsent';
    doc_kas_eraldi   BOOLEAN = doc_data ->> 'kas_eraldi';
    doc_kas_ettemaks BOOLEAN = doc_data ->> 'kas_ettemaks';
    doc_sooduse_alg  DATE    = doc_data ->> 'sooduse_alg';
    doc_sooduse_lopp DATE    = doc_data ->> 'sooduse_lopp';
    doc_muud         TEXT    = doc_data ->> 'muud';
    v_vanem          RECORD;
    json_props       JSONB;
    json_props_vanem JSONB;
    json_ajalugu     JSONB;
BEGIN

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    SELECT kasutaja INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;
    IF userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    json_props = to_jsonb(row)
                 FROM (SELECT doc_yksus        AS yksus,
                              doc_soodus       AS soodus,
                              doc_kas_protsent AS kas_protsent,
                              doc_sooduse_alg  AS sooduse_alg,
                              doc_sooduse_lopp AS sooduse_lopp,
                              doc_kas_eraldi   AS kas_eraldi,
                              doc_kas_ettemaks AS kas_ettemaks
                      ) row;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS created,
                                    userName AS user) row;

        INSERT INTO lapsed.lapse_kaart (parentid, rekvid, nomid, hind, tunnus, muud, properties, ajalugu)
        VALUES (doc_parentid, user_rekvid, doc_nomid, doc_hind, doc_tunnus, doc_muud, json_props,
                '[]' :: JSONB || json_ajalugu) RETURNING id
                   INTO doc_id;

    ELSE

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS updated,
                                    userName AS user,
                                    l.*      AS data
                             FROM lapsed.lapse_kaart l
                             WHERE id = doc_id
                            ) row;

        UPDATE lapsed.lapse_kaart
        SET nomid      = doc_nomid,
            tunnus     = doc_tunnus,
            hind       = doc_hind,
            properties = properties || json_props,
            muud       = doc_muud,
            ajalugu    = coalesce(ajalugu, '[]') :: JSONB || json_ajalugu
        WHERE id = doc_id RETURNING id
            INTO doc_id;

    END IF;


    RETURN doc_id;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            RETURN 0;


END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_lapse_kaart(JSONB, INTEGER, INTEGER) TO arvestaja;


DROP FUNCTION IF EXISTS lapsed.sp_salvesta_lapse_taabel(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_salvesta_lapse_taabel(data JSONB,
                                                           userid INTEGER,
                                                           user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName     TEXT;
    doc_data     JSON    = data ->> 'data';
    doc_id       INTEGER = doc_data ->> 'id';
    doc_parentid INTEGER = doc_data ->> 'parentid';
    doc_nomid    INTEGER = doc_data ->> 'nomid';
    doc_kogus    NUMERIC = doc_data ->> 'kogus';
    doc_kuu      INTEGER = doc_data ->> 'kuu';
    doc_aasta    INTEGER = doc_data ->> 'aasta';
    doc_muud     TEXT    = doc_data ->> 'muud';
    doc_staatus  INTEGER = 1;
    json_props   JSONB;
    json_ajalugu JSONB;
BEGIN

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    SELECT kasutaja INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;
    IF userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;


    -- поиск удаленной записи
    IF doc_id IS NULL OR doc_id = 0
    THEN
        SELECT id,
               staatus
               INTO doc_id, doc_staatus
        FROM lapsed.lapse_taabel lt
        WHERE parentid = doc_parentid
          AND rekvid = user_rekvid
          AND nomid = doc_nomid
          AND kuu = doc_kuu
          AND aasta = doc_aasta;

        IF doc_id IS NULL
        THEN
            doc_id = 0;
            doc_staatus = 1;
        ELSE
            IF doc_staatus = 3
            THEN
                doc_staatus = 1; -- запись была удалена, восстанавливаем
            END IF;
        END IF;

    END IF;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS created,
                                    userName AS user) row;

        INSERT INTO lapsed.lapse_taabel (parentid, nomid, rekvid, kogus, kuu, aasta, muud, ajalugu)
        VALUES (doc_parentid, doc_nomid, user_rekvid, doc_kogus, doc_kuu, doc_aasta, doc_muud,
                '[]' :: JSONB || json_ajalugu) RETURNING id
                   INTO doc_id;

    ELSE

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS updated,
                                    userName AS user,
                                    lt.*     AS data
                             FROM lapsed.lapse_taabel lt
                             WHERE id = doc_id
                            ) row;

        UPDATE lapsed.lapse_taabel
        SET nomid   = doc_nomid,
            kogus   = doc_kogus,
            kuu     = doc_kuu,
            aasta   = doc_aasta,
            muud    = doc_muud,
            ajalugu = coalesce(ajalugu, '[]') :: JSONB || json_ajalugu,
            staatus = doc_staatus
        WHERE id = doc_id RETURNING id
            INTO doc_id;

    END IF;


    RETURN doc_id;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            RETURN 0;


END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_lapse_taabel(JSONB, INTEGER, INTEGER) TO arvestaja;

CREATE OR REPLACE FUNCTION lapsed.sp_salvesta_vanem(data JSONB,
                                                    userid INTEGER,
                                                    user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName      TEXT;
    doc_data      JSON    = data ->> 'data';
    doc_id        INTEGER = doc_data ->> 'id';
    doc_parentid  INTEGER = doc_data ->> 'parentid';
    doc_asutusid  INTEGER = doc_data ->> 'asutusid';
    doc_arved     TEXT    = doc_data ->> 'arved';
    doc_suhtumine TEXT    = doc_data ->> 'suhtumine';
    doc_muud      TEXT    = doc_data ->> 'muud';
    json_props    JSONB;
    json_ajalugu  JSONB;

BEGIN

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    SELECT kasutaja INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;
    IF userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;


    json_props = to_jsonb(row)
                 FROM (SELECT doc_arved AS arved, doc_suhtumine AS suhtumine) row;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS created,
                                    userName AS user) row;

        INSERT INTO lapsed.vanemad (parentid, asutusid, muud, properties, ajalugu)
        VALUES (doc_parentid, doc_asutusid, doc_muud, json_props, '[]' :: JSONB || json_ajalugu) RETURNING id
            INTO doc_id;

    ELSE

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS updated,
                                    userName AS user,
                                    l.*      AS data
                             FROM lapsed.vanemad l
                             WHERE id = doc_id
                            ) row;

        UPDATE lapsed.vanemad
        SET asutusid   = doc_asutusid,
            properties = coalesce(properties,'{}'::jsonb)::jsonb || json_props,
            muud       = doc_muud,
            ajalugu    = coalesce(ajalugu, '[]') :: JSONB || json_ajalugu
        WHERE id = doc_id RETURNING id
            INTO doc_id;

    END IF;

    RETURN doc_id;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            RETURN 0;


END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_vanem(JSONB, INTEGER, INTEGER) TO arvestaja;


UPDATE libs.library
SET properties = properties::JSONB || '{"module":["Raamatupidamine","Lapsed"]}'
WHERE library = 'DOK'
  AND kood IN ('ARV','SORDER','SMK');
  
DROP FUNCTION IF EXISTS ou.get_user_data(l_kasutaja TEXT, l_rekvid INTEGER, l_module TEXT);

CREATE OR REPLACE FUNCTION ou.get_user_data(l_kasutaja TEXT, l_rekvid INTEGER, l_module TEXT)
    RETURNS TABLE (
        id             INTEGER,
        rekvid         INTEGER,
        kasutaja       TEXT,
        ametnik        TEXT,
        parool         TEXT,
        kasutaja_      INTEGER,
        peakasutaja_   INTEGER,
        admin          INTEGER,
        muud           TEXT,
        last_login     TIMESTAMP,
        asutus         TEXT,
        allowed_access TEXT[],
        allowed_libs   TEXT[]
    ) AS
$BODY$

SELECT u.id,
       u.rekvid,
       u.kasutaja::TEXT,
       u.ametnik::TEXT,
       u.parool::TEXT,
       u.kasutaja_,
       u.peakasutaja_,
       u.admin,
       u.muud,
       u.last_login,
       r.nimetus::TEXT              AS asutus,
       rs.a::TEXT[]                 AS allowed_access,
       allowed_modules.libs::TEXT[] AS allowed_libs

FROM ou.userid u
         JOIN ou.rekv r ON r.id = u.rekvid AND u.kasutaja::TEXT = l_kasutaja
         JOIN (
    SELECT array_agg('{"id":'::TEXT || r.id::TEXT || ',"nimetus":"'::TEXT || r.nimetus || '"}') AS a
    FROM (
             SELECT r.id, r.nimetus
             FROM ou.rekv r
                      JOIN ou.userid u_1 ON u_1.rekvid = r.id
             WHERE u_1.kasutaja::TEXT = l_kasutaja
         ) r) rs ON rs.a IS NOT NULL
         JOIN (
    SELECT array_agg('{"id":'::TEXT || lib.id::TEXT || ',"nimetus":"'::TEXT || lib.nimetus || '"}')
               AS libs
    FROM (
             SELECT id,
                    kood::TEXT,
                    nimetus::TEXT,
                    library::TEXT                          AS lib,
                    (properties::JSONB -> 'module')::JSONB AS module
             FROM libs.library l
             WHERE l.library = 'DOK'
               AND status <> 3
               AND ((properties::JSONB -> 'module') @> l_module::JSONB OR l_module IS NULL)
         ) lib
) allowed_modules ON allowed_modules.libs IS NOT NULL
WHERE (r.id = l_rekvid OR l_rekvid IS NULL)
ORDER BY u.last_login
LIMIT 1;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

  
