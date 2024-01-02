-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS hooldekodu.create_hootehingud(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION hooldekodu.create_hootehingud(IN user_id INTEGER,
                                                         IN l_doc_id INTEGER,
                                                         OUT error_code INTEGER,
                                                         OUT result INTEGER,
                                                         OUT doc_type_id TEXT,
                                                         OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_rekvid INTEGER = (SELECT rekvid
                        FROM ou.userid u
                        WHERE id = user_id
                        LIMIT 1);


BEGIN
    INSERT INTO hooldekodu.hootehingud (isikid, journalid, dokid, doktyyp, allikas, kpv, summa, tyyp, properties, muud,
                                         rekvid)
    SELECT (a.properties ->> 'isik_id')::INTEGER,
           a.journalid,
           a.parentid,
           'ARV',
           '',
           a.kpv,
           -1 * a1.summa,
           'KULUD',
           jsonb_build_object('arv_rea_id', a1.id),
           'Arve nr.:' || a.number,
           a.rekvid
    FROM docs.arv a
             INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
             INNER JOIN libs.asutus isik ON isik.id = (a.properties ->> 'isik_id')::INTEGER
             INNER JOIN hooldekodu.hooleping h ON h.isikid = isik.id
             INNER JOIN hooldekodu.hooteenused ht ON ht.lepingid = h.id AND ht.nomid = a1.nomid
    WHERE a.rekvid = 64
      AND a.properties ->> 'isik_id' IS NOT NULL
      AND a.parentid NOT IN (SELECT dokid FROM hooldekodu.hootehingud WHERE status < 3)
    ORDER BY a.id DESC;

-- 111946
    GET DIAGNOSTICS result = ROW_COUNT;

    RETURN;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_code = 1;
            error_message = SQLERRM;
            result = 0;
            RETURN;
END ;
$BODY$ LANGUAGE plpgsql
    VOLATILE
    COST 100;

REVOKE EXECUTE ON FUNCTION hooldekodu.create_hootehingud(INTEGER, INTEGER) FROM dbkasutaja;
REVOKE EXECUTE ON FUNCTION hooldekodu.create_hootehingud(INTEGER, INTEGER) FROM dbpeakasutaja;


/*


select * from ou.userid where rekvid = 64 and kasutaja = 'vlad'

select hooldekodu.create_hootehingud(3196, 2380341)

delete from hooldekodu.hootehingud where ettemaksid is null

select * from hooldekodu.hootehingud
 */