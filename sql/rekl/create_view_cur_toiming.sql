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
      rekl.fnc_dekl_jaak(t.ID)                                                      AS jaak,
      t.deklId,
      coalesce('Dekl.nr:' + (SELECT tt.number
                             FROM rekl.toiming tt
                             WHERE tt.id = t.deklid) :: VARCHAR, '') :: VARCHAR(20) AS parandus
    FROM docs.doc d
      INNER JOIN rekl.toiming t ON t.parentid = d.id
      INNER JOIN rekl.luba l ON t.lubaid = l.parentid
      LEFT OUTER JOIN docs.doc dd ON t.journalid = dd.id
      LEFT OUTER JOIN docs.journal j ON j.parentid = dd.id
      LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
where coalesce(t.staatus::text,'') <> 'deleted';
