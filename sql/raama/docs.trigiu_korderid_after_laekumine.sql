-- Function: docs.trigiu_korderid_after_laekumine()

-- DROP FUNCTION docs.trigiu_korderid_after_laekumine();

CREATE OR REPLACE FUNCTION docs.trigiu_korderid_after_laekumine()
    RETURNS TRIGGER AS
$BODY$
DECLARE
    v_userid RECORD;
    lresult  INT;
    lcNotice VARCHAR;
BEGIN

    IF new.arvid IS NOT NULL
    THEN

        DELETE FROM docs.arvtasu WHERE arvid = new.arvid AND doc_tasu_id = new.parentid;

        INSERT INTO docs.arvtasu (rekvid, doc_arv_id, doc_tasu_id, arvid, kpv, summa, dok, pankkassa, journalid,
                                  sorderid, muud, doklausid)
        SELECT k.rekvid,
               a.parentid                                              AS doc_arv_id,
               d.id                                                    AS doc_tasu_id,
               a.id,
               k.kpv,
               CASE WHEN k.tyyp = 1 THEN k.summa ELSE -1 * k.summa END AS summa,
               alltrim(k.number) || ' ' || k.kpv::TEXT                 AS dok,
               1                                                       AS pankkassa,
               NULL                                                    AS journalid,
               k.id                                                    AS sorderid,
               k.muud                                                  AS muud,
               NULL                                                    AS doklausid
        FROM docs.korder1 k
                 INNER JOIN docs.doc d ON d.id = k.parentid
                 INNER JOIN docs.arv a ON a.id = k.arvid
        WHERE k.arvid = new.arvid
          AND d.status > 0;

    END IF;

    IF new.arvid IS NULL AND TG_OP = 'UPDATE' AND old.arvid IS NOT NULL
    THEN
        DELETE FROM docs.arvtasu WHERE arvid = new.arvid AND doc_tasu_id = new.parentid;
    END IF;
    RETURN NULL;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;
ALTER FUNCTION docs.trigiu_korderid_after_laekumine()
    OWNER TO postgres;
