DROP FUNCTION IF EXISTS libs.check_asutus(tnasutusid INTEGER, tnrekvid INTEGER );

CREATE FUNCTION libs.check_asutus(l_asutusid INTEGER, l_rekvid INTEGER)
  RETURNS BOOLEAN
LANGUAGE SQL
AS $$
SELECT not exists
       (SELECT 1
        FROM palk.tooleping t
        WHERE t.parentId = l_asutusid
              AND t.rekvid = l_rekvid)
       OR EXISTS(SELECT 1
                 FROM docs.arv
                 WHERE asutusid = l_asutusid
                       AND rekvid = l_rekvid)
       OR exists(SELECT 1
                 FROM docs.journal j
                 WHERE asutusid = l_asutusid
                       AND j.rekvid = l_rekvid)
       OR exists(SELECT 1
                 FROM docs.korder1 k
                 WHERE asutusid = l_asutusid
                       AND k.rekvid = l_rekvid)
       OR exists(SELECT 1
                 FROM docs.mk m
                   INNER JOIN docs.mk1 m1 ON m.id = m1.parentid
                 WHERE m1.asutusid = l_asutusid AND m.rekvid = l_rekvid)
$$;

