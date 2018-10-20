DROP FUNCTION IF EXISTS palk.tsm_toend( DATE, DATE, INTEGER );

CREATE OR REPLACE FUNCTION palk.tsm_toend(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER)
  RETURNS TABLE(
    isik_id   INTEGER,
    isikukood VARCHAR(20),
    isik      VARCHAR(254),
    aadress   TEXT,
    summa     NUMERIC(14, 2),
    tulumaks  NUMERIC(14, 2),
    pm        NUMERIC(14, 2),
    tki       NUMERIC(14, 2),
    arvsm     NUMERIC(14, 2),
    sm        NUMERIC(14, 2),
    tululiik  VARCHAR(20),
    nimetus   VARCHAR(20),
    maar      INTEGER
  ) AS
$BODY$

SELECT
  a.id                                                               AS isik_id,
  a.regkood :: VARCHAR(20)                                           AS isikukood,
  a.nimetus :: VARCHAR(254)                                          AS isik,
  a.aadress :: TEXT,
  sum(po.summa) :: NUMERIC(14, 2)                                    AS summa,
  sum(po.tulumaks) :: NUMERIC(14, 2)                                 AS tulumaks,
  sum(po.pensmaks) :: NUMERIC(14, 2)                                 AS pm,
  sum(po.tootumaks) :: NUMERIC(14, 2)                                AS tki,
  sum(po.summa)
    FILTER (WHERE (l.properties :: JSONB ->> 'sots') :: INTEGER = 1) AS arvsm,
  sum(po.sotsmaks) :: NUMERIC(14, 2)                                 AS sm,
  po.tululiik :: VARCHAR(20)                                         AS tululiik,
  m.nimetus :: VARCHAR(254)                                          AS nimetus,
  m.tun1 :: INTEGER                                                  AS maar
FROM palk.palk_oper po
  INNER JOIN palk.tooleping t ON po.lepingid = t.id
  INNER JOIN libs.asutus a ON a.id = t.parentid
  INNER JOIN libs.library l ON l.id = po.libid
  INNER JOIN libs.library m ON m.kood = po.tululiik AND m.library = 'MAKSUKOOD'
WHERE
  po.kpv >= l_kpv1 AND po.kpv <= l_kpv2
  AND (l.properties :: JSONB ->> 'liik') :: INTEGER = 1 -- tulud
  AND po.rekvid = l_rekvid
GROUP BY po.tululiik, a.id, a.regkood, a.nimetus, a.aadress, m.nimetus, m.tun1

$BODY$
LANGUAGE SQL VOLATILE
COST 100;

/*

SELECT *
FROM palk.tsm_toend('2018-01-01', '2018-12-31', 63);

*/