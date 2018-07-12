DROP VIEW IF EXISTS cur_toiming;

CREATE VIEW cur_toiming
  AS
    SELECT
      d.id,
      d.rekvid,
      to_char(d.created, 'DD.MM.YYYY HH:MM' :: TEXT)                                AS created,
      to_char(d.lastupdate, 'DD.MM.YYYY HH:MM' :: TEXT)                             AS lastupdate,
      LTRIM(RTRIM(l.number)) + '-' + ltrim(rtrim(t.number :: VARCHAR)) :: VARCHAR   AS number,
      t.asutusid,
      t.lubaid,
      t.kpv,
      t.tahtaeg,
      t.summa,
      t.tyyp,
      t.journalid,
      coalesce(jid.number, 0)                                                       AS lausend,
      coalesce(t.staatus :: TEXT, '')                                               AS status,
      t.saadetud,
      t.failid,
      coalesce(rekl.fnc_dekl_jaak(d.ID), 0)                                         AS jaak,
      t.deklId,
      coalesce('Dekl.nr:' + (SELECT tt.number
                             FROM rekl.toiming tt
                             WHERE tt.id = t.deklid) :: VARCHAR, '') :: VARCHAR(20) AS parandus,

      CASE WHEN t.tyyp = 'DEKL' AND t.staatus IS NOT NULL AND t.saadetud IS NOT NULL
        THEN 'green'
      WHEN t.tyyp = 'DEKL' AND t.staatus IS NOT NULL AND t.saadetud IS NULL AND t.tahtaeg > current_date :: DATE
        THEN 'red'
      ELSE 'white' END :: VARCHAR(20)                                               AS color
    FROM docs.doc d
      INNER JOIN rekl.toiming t ON t.parentid = d.id
      INNER JOIN rekl.luba l ON t.lubaid = l.parentid
      LEFT OUTER JOIN docs.doc dd ON t.journalid = dd.id
      LEFT OUTER JOIN docs.journal j ON j.parentid = dd.id
      LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
    WHERE coalesce(t.staatus :: TEXT, '') <> 'deleted';
