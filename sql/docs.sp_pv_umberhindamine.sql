DROP FUNCTION IF EXISTS docs.sp_pv_oper_umberhindamine( INTEGER );

CREATE OR REPLACE FUNCTION docs.sp_pv_oper_umberhindamine(
  tnId INTEGER)
  RETURNS NUMERIC(14, 2) AS
$BODY$

DECLARE
  v_pv_kaart RECORD;
  json_props JSONB;
  v_soetmaks RECORD;
  a_pv_opers TEXT [] = enum_range(NULL :: PV_OPERATSIOONID);
  a_dokvaluuta        TEXT [] = enum_range(NULL :: DOK_VALUUTA);

BEGIN
  -- load the card
  SELECT
    l.properties
  INTO v_pv_kaart
  FROM libs.library l
  WHERE l.id = tnId;

  -- load last umberhindamine summa

  SELECT (po.summa * coalesce(v.kuurs, 1)) :: NUMERIC(14, 2) AS parhind
  INTO v_soetmaks
  FROM docs.pv_oper po
    LEFT OUTER JOIN docs.dokvaluuta1 v ON v.dokid = po.id AND dokliik = array_position(a_dokvaluuta, 'pv_oper')
  WHERE po.pv_kaart_id = tnId
        AND liik = array_position(a_pv_opers, 'umberhindamine')
  ORDER BY kpv DESC
  LIMIT 1;

  -- change soetmaks in the card
  json_props = v_pv_kaart.properties :: JSONB || row_to_json(v_soetmaks) :: JSONB;

  -- save changes
  UPDATE libs.library
  SET properties = json_props
  WHERE id = tnId;

  RETURN v_soetmaks.parhind;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_pv_oper_umberhindamine(INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_pv_oper_umberhindamine(INTEGER) TO dbpeakasutaja;

/*
SELECT docs.sp_pv_oper_parandus(447);

*/