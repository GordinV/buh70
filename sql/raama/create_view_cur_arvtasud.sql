DROP VIEW IF EXISTS cur_arvtasud;

CREATE OR REPLACE VIEW cur_arvtasud AS
  SELECT
    arv.id                                                        AS arvid,
    arv.rekvid,
    arv.number,
    arv.kpv                                                       AS arvkpv,
    arv.summa                                                     AS arvsumma,
    arv.tahtaeg,
    arv.liik,
    asutus.nimetus                                                AS asutus,
    arvtasu.kpv,
    arvtasu.summa,
    arvtasu.id,
    arvtasu.doc_tasu_id,
    coalesce(arv.objekt, space(20)) :: CHARACTER VARYING          AS objekt,
    (CASE WHEN arvtasu.pankkassa = 3
      THEN 'JOURNAL'
     WHEN arvtasu.pankkassa = 1
       THEN 'MK'
     WHEN arvtasu.pankkassa = 2
       THEN 'KASSA' END) :: TEXT                                  AS dok_type,
    (CASE WHEN arvtasu.pankkassa = 3
      THEN jid.number :: TEXT || to_char(j.kpv, 'DD.MM.YYYY')
     WHEN arvtasu.pankkassa = 1
       THEN m.number || to_char(m.kpv, 'DD.MM.YYYY')
     WHEN arvtasu.pankkassa = 2
       THEN k.number || to_char(k.kpv, 'DD.MM.YYYY') END) :: TEXT AS dok,

    CASE
    WHEN arvtasu.pankkassa = 1
      THEN 'MK' :: CHARACTER VARYING
    WHEN arvtasu.pankkassa = 2
      THEN 'KASSA' :: CHARACTER VARYING
    WHEN arvtasu.pankkassa = 3
      THEN 'RAAMAT' :: CHARACTER VARYING
    ELSE 'MUUD' :: CHARACTER VARYING
    END                                                           AS tasuliik,
    coalesce(dokvaluuta1.valuuta, 'EUR') :: CHARACTER VARYING(20) AS valuuta,
    coalesce(dokvaluuta1.kuurs, 1 :: NUMERIC)                     AS kuurs,
    arvtasu.status
  FROM docs.arvtasu arvtasu
    JOIN docs.arv arv ON arvtasu.doc_arv_id = arv.id
    JOIN libs.asutus asutus ON asutus.id = arv.asutusid
    LEFT JOIN docs.dokvaluuta1 ON arvtasu.id = dokvaluuta1.dokid AND dokvaluuta1.dokliik = 10
    LEFT OUTER JOIN docs.journal j ON j.parentid = arvtasu.doc_tasu_id
    LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
    LEFT OUTER JOIN docs.mk m ON m.parentid = arvtasu.doc_tasu_id
    LEFT OUTER JOIN docs.korder1 k ON k.parentid = arvtasu.doc_tasu_id

  WHERE arvtasu.status <> 3;

GRANT SELECT ON TABLE cur_arvtasud TO dbpeakasutaja;
GRANT SELECT ON TABLE cur_arvtasud TO dbkasutaja;
GRANT SELECT ON TABLE cur_arvtasud TO dbvaatleja;

