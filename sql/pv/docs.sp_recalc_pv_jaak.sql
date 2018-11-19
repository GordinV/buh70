DROP FUNCTION IF EXISTS docs.sp_recalc_pv_jaak(INTEGER, DATE);
DROP FUNCTION IF EXISTS docs.sp_recalc_pv_jaak(INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_recalc_pv_jaak(
  pv_id INTEGER)
  RETURNS NUMERIC AS
$BODY$

DECLARE
  v_pv_kaart RECORD;
  v_pv_oper  RECORD;
  l_jaak     NUMERIC(12, 2) = 0;
  json_jaak  JSONB;
  json_props JSONB;
BEGIN
  -- get pv_kaart
  SELECT coalesce((l.properties :: JSONB ->> 'soetkpv') :: DATE, now() :: DATE) AS soetkpv,
         coalesce((l.properties :: JSONB ->> 'algkulum') :: NUMERIC(12, 2), 0)  AS algkulum,
         l.properties
      INTO v_pv_kaart
  FROM libs.library l
  WHERE l.id = pv_id;

  -- select summ
  SELECT coalesce(sum(summa)
               FILTER (WHERE liik = 1),1) AS soetmaks,
         coalesce(sum(summa)
               FILTER (WHERE liik = 2),0) AS kulum,
         coalesce(sum(summa)
               FILTER (WHERE liik = 3),0) AS parandus,
         coalesce(sum(summa)
               FILTER (WHERE liik = 5),0) AS umberhind
      INTO v_pv_oper
  FROM docs.pv_oper po
  WHERE pv_kaart_id = pv_id
    AND po.kpv >= date(year(v_pv_kaart.soetkpv), month(v_pv_kaart.soetkpv), 1);

  -- calculation

  l_jaak = (CASE WHEN coalesce(v_pv_oper.umberhind, 0) > 0
    THEN v_pv_oper.umberhind
            ELSE coalesce(v_pv_oper.soetmaks, 0) END)
           + coalesce(v_pv_oper.parandus, 0) - v_pv_kaart.algkulum - coalesce(v_pv_oper.kulum, 0);

  SELECT row_to_json(row)
      INTO json_jaak
  FROM (SELECT l_jaak                                                                         AS jaak,
               (CASE
                  WHEN coalesce(v_pv_oper.umberhind, 0) > 0
                          THEN v_pv_oper.umberhind
                  ELSE coalesce(v_pv_oper.soetmaks, 0) END) + coalesce(v_pv_oper.parandus, 0) AS parhind,
               (CASE
                  WHEN coalesce(v_pv_oper.umberhind, 0) > 0
                          THEN v_pv_oper.umberhind
                  ELSE coalesce(v_pv_oper.soetmaks, 0) END)                                   AS soetmaks,
               coalesce(v_pv_kaart.algkulum, 0) + coalesce(v_pv_oper.kulum, 0)                AS kulum_kokku) row;

  json_props = v_pv_kaart.properties :: JSONB || json_jaak :: JSONB;

  -- save changes
  UPDATE libs.library SET properties = json_props WHERE id = pv_id;

  RETURN l_jaak;

END;$BODY$
LANGUAGE plpgsql
VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_recalc_pv_jaak(INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_recalc_pv_jaak(INTEGER) TO dbpeakasutaja;

/*
SELECT docs.sp_recalc_pv_jaak(213051);

select * from libs.library order by id desc limit 1
*/