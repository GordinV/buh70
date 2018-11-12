DROP FUNCTION IF EXISTS docs.sp_pv_oper_parandus( INTEGER );

CREATE OR REPLACE FUNCTION docs.sp_pv_oper_parandus(
  tnId INTEGER)
  RETURNS NUMERIC(14, 2) AS
$BODY$

DECLARE
  v_pv_kaart        RECORD;
  v_pv_oper         RECORD;
  json_props        JSONB;
  v_soetmaks        RECORD;
  umberHindamiseKpv DATE;
  a_pv_opers        TEXT [] = enum_range(NULL :: PV_OPERATSIOONID);
BEGIN
  -- load the card
  SELECT
    coalesce((l.properties :: JSONB ->> 'soetkpv') :: DATE, now() :: DATE)                 AS soetkpv,
    coalesce((l.properties :: JSONB ->> 'parhind') :: NUMERIC(12, 2), 0) :: NUMERIC(12, 2) AS parhind,
    coalesce((l.properties :: JSONB ->> 'jaak') :: NUMERIC(12, 2), 0) :: NUMERIC(12, 2)    AS jaak,
    1                                                                                      AS kuurs,
    l.rekvid,
    l.properties
  INTO v_pv_kaart
  FROM libs.library l
  WHERE l.id = tnId;

  -- calculate PV cost

  IF exists(SELECT id
            FROM docs.pv_oper po
            WHERE liik = array_position(a_pv_opers, 'umberhindamine') --5
                  AND po.pv_kaart_id = tnId)
  THEN
    -- otsime umberhindamine
    SELECT max(po.kpv)
    INTO umberHindamiseKpv
    FROM docs.pv_oper po
    WHERE liik = array_position(a_pv_opers, 'umberhindamine')
          AND pv_kaart_id = tnId;

    v_pv_kaart.soetkpv = umberHindamiseKpv;

  END IF;

  SELECT
    coalesce(sum(po.summa)
      FILTER (WHERE liik = array_position(a_pv_opers, 'paigutus')),0)       AS soetmaks,
    coalesce(sum(po.summa)
      FILTER (WHERE liik = array_position(a_pv_opers, 'parandus')),0)       AS parandus,
    coalesce(sum(po.summa)
      FILTER (WHERE liik = array_position(a_pv_opers, 'umberhindamine')),0) AS umberhind
  INTO v_pv_oper
  FROM docs.pv_oper po
  WHERE po.pv_kaart_id = tnId
        AND po.kpv >= date(year(v_pv_kaart.soetkpv),month(v_pv_kaart.soetkpv),1);

  v_pv_kaart.parhind = (CASE WHEN coalesce(v_pv_oper.umberhind, 0) > 0
    THEN v_pv_oper.umberhind
                        ELSE coalesce(v_pv_oper.soetmaks, 0) END) + coalesce(v_pv_oper.parandus, 0);

  -- change soetmaks in the card
  SELECT v_pv_kaart.parhind AS parhind
  INTO v_soetmaks;
  json_props = v_pv_kaart.properties :: JSONB || row_to_json(v_soetmaks) :: JSONB;

  -- save changes
  UPDATE libs.library
  SET properties = json_props
  WHERE id = tnId;

  RETURN v_pv_kaart.parhind;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_pv_oper_parandus(INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_pv_oper_parandus(INTEGER) TO dbpeakasutaja;

/*
SELECT docs.sp_pv_oper_parandus(447);

*/