DROP VIEW IF EXISTS rekl.cur_asutus_rekl_jaak;
DROP VIEW IF EXISTS rekl.com_asutus_rekl;
DROP VIEW IF EXISTS rekl.cur_asutus_rekl;

CREATE VIEW rekl.com_asutus_rekl
  AS
    SELECT a.id                                               AS id,
           a.regkood,
           a.nimetus,
           l.rekvid,
           sum(l.summa) FILTER (WHERE NOT empty(l.staatus))   AS summa,
           sum(l.jaak) FILTER (WHERE NOT empty(l.staatus))    AS jaak,
           sum(l.volg) FILTER (WHERE NOT empty(l.staatus))    AS volg,
           sum(l.intress) FILTER (WHERE NOT empty(l.staatus)) AS intress,
           sum(coalesce(e.summa, 0))                          AS ettemaks
    FROM libs.asutus a
           INNER JOIN rekl.luba l ON l.asutusid = a.id
           LEFT OUTER JOIN (SELECT asutusid, summa AS summa, e.rekvid
                            FROM rekl.ettemaksud e
                            WHERE staatus <> 'deleted') e ON e.asutusid = a.id AND l.rekvid = e.rekvid
    GROUP BY a.id, a.regkood, a.nimetus, l.rekvid


GRANT SELECT ON TABLE rekl.com_asutus_rekl TO dbvaatleja;
