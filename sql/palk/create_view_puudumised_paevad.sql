drop VIEW  if EXISTS  palk.puudumised_paevad;

CREATE OR REPLACE VIEW palk.puudumised_paevad AS
    WITH qryKuu AS (
        SELECT unnest(ARRAY [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]) AS kuu
    )
    SELECT p.kpv1, p.kpv2,
           CASE
               WHEN p.kpv1 >= q.alg_kpv AND month(p.kpv1) = month(q.alg_kpv)
                   THEN ((q.alg_kpv + INTERVAL '1 month')::DATE - 1) - p.kpv1 + 1
               WHEN month(p.kpv1) < month(q.alg_kpv) AND month(p.kpv2) = month(q.lopp_kpv)
                   THEN p.kpv2 - make_date(year(q.lopp_kpv), month(q.lopp_kpv), 1) + 1
               WHEN p.kpv1 > q.alg_kpv THEN 0
               ELSE day(q.lopp_kpv)
               END AS paevad,
           p.puudumiste_liik,
           p.lepingid,
           p.tyyp,
           q.kuu
    FROM (SELECT qryKuu.kuu, make_date(2021, qryKuu.kuu, 1)                                             alg_kpv,
                 ((make_date(2021, qryKuu.kuu, 1) + INTERVAL '1 month')::DATE - 1)::DATE AS lopp_kpv
          FROM qryKuu
         ) q,
         palk.puudumine p
    WHERE p.status <> 'deleted';

GRANT SELECT ON TABLE palk.puudumised_paevad TO dbpeakasutaja;
GRANT SELECT ON TABLE palk.puudumised_paevad TO dbkasutaja;
GRANT ALL ON TABLE palk.puudumised_paevad TO dbadmin;
GRANT SELECT ON TABLE palk.puudumised_paevad TO dbvaatleja;
GRANT ALL ON TABLE palk.puudumised_paevad TO taabel;

select distinct * from palk.puudumised_paevad
where lepingid IN (35572, 33856)
  AND puudumiste_liik = 'PUHKUS'
order by kuu, lepingid
--  and paevad > 0

