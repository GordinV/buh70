DROP FUNCTION IF EXISTS libs.check_asutus(tnasutusid INTEGER, tnrekvid INTEGER);

CREATE FUNCTION libs.check_asutus(l_asutusid INTEGER, l_rekvid INTEGER)
    RETURNS BOOLEAN
    LANGUAGE SQL
AS
$$

SELECT (
               (SELECT NOT coalesce((properties::JSON ->> 'is_tootaja')::BOOLEAN, FALSE)
                FROM libs.asutus
                WHERE id = l_asutusid)
               OR exists
                   (
                       SELECT 1
                       FROM palk.tooleping t
                       WHERE t.parentId = l_asutusid
                         AND t.rekvid = l_rekvid
                       UNION
                       SELECT 1
                       FROM docs.arv
                       WHERE asutusid = l_asutusid
                         AND rekvid = l_rekvid
                       UNION
                       SELECT 1
                       FROM docs.journal j
                       WHERE asutusid = l_asutusid
                         AND j.rekvid = l_rekvid
                       UNION
                       SELECT 1
                       FROM docs.korder1 k
                       WHERE asutusid = l_asutusid
                         AND k.rekvid = l_rekvid
                       UNION
                       SELECT 1
                       FROM docs.mk m
                                INNER JOIN docs.mk1 m1 ON m.id = m1.parentid
                       WHERE m1.asutusid = l_asutusid
                         AND m.rekvid = l_rekvid
                       UNION
                       SELECT 1
                       FROM lapsed.vanem_arveldus v
                       WHERE v.asutusid = l_asutusid
                         AND v.rekvid = l_rekvid
                   ))
$$;


