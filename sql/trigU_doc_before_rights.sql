-- управление правами в зависимости от статуса

DROP FUNCTION IF EXISTS docs.trigU_doc_before_rights() CASCADE;
DROP FUNCTION IF EXISTS trigU_doc_before_rights() CASCADE;

CREATE FUNCTION docs.trigu_doc_before_rights()
  RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  doc_rigths   JSONB;
  author       TEXT = 'vlad';
  author_id    INTEGER = 0;
  muud_roles   TEXT;
  history_json JSON;
  muud_rigths  JSONB;
  is_eelarve   BOOLEAN = (new.doc_type_id IN (
    SELECT id
    FROM libs.library
    WHERE (properties :: JSON ->> 'module') :: TEXT ILIKE '%eelarve%'
  ));
  is_rekl      BOOLEAN = (new.doc_type_id IN (
    SELECT id
    FROM libs.library
    WHERE (properties :: JSON ->> 'module') :: TEXT ILIKE '%rekl%'
  ));

BEGIN

  -- 1 (ативный. Права согласно роли)
  -- 2 (закрыт, права на просмотр, на редактирование прав нет, удаление у peakasutaja)
  -- 3 (удален, права на просмотр только у peakasutaja)

  author = ((new.history) -> 0) ->> 'user';
  SELECT
    id,
    muud
  INTO author_id, muud_roles
  FROM ou.userid
  WHERE kasutaja = author AND rekvId = new.rekvid
  LIMIT 1;

  CASE
    WHEN new.status = 0
    THEN
      -- 0 (черновик. Права только у автора)
      -- ищем автора в истории документа


      SELECT row_to_json(row)
      INTO doc_rigths
      FROM
        (SELECT
           ARRAY [author_id] AS "select",
           ARRAY [author_id] AS "update",
           ARRAY [author_id] AS "delete") row;

      IF is_eelarve
      THEN
        -- will find add rights for eelarve module ("EelAktsepterja,EelKoostaja, EelAllkirjastaja, Eelesitaja")
        SELECT row_to_json(row)
        INTO muud_rigths
        FROM
          (SELECT
             (CASE WHEN muud_roles ILIKE '%' || 'EelAllkirjastaja' || '%'
               THEN ARRAY [author_id]
              ELSE ARRAY [0] END) :: INTEGER [] AS EelAllkirjastaja,
             (CASE WHEN muud_roles ILIKE '%' || 'EelKoostaja' || '%'
               THEN ARRAY [author_id]
              ELSE ARRAY [0] END) :: INTEGER [] AS EelKoostaja,
             (CASE WHEN muud_roles ILIKE '%' || 'EelAktsepterja' || '%'
               THEN ARRAY [author_id]
              ELSE ARRAY [0] END) :: INTEGER [] AS EelAktsepterja,
             (CASE WHEN muud_roles ILIKE '%' || 'Eelesitaja' || '%'
               THEN ARRAY [author_id]
              ELSE ARRAY [0] END) :: INTEGER [] AS Eelesitaja
          ) row;
        doc_rigths = doc_rigths || muud_rigths;
      END IF;

      IF is_rekl
      THEN
        -- will find add rights for eelarve module ("EelAktsepterja,EelKoostaja, EelAllkirjastaja, Eelesitaja")
        SELECT row_to_json(row)
        INTO muud_rigths
        FROM
          (SELECT
             (CASE WHEN muud_roles ILIKE '%' || 'reklMaksuhaldur' || '%'
               THEN ARRAY [author_id]
              ELSE ARRAY [0] END) :: INTEGER [] AS reklMaksuhaldur,
             (CASE WHEN muud_roles ILIKE '%' || 'reklAdministraator' || '%'
               THEN ARRAY [author_id]
              ELSE ARRAY [0] END) :: INTEGER [] AS reklAdministraator
          ) ROW;
      END IF;

    WHEN new.status = array_position((enum_range(NULL :: DOK_STATUS)), 'active')
    THEN
      SELECT row_to_json(row)
      INTO doc_rigths
      FROM
        (SELECT
           array(SELECT id
                 FROM ou.userid
                 WHERE (kasutaja_ = 1 OR peakasutaja_ = 1) AND rekvid = new.rekvid) AS "update",
           array(SELECT id
                 FROM ou.userid
                 WHERE (kasutaja_ = 1 OR peakasutaja_ = 1) AND rekvid = new.rekvid) AS "delete",
           array(SELECT id
                 FROM ou.userid
                 WHERE rekvid = new.rekvid)                                         AS "select") row;

      IF is_eelarve
      THEN
        -- will find add rights for eelarve module ("EelAktsepterja,EelKoostaja, EelAllkirjastaja, Eelesitaja")
        SELECT row_to_json(row)
        INTO muud_rigths
        FROM
          (SELECT
             array(SELECT id
                   FROM ou.userid
                   WHERE muud ILIKE '%EelAktsepterja%' AND rekvid = new.rekvid)   AS "EelAktsepterja",
             array(SELECT id
                   FROM ou.userid
                   WHERE muud ILIKE '%EelKoostaja%' AND rekvid = new.rekvid)      AS "EelKoostaja",
             array(SELECT id
                   FROM ou.userid
                   WHERE muud ILIKE '%EelAllkirjastaja%' AND rekvid = new.rekvid) AS "EelAllkirjastaja",
             array(SELECT id
                   FROM ou.userid
                   WHERE muud ILIKE '%Eelesitaja%' AND rekvid = new.rekvid)       AS "Eelesitaja") row;


        doc_rigths = doc_rigths || muud_rigths;

      END IF;


      IF is_rekl
      THEN
        -- will find add rights for eelarve module ("EelAktsepterja,EelKoostaja, EelAllkirjastaja, Eelesitaja")
        SELECT row_to_json(row)
        INTO muud_rigths
        FROM
          (SELECT
             array(SELECT id
                   FROM ou.userid
                   WHERE muud ILIKE '%reklAdministraator%' AND rekvid = new.rekvid)   AS "reklAdministraator",
             array(SELECT id
                   FROM ou.userid
                   WHERE muud ILIKE '%reklMaksuhaldur%' AND rekvid = new.rekvid)      AS "reklMaksuhaldur") row;

        doc_rigths = doc_rigths || muud_rigths;

      END IF;

  WHEN new.status = array_position((enum_range(NULL :: DOK_STATUS)), 'closed')
    THEN -- closed
      SELECT row_to_json(row)
      INTO doc_rigths
      FROM
        (SELECT
           ARRAY [0]                        AS "update",
           ARRAY [0]                        AS "delete",
           array(SELECT id
                 FROM ou.userid
                 WHERE rekvid = new.rekvid) AS "select") row;

      IF is_eelarve
      THEN
        -- will find add rights for eelarve module ("EelAktsepterja,EelKoostaja, EelAllkirjastaja, Eelesitaja")
        SELECT row_to_json(row)
        INTO muud_rigths
        FROM
          (SELECT
             ARRAY [0] AS "EelAktsepterja",
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
        FROM
          (SELECT
             ARRAY [0] AS "reklMaksuhaldur",
             ARRAY [0] AS "reklAdministraator") row;

        doc_rigths = doc_rigths || muud_rigths;

      END IF;

    WHEN new.status = array_position((enum_range(NULL :: DOK_STATUS)), 'deleted')
    THEN -- deleted
      SELECT row_to_json(row)
      INTO doc_rigths
      FROM
        (SELECT
           ARRAY [0]                                             AS "update",
           ARRAY [0]                                             AS "delete",
           array(SELECT id
                 FROM ou.userid
                 WHERE rekvid = new.rekvid AND peakasutaja_ = 1) AS "select") row;

      IF is_eelarve
      THEN
        -- will find add rights for eelarve module ("EelAktsepterja,EelKoostaja, EelAllkirjastaja, Eelesitaja")
        SELECT row_to_json(row)
        INTO muud_rigths
        FROM
          (SELECT
             ARRAY [0] AS "EelAktsepterja",
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
        FROM
          (SELECT
             ARRAY [0] AS "reklAdministraator",
             ARRAY [0] AS "reklMaksuhaldur") row;

        doc_rigths = doc_rigths || muud_rigths;

      END IF;
  END CASE;

  new.rigths = doc_rigths;
  RETURN new;

END;
$$;


DROP TRIGGER IF EXISTS trigU_doc_before_rights
ON docs.doc;

CREATE TRIGGER trigU_doc_before_rights
BEFORE UPDATE OR INSERT
  ON docs.doc
FOR EACH ROW
EXECUTE PROCEDURE docs.trigU_doc_before_rights();


