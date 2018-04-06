DROP FUNCTION IF EXISTS palk.get_taotlus_mvt_data(isik_id INTEGER, rekv_id INTEGER );

CREATE FUNCTION palk.get_taotlus_mvt_data(isik_id INTEGER, rekv_id INTEGER)
  RETURNS TABLE(id             INTEGER, lepingId INTEGER, kuu INTEGER, aasta INTEGER,
                taotluse_summa NUMERIC(14, 2), mvt_summa NUMERIC(14, 2), muud TEXT, amet VARCHAR(254)) AS $$
DECLARE
  v_taotlus   RECORD;
  tmpPalkJaak RECORD;
  l_kuud      INTEGER;
  l_kuu       INTEGER;
  l_aasta     INTEGER;
  i           INTEGER;
BEGIN
  FOR v_taotlus IN
  SELECT
    t.*,
    amet.nimetus AS amet
  FROM palk.taotlus_mvt t
    INNER JOIN palk.tooleping l ON l.id = t.lepingid
    INNER JOIN libs.library amet ON amet.id = l.ametid
  WHERE l.parentid = isik_id AND l.rekvid = rekv_id
        AND t.status <> 'deleted'
  ORDER BY t.alg_kpv, t.lepingid
  LOOP
    l_kuud =
    (YEAR(v_taotlus.lopp_kpv) - YEAR(v_taotlus.alg_kpv)) * 12 + (MONTH(v_taotlus.lopp_kpv) - month(v_taotlus.alg_kpv)) +
    1;

    l_kuu = month(v_taotlus.alg_kpv);
    l_aasta = YEAR(v_taotlus.alg_kpv);
    FOR i IN 1..l_kuud LOOP
      SELECT sum(mvt) AS mvt
      INTO tmpPalkJaak
      FROM (SELECT
              p.kuu,
              p.aasta,
              p.lepingId,
              p.g31 AS mvt,
              t.parentId,
              t.rekvId
            FROM palk.palk_jaak p
              INNER JOIN palk.tooleping t ON t.id = p.lepingid
            WHERE t.parentid = isik_id
                  AND t.rekvid = rekv_id
            ORDER BY p.aasta, p.kuu, p.lepingid) AS CURPALKJAAK_MVT
      WHERE CURPALKJAAK_MVT.kuu = l_kuu
            AND CURPALKJAAK_MVT.aasta = l_aasta
            AND CURPALKJAAK_MVT.lepingid = v_taotlus.lepingid;

      RETURN QUERY SELECT
                     v_taotlus.id,
                     v_taotlus.lepingid,
                     l_kuu,
                     l_aasta,
                     v_taotlus.summa,
                     coalesce(tmpPalkJaak.mvt,0)::numeric,
                     v_taotlus.muud,
                     v_taotlus.amet::VARCHAR(254);

      l_kuu = l_kuu + 1;
      IF l_kuu > 12
      THEN
        l_kuu = 1;
        l_aasta = l_aasta + 1;
      END IF;
    END LOOP;

  END LOOP;
END;
$$
LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION palk.get_taotlus_mvt_data(isik_id INTEGER, rekv_id INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.get_taotlus_mvt_data(isik_id INTEGER, rekv_id INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.get_taotlus_mvt_data(isik_id INTEGER, rekv_id INTEGER) TO dbvaatleja;

/*
select * from palk.get_taotlus_mvt_data(1, 1)
 */