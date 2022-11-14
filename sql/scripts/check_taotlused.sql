DROP FUNCTION IF EXISTS eelarve.check_taotlused();

CREATE FUNCTION eelarve.check_taotlused()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_taotlused      RECORD;
    l_count   INTEGER = 0;
BEGIN

    FOR v_taotlused IN
        select * from (
                          SELECT t.id,
                                 t.rekvid,
                                 koostajaid,
                                 koostaja,
                                 (select id from ou.userid u where kasutaja = t.koostaja and u.rekvid = t.rekvid limit 1) user_id,
                                 aktseptid,
                                 kpv,
                                 number,
                                 aasta,
                                 kuu,
                                 t.status AS status,
                                 allkiri,
                                 kood1,
                                 kood2,
                                 kood3,
                                 kood4,
                                 kood5,
                                 tunnus,
                                 summa,
                                 summa_kassa,
                                 oodatav_taitmine,
                                 parentid,
                                 regkood,
                                 nimetus::VARCHAR(254),
                                 t.ametnik::VARCHAR(254),
                                 rea_selg::TEXT,
                                 dok_mark::TEXT
                          FROM (SELECT d.id,
                                       t.rekvid,
                                       t.koostajaid,
                                       t.aktseptid,
                                       t.kpv,
                                       t.number,
                                       t.aasta,
                                       t.kuu,
                                       t.status                             AS status,
                                       t.allkiri,
                                       coalesce(t1.kood1, '')::VARCHAR(20)  AS kood1,
                                       coalesce(t1.kood2, '')::VARCHAR(20)  AS kood2,
                                       coalesce(t1.kood3, '')::VARCHAR(20)  AS kood3,
                                       coalesce(t1.kood4, '')::VARCHAR(20)  AS kood4,
                                       coalesce(t1.kood5, '')::VARCHAR(20)  AS kood5,
                                       coalesce(t1.tunnus, '')::VARCHAR(20) AS tunnus,
                                       t1.summa,
                                       t1.summa_kassa,
                                       t1.oodatav_taitmine,
                                       Rekv.parentid,
                                       Rekv.regkood,
                                       Rekv.nimetus,
                                       Userid.ametnik,
                                       t1.selg as rea_selg,
                                       t.muud as dok_mark,
                                       d.history->0->>'user' as koostaja
                                FROM docs.doc d
                                         INNER JOIN eelarve.taotlus t ON d.id = t.parentid
                                         INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
                                         INNER JOIN ou.rekv rekv ON t.rekvid = Rekv.id
                                         LEFT OUTER JOIN ou.userid userid ON t.koostajaid = Userid.id
                                WHERE d.status <> 3) t
                      ) qry
        where status = 3
          and koostajaid is null
        LOOP
            update eelarve.taotlus set koostajaid = v_taotlused.user_id where parentid = v_taotlused.id and koostajaid is null;
            l_count = l_count + 1;
        END LOOP;
    RETURN l_count;

END;
$$;

SELECT eelarve.check_taotlused();

DROP FUNCTION IF EXISTS eelarve.check_taotlused();
