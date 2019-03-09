DROP FUNCTION IF EXISTS libs.get_pv_kaart_jaak(l_id INTEGER, l_kpv DATE);

CREATE OR REPLACE FUNCTION libs.get_pv_kaart_jaak(l_id INTEGER, l_kpv DATE DEFAULT current_date)
  RETURNS TABLE(
    id INTEGER,
    soetmaks NUMERIC(14, 2),
    kulum NUMERIC(14, 2),
    jaak NUMERIC(14, 2),
    eluiga NUMERIC(14, 4),
    turu_vaartsus NUMERIC(14, 4)
    ) AS
$BODY$

WITH pv_kaart AS (
  SELECT l.id,
         (l.properties :: JSONB ->> 'pindala') :: NUMERIC(12, 4)       AS pindala,
         (l.properties :: JSONB ->> 'turu_vaartsus') :: NUMERIC(12, 2) AS turu_vaartsus,
         (l.properties :: JSONB ->> 'algkulum') :: NUMERIC(12, 4)      AS algkulum,
         (l.properties :: JSONB ->> 'kulum') :: NUMERIC(12, 4)         AS kulum_maar,
         l.status -- case status = 2 (mahakantud, jaak = 0)
  FROM libs.library l
  WHERE l.id = l_id
)
SELECT id,
       tapsestatud_hind                                                                AS soetmaks,
       kulum,
       (tapsestatud_hind - kulum)::NUMERIC(14, 2)                                      AS jaak,
       ((tapsestatud_hind - kulum) / (tapsestatud_hind * 12.5 * 0.01))::NUMERIC(14, 4) AS eluiga,
       turu_vaartsus
FROM (
       SELECT
         id                  AS id,
         turu_vaartsus,
         soetmaks,
         umberhindamine,
         kulum               AS kulum,
         CASE
           WHEN umberhindamine > 0
             THEN umberhindamine
           ELSE soetmaks END AS tapsestatud_hind

       FROM (
              SELECT
                p.id,
                p.status,
                p.kulum_maar,
                (CASE
                   WHEN coalesce(p.pindala, 0) > 0 AND coalesce(p.turu_vaartsus, 0) = 0 THEN p.pindala * 425.56
                   ELSE p.turu_vaartsus END)::NUMERIC(14,2)    AS turu_vaartsus,
                coalesce((SELECT sum(summa)
                          FROM docs.pv_oper po
                          WHERE pv_kaart_id = p.id
                            AND liik = 2
                            AND kpv <= l_kpv), 0) + p.algkulum AS kulum,
                coalesce((SELECT sum(summa)
                          FROM docs.pv_oper po
                          WHERE pv_kaart_id = p.id
                            AND liik IN (1)
                            AND kpv <= l_kpv), 0)              AS soetmaks,
                coalesce((SELECT sum(summa)
                          FROM docs.pv_oper po
                          WHERE pv_kaart_id = p.id
                            AND liik = 3
                            AND kpv <= l_kpv
                            AND kpv >=
                                coalesce((SELECT max(kpv)
                                          FROM docs.pv_oper po
                                          WHERE pv_kaart_id = p.id
                                            AND liik = 5
                                            AND kpv <= l_kpv)::DATE,
                                         '19000101'::DATE)
                         ), 0)                                 AS parandus,

                coalesce((SELECT sum(summa)
                          FROM docs.pv_oper po
                          WHERE pv_kaart_id = p.id
                            AND liik = 5
                            AND kpv < l_kpv),
                         0)                                    AS umberhindamine
              FROM pv_kaart p
            ) qry
     ) pre_qry ;

$BODY$
  LANGUAGE SQL
  VOLATILE
  COST 100;

GRANT EXECUTE ON FUNCTION libs.get_pv_kaart_jaak(l_id INTEGER, l_kpv DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION libs.get_pv_kaart_jaak(l_id INTEGER, l_kpv DATE) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION libs.get_pv_kaart_jaak(l_id INTEGER, l_kpv DATE) TO dbkasutaja;


/*
SELECT * from libs.library where kood = 'test' and library = 'POHIVARA'

select * from libs.get_pv_kaart_jaak(209554)
*/