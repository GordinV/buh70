drop view if exists rekl.com_asutus_rekl;

CREATE VIEW rekl.com_asutus_rekl AS
SELECT a.id,
       a.regkood,
       a.nimetus,
       l.rekvid,
       sum(l.summa) FILTER (WHERE (NOT empty(l.staatus)))   AS summa,
       sum(l.jaak) FILTER (WHERE (NOT empty(l.staatus)))    AS jaak,
       sum(l.volg) FILTER (WHERE (NOT empty(l.staatus)))    AS volg,
       sum(l.intress) FILTER (WHERE (NOT empty(l.staatus))) AS intress,
       sum(COALESCE(e.summa, (0) :: NUMERIC))               AS ettemaks
FROM ((libs.asutus a
  JOIN rekl.luba l ON ((l.asutusid = a.id)))
       LEFT JOIN (SELECT e_1.asutusid, e_1.summa, e_1.rekvid
                  FROM rekl.ettemaksud e_1
                  WHERE (e_1.staatus <> 'deleted' :: DOK_STATUS)) e ON (((e.asutusid = a.id) AND (l.rekvid = e.rekvid))))
GROUP BY a.id, a.regkood, a.nimetus, l.rekvid;


GRANT SELECT ON TABLE rekl.com_asutus_rekl TO dbvaatleja;


