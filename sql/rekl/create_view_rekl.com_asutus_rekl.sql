DROP VIEW IF EXISTS rekl.com_asutus_rekl;

CREATE VIEW rekl.com_asutus_rekl AS
SELECT a.id,
       a.regkood,
       a.nimetus,
       l.rekvid,
       sum(l.summa) FILTER (WHERE (NOT empty(l.staatus)))   AS summa,
       sum(l.jaak) FILTER (WHERE (NOT empty(l.staatus)))    AS jaak,
       sum(l.volg) FILTER (WHERE (NOT empty(l.staatus)))    AS volg,
       sum(l.intress) FILTER (WHERE (NOT empty(l.staatus))) AS intress,
       max(COALESCE(e.summa, (0) :: NUMERIC))               AS ettemaks,
       l_a.kas_arhiiv
FROM ((libs.asutus a
    JOIN rekl.luba l ON ((l.asutusid = a.id)))
    LEFT JOIN (SELECT e_1.asutusid, sum(e_1.summa) AS summa, e_1.rekvid
               FROM rekl.ettemaksud e_1
               WHERE (e_1.staatus <> 'deleted' :: DOK_STATUS)
                   GROUP BY asutusid
                   , rekvid
    ) e ON (((e.asutusid = a.id) AND (l.rekvid = e.rekvid))))
         INNER JOIN (SELECT asutusid,
                            max(CASE
                                -- только текущего года разрешения но нет долга и не полученных разрешений
                                    WHEN year(algkpv) <> year(current_date) AND year(loppkpv) <> year(current_date)
                                        AND coalesce(volg, 0) = 0
                                        AND NOT exists(
                                                SELECT 1
                                                FROM rekl.toiming t
                                                WHERE lubaid = l.parentid
                                                  AND saadetud IS NULL
                                                  AND t.tyyp = 'DEKL'
                                                  AND t.staatus IS NULL)
                                        THEN 0
                                -- аннулированные
                                    WHEN staatus = 0 THEN 0
                                    ELSE 1 END) AS kas_arhiiv
                     FROM rekl.luba l
                     GROUP BY asutusid) AS l_a ON l_a.asutusid = a.id
GROUP BY a.id, a.regkood, a.nimetus, l.rekvid, l_a.kas_arhiiv;


GRANT SELECT ON TABLE rekl.com_asutus_rekl TO dbvaatleja;
GRANT SELECT ON TABLE rekl.com_asutus_rekl TO dbkasutaja;


SELECT *
FROM rekl.com_asutus_rekl
WHERE regkood = '11958746'