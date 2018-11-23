DROP VIEW IF EXISTS cur_volgnik;

CREATE VIEW cur_volgnik
  AS
    SELECT
      qryVolgnik.id,
      qryVolgnik.rekvid,
      qryVolgnik.regkood,
      qryVolgnik.nimetus,
      qryVolgnik.volg    AS volg,
      qryVolgnik.jaak    AS jaak,
      qryVolgnik.intress AS intress
    FROM (
           SELECT
             a.id,
             l.rekvid,
             a.regkood,
             a.nimetus,
             sum(l.volg)    AS volg,
             sum(l.jaak)    AS jaak,
             sum(l.intress) AS intress
           FROM libs.asutus a
             INNER JOIN rekl.luba l ON (a.id = l.asutusid)
           WHERE l.staatus > 0
                 AND l.staatus <> 3
           GROUP BY a.id, a.regkood, a.nimetus, l.rekvid
         ) qryVolgnik
    WHERE qryVolgnik.volg <> 0


GRANT SELECT ON TABLE cur_volgnik TO dbvaatleja;

  /*
  select * from cur_volgnik

  select * from rekl.luba

  update rekl.luba set jaak = 100, staatus = 1 where id  = 39
   */