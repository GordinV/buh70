DROP VIEW IF EXISTS cur_toiming;

CREATE VIEW cur_toiming
AS
SELECT *,
       CASE
           WHEN qry.tyyp = 'DEKL' AND qry.staatus IS NOT NULL AND qry.saadetud IS NOT NULL AND qry.jaak <= 0
               THEN 'green' -- отправлена и нет долга
           WHEN qry.tyyp = 'DEKL' AND qry.staatus IS NOT NULL
               AND qry.saadetud IS NOT NULL AND
                COALESCE(qry.tahtaeg, CURRENT_DATE) >
                CURRENT_DATE :: DATE AND qry.jaak > 0
               THEN 'yellow' -- отправлена но не оплачена
       -- декларация не отправленна а срок подачи прошел
           WHEN qry.tyyp = 'DEKL' AND qry.staatus IS NOT NULL
               AND qry.saadetud IS NOT NULL AND
                COALESCE(qry.tahtaeg, CURRENT_DATE) <
                CURRENT_DATE :: DATE AND qry.jaak > 0
               THEN 'red' -- декларация отправленна , но не оплаченна
           WHEN qry.tyyp = 'INTRESS' AND qry.staatus IS NULL
               THEN 'white' -- декларация отправленна , но не оплаченна

           WHEN qry.tyyp = 'INTRESS' AND qry.staatus IS NOT NULL
               AND COALESCE(qry.tahtaeg, CURRENT_DATE) <
                   CURRENT_DATE :: DATE AND qry.jaak > 0
               THEN 'red' -- декларация отправленна , но не оплаченна
           WHEN qry.tyyp = 'INTRESS' AND qry.staatus IS NOT NULL
                    AND COALESCE(qry.tahtaeg, CURRENT_DATE) >
                        CURRENT_DATE :: DATE OR qry.jaak <= 0
               THEN 'green' -- декларация отправленна , но не оплаченна
           ELSE 'white' END :: VARCHAR(20) AS color
FROM (SELECT D.id,
             D.rekvid,
             to_char(D.created, 'DD.MM.YYYY HH:MM' :: TEXT)  AS created,
             to_char(D.lastupdate, 'DD.MM.YYYY HH:MM' ::
                 TEXT)                                       AS lastupdate,
             left(LTRIM(RTRIM(l.number)), position('-' IN l.number)) +
             lpad(ltrim(rtrim(t.number :: VARCHAR)), 2, '0') AS number,
             t.asutusid,
             t.lubaid,
             t.kpv,
             t.tahtaeg,
             t.summa,
             t.tyyp,
             t.journalid,
             COALESCE(jid.number, 0)                         AS lausend,
             COALESCE(t.staatus :: TEXT, '')                 AS status,
             t.saadetud,
             t.failid,
             COALESCE(rekl.fnc_dekl_jaak(D.ID), 0)           AS jaak,
             t.deklId,
             COALESCE('Dekl.nr:' + (SELECT tt.number FROM rekl.toiming tt WHERE tt.id = t.deklid) ::
                 VARCHAR,
                      '') :: VARCHAR(20)                     AS parandus,
             ((t.lisa ->> 'failid') :: JSONB ->> 'fail') ::
                 VARCHAR(254)                                AS fail,
             ((t.lisa ->> 'failid') :: JSONB ->> 'tyyp') ::
                 VARCHAR(20)                                 AS storage_type,
             t.staatus
      FROM docs.doc D
               INNER JOIN rekl.toiming t ON t.parentid = D.id
               INNER JOIN rekl.luba l ON t.lubaid = l.
          parentid
               LEFT OUTER JOIN docs.doc dd ON t.journalid = dd
          .id
               LEFT OUTER JOIN docs.journal j ON j.parentid =
                                                 dd.id
               LEFT OUTER JOIN docs.journalid jid ON jid.
                                                         journalid = j.id
      WHERE COALESCE(t.staatus :: TEXT, '') <>
            'deleted') qry;

GRANT SELECT ON TABLE cur_toiming TO dbvaatleja;
