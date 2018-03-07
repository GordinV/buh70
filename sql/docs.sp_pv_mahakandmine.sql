DROP FUNCTION IF EXISTS docs.sp_pv_oper_mahakandmine( INTEGER );

CREATE OR REPLACE FUNCTION docs.sp_pv_oper_mahakandmine(
  docId INTEGER)
  RETURNS NUMERIC(14, 2) AS
$BODY$

DECLARE
  v_pv_kaart        RECORD;
  json_props        JSONB;
  v_soetmaks        RECORD;
BEGIN
  -- load the card
  SELECT
    po.kpv,
    po.summa,
    pk.id as pv_kaart_id,
    pk.properties
  INTO v_pv_kaart
  FROM docs.doc d
    INNER JOIN docs.pv_oper po ON po.parentid = d.id
    INNER JOIN libs.library pk ON pk.id = po.pv_kaart_id
  WHERE d.id = docId;

  -- prepare json

  SELECT v_pv_kaart.kpv AS mahakantud
  INTO v_soetmaks;
  json_props = v_pv_kaart.properties :: JSONB || row_to_json(v_soetmaks) :: JSONB;

  -- save changes
  UPDATE libs.library
  SET properties = json_props,
    status       = 2 -- closed
  WHERE id = v_pv_kaart.pv_kaart_id;

  RETURN 1;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_pv_oper_mahakandmine(INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_pv_oper_mahakandmine(INTEGER) TO dbpeakasutaja;

/*
SELECT docs.sp_pv_oper_parandus(447);

*/