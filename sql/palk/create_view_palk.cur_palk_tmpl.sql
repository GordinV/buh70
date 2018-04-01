DROP VIEW IF EXISTS palk.cur_palk_tmpl;

CREATE VIEW palk.cur_palk_tmpl AS
  SELECT
    *,
    (enum_range(NULL :: PALK_OPER_LIIK)) [qry.liik] AS liik_,
    (enum_range(NULL :: PALK_TUND_LIIK)) [qry.tund] AS tund_,
    CASE WHEN maks = 1
      THEN 'JAH'
    ELSE 'EI' END                                   AS maks_
  FROM (
         SELECT
           pk.id,
           pk.parentid,
           pk.libid,
           pk.summa,
           pk.percent_,
           pk.tulumaks,
           pk.tulumaar,
           pk.status,
           pk.muud,
           pk.tunnus,
           amet.kood                                          AS amet,
           l.kood,
           l.nimetus,
           (l.properties :: JSONB ->> 'liik') :: INTEGER      AS liik,
           (l.properties :: JSONB ->> 'tund') :: INTEGER      AS tund,
           (l.properties :: JSONB ->> 'maks') :: INTEGER      AS maks,
           (l.properties :: JSONB ->> 'asutusest') :: INTEGER AS asutusest,
           CASE WHEN coalesce((l.properties :: JSONB ->> 'tululiik'), '99') = ''
             THEN '99'
           ELSE (l.properties :: JSONB ->> 'tululiik') END    AS tululiik,
           l.rekvid
         FROM libs.library l
           INNER JOIN palk.palk_tmpl pk ON pk.libId = l.id
           LEFT OUTER JOIN library amet ON amet.id = pk.parentid
         WHERE pk.status <> 'deleted'
         ORDER BY liik,
           COALESCE((l.properties :: JSONB ->> 'tululiik'), '99'),
           pk.percent_ DESC, pk.summa DESC) qry;

/*
select * from palk.cur_palk_tmpl
 */