DROP VIEW IF EXISTS palk.cur_palk_kaart;

CREATE VIEW palk.cur_palk_kaart AS
SELECT *,
       coalesce(((enum_range(NULL :: PALK_OPER_LIIK))[qry.liik])::VARCHAR(10), '')::VARCHAR(10) AS liik_,
       (enum_range(NULL :: PALK_TUND_LIIK))[qry.tund]                                           AS tund_,
       CASE
           WHEN maks = 1
               THEN 'JAH'
           ELSE 'EI' END                                                                        AS maks_
FROM (
         SELECT pk.id,
                pk.parentid,
                pk.lepingid,
                pk.libid,
                pk.summa,
                pk.percent_,
                pk.tulumaks,
                pk.tulumaar,
                pk.status,
                pk.muud,
                pk.alimentid,
                pk.tunnus,
                osakond.kood                                             AS osakond,
                osakond.id                                               AS osakondId,
                amet.kood                                                AS amet,
                l.kood,
                l.nimetus,
                (l.properties :: JSONB ->> 'liik') :: INTEGER            AS liik,
                (l.properties :: JSONB ->> 'tund') :: INTEGER            AS tund,
                (l.properties :: JSONB ->> 'maks') :: INTEGER            AS maks,
                (l.properties :: JSONB ->> 'asutusest') :: INTEGER       AS asutusest,
                (l.properties :: JSONB ->> 'tunnusid') :: NUMERIC(12, 4) AS tunnusid,
                (l.properties :: JSONB ->> 'round') :: NUMERIC(12, 4)    AS round,
                'EUR' :: VARCHAR                                         AS valuuta,
                1 :: NUMERIC                                             AS kuurs,
                CASE
                    WHEN coalesce((l.properties :: JSONB ->> 'tululiik'), '99') = ''
                        THEN '99'
                    ELSE (l.properties :: JSONB ->> 'tululiik') END      AS tululiik,
                pk.minsots,
                t.rekvid
         FROM libs.library l
                  INNER JOIN palk.palk_kaart pk ON pk.libId = l.id
                  LEFT OUTER JOIN palk.tooleping t ON pk.lepingId = t.id
                  LEFT OUTER JOIN libs.library amet ON amet.id = t.ametid
                  LEFT OUTER JOIN libs.library osakond ON osakond.id = t.osakondid
         WHERE pk.status <> 3) qry;


GRANT SELECT ON TABLE palk.cur_palk_kaart TO dbkasutaja;
GRANT SELECT ON TABLE palk.cur_palk_kaart TO dbvaatleja;
GRANT SELECT ON TABLE palk.cur_palk_kaart TO dbpeakasutaja;

/*

select (enum_range(null :: palk_oper_liik))[1]

Do Case
		Case v_palk_kaart.liik = 1
			Replace v_palk_kaart.liik_ With '+' In v_palk_kaart
		Case v_palk_kaart.liik = 2
			Replace v_palk_kaart.liik_ With '-' In v_palk_kaart
		Case v_palk_kaart.liik = 3
			Replace v_palk_kaart.liik_ With '%' In v_palk_kaart
	Endcase

select * from libs.library where library = 'PALK'
 */