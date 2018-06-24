DROP VIEW IF EXISTS rekl.dekl_jaak;
CREATE VIEW rekl.dekl_jaak AS
  SELECT
    t.id                                  AS deklid,
    t.asutusid,
    t.summa                               AS dekl,
    coalesce(qryTasud.tasu, 0) :: NUMERIC AS tasu,
    t.tyyp
  FROM rekl.toiming t
    LEFT OUTER JOIN (
                      SELECT
                        deklid,
                        sum(summa) AS tasu
                      FROM rekl.dekltasu
                      GROUP BY deklid
                    ) qryTasud ON qryTasud.deklid = t.id
  WHERE t.tyyp IN ('DEKL', 'INTRESS', 'PARANDUS')


/*
select * from rekl.dekl_jaak
 */