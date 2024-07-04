DROP FUNCTION IF EXISTS docs.sp_pv_oper_paigutus(INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_pv_oper_paigutus(
    doc_id INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    v_pv_kaart RECORD;
    json_props JSONB;
    json_soet  JSONB;
    v_soetmaks RECORD;
BEGIN
    -- load the card
--    po.*,
    SELECT po.pv_kaart_id,
           po.summa,
           po.kpv,
           pk.*
    INTO v_pv_kaart
    FROM docs.doc d
             INNER JOIN docs.pv_oper po ON po.parentid = d.id
             INNER JOIN libs.library pk ON pk.id = po.pv_kaart_id
    WHERE d.id = doc_id;

    -- change pv_kaart status (next status = 1)
    v_pv_kaart.status = 1;

    -- change soetmaks in the card
    SELECT v_pv_kaart.summa AS soetmaks,
           v_pv_kaart.summa AS parhind,
           v_pv_kaart.kpv   AS soetkpv
    INTO v_soetmaks;

    json_soet = row_to_json(v_soetmaks) :: JSONB;

    json_props = v_pv_kaart.properties :: JSONB || row_to_json(v_soetmaks) :: JSONB;


    -- save changes
    UPDATE libs.library
    SET properties = json_props,
        status     = v_pv_kaart.status
    WHERE id = v_pv_kaart.pv_kaart_id;

    RETURN doc_id;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_pv_oper_paigutus(INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_pv_oper_paigutus(INTEGER) TO dbpeakasutaja;

/*
SELECT docs.sp_pv_oper_paigutus(1069);

*/