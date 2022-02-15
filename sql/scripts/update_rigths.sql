DROP FUNCTION IF EXISTS update_rights();

CREATE FUNCTION update_rights()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    doc_rigths   JSONB;
    author       TEXT    = 'vlad';
    author_id    INTEGER = 0;
    muud_roles   TEXT;
    history_json JSON;
    muud_rigths  JSONB;
    is_eelarve   BOOLEAN = FALSE;
    is_rekl      BOOLEAN = FALSE;
    is_lapsed    BOOLEAN = FALSE;
    v_docs       RECORD;
    l_count integer = 0;
BEGIN

    FOR v_docs IN
        SELECT *
        FROM docs.doc
        WHERE status < 3
          AND lastupdate < now() - INTERVAL '3 hours'
--        and id = 158382
        ORDER BY id desc
        LOOP
            is_eelarve = coalesce((v_docs.doc_type_id IN (
                SELECT id
                FROM libs.library
                WHERE (properties :: JSONB ->> 'module') :: TEXT ILIKE '%eelarve%'
                  AND library = 'DOK'
            )), FALSE);
            is_rekl = coalesce((v_docs.doc_type_id IN (
                SELECT id
                FROM libs.library
                WHERE (properties :: JSONB ->> 'module') :: TEXT ILIKE '%rekl%'
                  AND library = 'DOK'
            )), FALSE);

            is_lapsed = coalesce((v_docs.doc_type_id IN (
                SELECT id
                FROM libs.library
                WHERE (properties :: JSONB ->> 'module') :: TEXT ILIKE '%laps%'
                  AND library = 'DOK'
            )), FALSE);

            -- 1 (ативный. Права согласно роли)
            -- 2 (закрыт, права на просмотр, на редактирование прав нет, удаление у peakasutaja)
            -- 3 (удален, права на просмотр только у peakasutaja)

            author = ((v_docs.history) -> 0) ->> 'user';
            SELECT id,
                   muud
            INTO author_id, muud_roles
            FROM ou.userid
            WHERE kasutaja = author
              AND rekvId = v_docs.rekvid
            LIMIT 1;

            CASE
                WHEN v_docs.status = 0
                    THEN
                        -- 0 (черновик. Права только у автора)
                        -- ищем автора в истории документа


                        SELECT row_to_json(row)
                        INTO doc_rigths
                        FROM (SELECT ARRAY [author_id] AS "select",
                                     ARRAY [author_id] AS "update",
                                     ARRAY [author_id] AS "delete") row;

                        IF is_eelarve
                        THEN
                            -- will find add rights for eelarve module ("EelAktsepterja,EelKoostaja, EelAllkirjastaja, Eelesitaja")
                            SELECT row_to_json(row)
                            INTO muud_rigths
                            FROM (SELECT (CASE
                                              WHEN muud_roles ILIKE '%' || 'EelAllkirjastaja' || '%'
                                                  THEN ARRAY [author_id]
                                              ELSE ARRAY [0] END) :: INTEGER[] AS EelAllkirjastaja,
                                         (CASE
                                              WHEN muud_roles ILIKE '%' || 'EelKoostaja' || '%'
                                                  THEN ARRAY [author_id]
                                              ELSE ARRAY [0] END) :: INTEGER[] AS EelKoostaja,
                                         (CASE
                                              WHEN muud_roles ILIKE '%' || 'EelAktsepterja' || '%'
                                                  THEN ARRAY [author_id]
                                              ELSE ARRAY [0] END) :: INTEGER[] AS EelAktsepterja,
                                         (CASE
                                              WHEN muud_roles ILIKE '%' || 'Eelesitaja' || '%'
                                                  THEN ARRAY [author_id]
                                              ELSE ARRAY [0] END) :: INTEGER[] AS Eelesitaja
                                 ) row;
                            doc_rigths = doc_rigths || muud_rigths;
                        END IF;

                        IF is_rekl
                        THEN
                            -- will find add rights for eelarve module ("EelAktsepterja,EelKoostaja, EelAllkirjastaja, Eelesitaja")
                            SELECT row_to_json(row)
                            INTO muud_rigths
                            FROM (SELECT (CASE
                                              WHEN muud_roles ILIKE '%' || 'reklMaksuhaldur' || '%'
                                                  THEN ARRAY [author_id]
                                              ELSE ARRAY [0] END) :: INTEGER[] AS reklMaksuhaldur,
                                         (CASE
                                              WHEN muud_roles ILIKE '%' || 'reklAdministraator' || '%'
                                                  THEN ARRAY [author_id]
                                              ELSE ARRAY [0] END) :: INTEGER[] AS reklAdministraator
                                 ) ROW;
                        END IF;

                WHEN v_docs.status = array_position((enum_range(NULL :: DOK_STATUS)), 'active')
                    THEN
                        SELECT row_to_json(row)
                        INTO doc_rigths
                        FROM (SELECT array(SELECT id
                                           FROM ou.userid
                                           WHERE (kasutaja_ = 1 OR peakasutaja_ = 1 OR
                                                  (roles ->> 'is_kasutaja')::BOOLEAN OR
                                                  (roles ->> 'is_peakasutaja')::BOOLEAN)
                                             AND rekvid = v_docs.rekvid) AS "update",
                                     array(SELECT id
                                           FROM ou.userid
                                           WHERE (kasutaja_ = 1 OR peakasutaja_ = 1 OR
                                                  (roles ->> 'is_kasutaja')::BOOLEAN OR
                                                  (roles ->> 'is_peakasutaja')::BOOLEAN)
                                             AND rekvid = v_docs.rekvid) AS "delete",
                                     array(SELECT id
                                           FROM ou.userid
                                           WHERE rekvid = v_docs.rekvid) AS "select") row;

                        IF is_eelarve
                        THEN
                            -- will find add rights for eelarve module ("EelAktsepterja,EelKoostaja, EelAllkirjastaja, Eelesitaja")
                            SELECT row_to_json(row)
                            INTO muud_rigths
                            FROM (SELECT array(SELECT id
                                               FROM ou.userid
                                               WHERE muud ILIKE '%EelAktsepterja%'
                                                 AND rekvid = v_docs.rekvid) AS "EelAktsepterja",
                                         array(SELECT id
                                               FROM ou.userid
                                               WHERE muud ILIKE '%EelKoostaja%'
                                                 AND rekvid = v_docs.rekvid) AS "EelKoostaja",
                                         array(SELECT id
                                               FROM ou.userid
                                               WHERE muud ILIKE '%EelAllkirjastaja%'
                                                 AND rekvid = v_docs.rekvid) AS "EelAllkirjastaja",
                                         array(SELECT id
                                               FROM ou.userid
                                               WHERE muud ILIKE '%Eelesitaja%'
                                                 AND rekvid = v_docs.rekvid) AS "Eelesitaja") row;


                            doc_rigths = doc_rigths || muud_rigths;

                        END IF;


                        IF is_rekl
                        THEN
                            -- will find add rights for eelarve module ("EelAktsepterja,EelKoostaja, EelAllkirjastaja, Eelesitaja")
                            SELECT row_to_json(row)
                            INTO muud_rigths
                            FROM (SELECT array(SELECT id
                                               FROM ou.userid
                                               WHERE muud ILIKE '%reklAdministraator%'
                                                 AND rekvid = v_docs.rekvid) AS "reklAdministraator",
                                         array(SELECT id
                                               FROM ou.userid
                                               WHERE muud ILIKE '%reklMaksuhaldur%'
                                                 AND rekvid = v_docs.rekvid) AS "reklMaksuhaldur") row;

                            doc_rigths = doc_rigths || muud_rigths;

                        END IF;

                WHEN v_docs.status = array_position((enum_range(NULL :: DOK_STATUS)), 'closed')
                    THEN -- closed
                        SELECT row_to_json(row)
                        INTO doc_rigths
                        FROM (SELECT ARRAY [0]                           AS "update",
                                     ARRAY [0]                           AS "delete",
                                     array(SELECT id
                                           FROM ou.userid
                                           WHERE rekvid = v_docs.rekvid) AS "select") row;

                        IF is_eelarve
                        THEN
                            -- will find add rights for eelarve module ("EelAktsepterja,EelKoostaja, EelAllkirjastaja, Eelesitaja")
                            SELECT row_to_json(row)
                            INTO muud_rigths
                            FROM (SELECT ARRAY [0] AS "EelAktsepterja",
                                         ARRAY [0] AS "EelKoostaja",
                                         ARRAY [0] AS "EelAllkirjastaja",
                                         ARRAY [0] AS "Eelesitaja") row;

                            doc_rigths = doc_rigths || muud_rigths;

                        END IF;

                        IF is_rekl
                        THEN
                            -- will find add rights for eelarve module ("EelAktsepterja,EelKoostaja, EelAllkirjastaja, Eelesitaja")
                            SELECT row_to_json(row)
                            INTO muud_rigths
                            FROM (SELECT ARRAY [0] AS "reklMaksuhaldur",
                                         ARRAY [0] AS "reklAdministraator") row;

                            doc_rigths = doc_rigths || muud_rigths;

                        END IF;

                WHEN v_docs.status = array_position((enum_range(NULL :: DOK_STATUS)), 'deleted')
                    THEN -- deleted
                        SELECT row_to_json(row)
                        INTO doc_rigths
                        FROM (SELECT ARRAY [0]                     AS "update",
                                     ARRAY [0]                     AS "delete",
                                     array(SELECT id
                                           FROM ou.userid
                                           WHERE rekvid = v_docs.rekvid
                                             AND peakasutaja_ = 1) AS "select") row;

                        IF is_eelarve
                        THEN
                            -- will find add rights for eelarve module ("EelAktsepterja,EelKoostaja, EelAllkirjastaja, Eelesitaja")
                            SELECT row_to_json(row)
                            INTO muud_rigths
                            FROM (SELECT ARRAY [0] AS "EelAktsepterja",
                                         ARRAY [0] AS "EelKoostaja",
                                         ARRAY [0] AS "EelAllkirjastaj",
                                         ARRAY [0] AS "Eelesitaja") row;

                            doc_rigths = doc_rigths || muud_rigths;

                        END IF;

                        IF is_rekl
                        THEN
                            -- will find add rights for eelarve module ("EelAktsepterja,EelKoostaja, EelAllkirjastaja, Eelesitaja")
                            SELECT row_to_json(row)
                            INTO muud_rigths
                            FROM (SELECT ARRAY [0] AS "reklAdministraator",
                                         ARRAY [0] AS "reklMaksuhaldur") row;

                            doc_rigths = doc_rigths || muud_rigths;

                        END IF;
                WHEN v_docs.status = 4 -- alg.saaldo
                    THEN
                        SELECT row_to_json(row)
                        INTO doc_rigths
                        FROM (SELECT ARRAY [0]                        AS "update",
                                     ARRAY [0]                        AS "delete",
                                     array(SELECT id
                                           FROM ou.userid
                                           WHERE rekvid = v_docs.rekvid) AS "select") row;
                END CASE;

            UPDATE docs.doc SET rigths = doc_rigths WHERE id = v_docs.id;
            l_count = l_count + 1;
        END LOOP;
    return l_count;

END;
$$;

SELECT update_rights();

DROP FUNCTION IF EXISTS update_rights();

