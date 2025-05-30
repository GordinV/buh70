-- Function: docs.sp_salvesta_mk(json, integer, integer)

DROP FUNCTION IF EXISTS docs.sp_salvesta_pv_oper(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_salvesta_pv_oper(data JSON,
                                                    userid INTEGER,
                                                    user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    pv_oper_id      INTEGER;
    userName        TEXT;
    doc_id          INTEGER        = data ->> 'id';
    doc_data        JSON           = data ->> 'data';
    doc_typeId      INTEGER        = (SELECT id
                                      FROM libs.library
                                      WHERE ltrim(rtrim(kood)) = ltrim(rtrim(upper('PV_OPER')))
                                        AND library = 'DOK'
                                      LIMIT 1);
    doc_asutusid    INTEGER        = doc_data ->> 'asutusid';
    doc_kpv         DATE           = doc_data ->> 'kpv';
    doc_pv_kaart_id INTEGER        = doc_data ->> 'pv_kaart_id';
    doc_nomid       INTEGER        = doc_data ->> 'nomid';
    doc_muud        TEXT           = doc_data ->> 'muud';
    doc_liik        INTEGER        = doc_data ->> 'liik';
    doc_doklausid   INTEGER        = doc_data ->> 'doklausid';
    doc_summa       NUMERIC(12, 2) = doc_data ->> 'summa';
    doc_konto       TEXT           = doc_data ->> 'konto';
    doc_korr_konto  TEXT           = doc_data ->> 'korr_konto';
    doc_tunnus      TEXT           = doc_data ->> 'tunnus';
    doc_tp          TEXT           = doc_data ->> 'tp';
    doc_proj        TEXT           = doc_data ->> 'proj';
    doc_kood1       TEXT           = doc_data ->> 'kood1';
    doc_kood2       TEXT           = doc_data ->> 'kood2';
    doc_kood3       TEXT           = doc_data ->> 'kood3';
    doc_kood4       TEXT           = doc_data ->> 'kood4';
    doc_kood5       TEXT           = doc_data ->> 'kood5';
    new_history     JSONB;
    docs            INTEGER[];
    a_pv_opers      TEXT[]         = enum_range(NULL :: PV_OPERATSIOONID);
    is_import       BOOLEAN        = data ->> 'import';
    l_korr_konto    TEXT;
BEGIN

    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;
    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE exception  'Viga: User not found %', user;
    END IF;

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    -- проврека на контировку с 2024 года
    IF doc_kpv >= '2024-01-01' AND (coalesce(doc_doklausid, 0) = 0 OR
                                    NOT exists(SELECT 1
                                               FROM libs.dokprop dokprop
                                               WHERE dokprop.id = doc_doklausid
                                                 AND registr = 1))

    THEN
        RAISE EXCEPTION 'Viga, Alates 01.01.2024 konteerimine on kohuslik';
    END IF;

    -- контроль над двойной операцией постановке на учет
        if doc_liik = 1 and exists (select id from docs.pv_oper po where po.liik = 1 and po.pv_kaart_id = doc_pv_kaart_id
                                                                     and po.parentid <> coalesce(doc_id,0) ) then
            RAISE EXCEPTION 'Viga, toppelt arvelevõit operatsioon on keelatud';
        end if;

    -- вставка или апдейт docs.doc

    IF doc_id IS NULL OR doc_id = 0
    THEN

        SELECT row_to_json(row)
        INTO new_history
        FROM (SELECT now()    AS created,
                     userName AS user) row;


        INSERT INTO docs.doc (doc_type_id, history, rekvid, status)
        VALUES (doc_typeId, '[]' :: JSONB || new_history, user_rekvid, 1);
--        RETURNING id    INTO doc_id;
        SELECT currval('docs.doc_id_seq') INTO doc_id;


        INSERT INTO docs.pv_oper (parentid, kpv, pv_kaart_id, nomid, liik, summa, muud, kood1, kood2, kood3, kood4,
                                  kood5,
                                  konto, tp, asutusid, tunnus, proj, doklausid)
        VALUES (doc_id, doc_kpv, doc_pv_kaart_id, doc_nomid, doc_liik, doc_summa, doc_muud,
                CASE WHEN doc_kood1 IS NOT NULL AND lower(doc_kood1) = 'null' THEN NULL ELSE doc_kood1 END,
                CASE WHEN doc_kood2 IS NOT NULL AND lower(doc_kood2) = 'null' THEN NULL ELSE doc_kood2 END,
                CASE WHEN doc_kood3 IS NOT NULL AND lower(doc_kood3) = 'null' THEN NULL ELSE doc_kood3 END,
                CASE WHEN doc_kood4 IS NOT NULL AND lower(doc_kood4) = 'null' THEN NULL ELSE doc_kood4 END,
                CASE WHEN doc_kood5 IS NOT NULL AND lower(doc_kood5) = 'null' THEN NULL ELSE doc_kood5 END,
                doc_konto,
                CASE WHEN doc_tp IS NOT NULL AND lower(doc_tp) = 'null' THEN NULL ELSE doc_tp END,
                doc_asutusid, doc_tunnus, doc_proj, doc_doklausid) RETURNING id
                   INTO pv_oper_id;

    ELSE
        SELECT row_to_json(row)
        INTO new_history
        FROM (SELECT now()    AS updated,
                     userName AS user) row;

        -- устанавливаем связи с документами

        -- получим связи документа
        SELECT docs_ids
        INTO docs
        FROM docs.doc
        WHERE id = doc_id;

        UPDATE docs.doc
        SET doc_type_id = doc_typeId,
            docs_ids    = docs,
            lastupdate  = now(),
            history     = coalesce(history, '[]') :: JSONB || new_history
        WHERE id = doc_id;


        UPDATE docs.pv_oper
        SET kpv       = doc_kpv,
            nomid     = doc_nomid,
            liik      = doc_liik,
            summa     = doc_summa,
            muud      = doc_muud,
            kood1     = doc_kood1,
            kood2     = doc_kood2,
            kood3     = doc_kood3,
            kood4     = doc_kood4,
            kood5     = doc_kood5,
            konto     = doc_konto,
            tp        = doc_tp,
            asutusid  = doc_asutusid,
            tunnus    = doc_tunnus,
            proj      = doc_proj,
            doklausid = doc_doklausid
        WHERE parentid = doc_id RETURNING id
            INTO pv_oper_id;

    END IF;

    IF pv_oper_id IS NOT NULL AND pv_oper_id > 0
    THEN
        IF doc_liik = array_position(a_pv_opers, 'paigutus') -- will calculate summa and change card status
        THEN
            PERFORM docs.sp_pv_oper_paigutus(doc_id);
        ELSEIF doc_liik = array_position(a_pv_opers, 'parandus')
        THEN
            PERFORM docs.sp_pv_oper_parandus(doc_pv_kaart_id, doc_id, userid); --will calculate parhind
        ELSEIF doc_liik = array_position(a_pv_opers, 'umberhindamine')
        THEN
            PERFORM docs.sp_pv_oper_umberhindamine(doc_pv_kaart_id); --will calculate parhind
        ELSEIF doc_liik = array_position(a_pv_opers, 'mahakandmine')
        THEN
            PERFORM docs.sp_pv_oper_mahakandmine(doc_id);
        ELSEIF doc_liik = 6
        THEN
            -- переквалификация
            IF doc_konto = '154000'
            THEN
                -- запоминаем кор.счет карточки
                SELECT properties::JSONB ->> 'konto'
                INTO l_korr_konto
                FROM libs.library
                WHERE id = doc_pv_kaart_id;

                UPDATE libs.library
                SET properties = properties::JSONB || jsonb_build_object('korr_konto', l_korr_konto)
                WHERE id = doc_pv_kaart_id;

            END IF;

            PERFORM docs.pv_umberklassifitseerimine(doc_id);
        ELSE
            -- ничего
        END IF;
        -- calculation of jaak
    END IF;
    PERFORM docs.sp_recalc_pv_jaak(doc_pv_kaart_id);

    RETURN doc_id;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_salvesta_pv_oper(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_pv_oper(JSON, INTEGER, INTEGER) TO dbpeakasutaja;

/*
select docs.sp_salvesta_pv_oper(
  '{"id":0,"data":{"asutus":null,"asutusid":null,"bpm":"","created":"","doc":"","doc_status":null,"doc_type_id":"POHIVARA","doklausid":null,"dokprop":null,"id":0,"journalid":null,"konto":"113","kood":null,"kood1":"null","kood2":"null","kood3":"null","kood4":null,"kood5":"null","korrkonto":"","kpv":"20180303","kuurs":1,"lastupdate":"","laus_nr":null,"liik":2,"muud":null,"nimetus":null,"nomid":68,"proj":null,"pv_kaart_id":null,"regkood":null,"status":"0","summa":1.6700,"tp":null,"tunnus":null,"userid":1,"valuuta":"EUR"}}'
  ,1,1)
*/