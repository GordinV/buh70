-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.update_smk_dokprop_id(IN arve_id INTEGER, IN rekv_id INTEGER);

CREATE OR REPLACE FUNCTION lapsed.update_smk_dokprop_id(arve_id INTEGER, rekv_id INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    l_dokprop_id INTEGER;

BEGIN
    l_dokprop_id = (SELECT dp.id
                    FROM libs.dokprop dp
                             INNER JOIN libs.library l ON l.id = dp.parentid
                    WHERE dp.rekvid = rekv_id
                      AND l.kood = 'SMK'
                    ORDER BY dp.id DESC
                    LIMIT 1
    );
    IF l_dokprop_id IS NOT NULL
    THEN
        UPDATE docs.arv SET doklausid = l_dokprop_id WHERE id = arve_id;
    END IF;

    return 1;
END ;

$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

SELECT lapsed.update_smk_dokprop_id(a.id, a.rekvid)
FROM docs.arv a
WHERE journalid = 0
  AND kpv = '2020-12-31'
  AND rekvid IN (SELECT id FROM ou.rekv WHERE rekv.parentid = 119)
  AND liik = 0
  AND doklausid = 1
  AND muud = 'Alg.saldo';



DROP FUNCTION IF EXISTS lapsed.update_smk_dokprop_id(IN arve_id INTEGER, IN rekv_id INTEGER);
