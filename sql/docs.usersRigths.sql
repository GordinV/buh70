-- Function: docs.sp_lausendikontrol(json)

-- DROP FUNCTION docs.sp_lausendikontrol(json);

CREATE OR REPLACE FUNCTION docs.usersRigths(docId INTEGER, command TEXT, userId INTEGER)
    RETURNS BOOLEAN AS
$BODY$
SELECT (exists(
                SELECT 1
                FROM docs.doc d
                WHERE id = docId
                  AND d.rigths -> command @> to_jsonb(userId)::JSONB)
    OR exists(
                SELECT 1
                FROM ou.userid u
                WHERE id = userId
                    AND (((
                            (u.roles ->> 'is_kasutaja')::BOOLEAN OR
                            (u.roles ->> 'is_vaatleja')::BOOLEAN OR
                            (u.roles ->> 'is_peakasutaja')::BOOLEAN)
                             )
                        AND exists(
                                 SELECT 1
                                 FROM docs.doc d
                                          INNER JOIN libs.library l ON d.doc_type_id = l.id
                                 WHERE d.id = docId
                                   AND (l.properties :: JSONB -> 'module')::JSONB <@
                                       to_jsonb(ARRAY ['Raamatupidamine','Palk','Pohivara'])
                                   AND l.library = 'DOK'
                             ))
                   OR ((((u.roles ->> 'is_rekl_administraator')::BOOLEAN) OR
                        (u.roles ->> 'is_rekl_maksuhaldur')::BOOLEAN)
                    AND exists(
                               SELECT 1
                               FROM docs.doc d
                                        INNER JOIN libs.library l ON d.doc_type_id = l.id
                               WHERE d.id = docId
                                 AND (l.properties :: JSONB -> 'module')::JSONB <@ to_jsonb(ARRAY ['Rekl'])
                                 AND l.library = 'DOK'))
                   OR (((u.roles ->> 'is_eel_esitaja')::BOOLEAN OR
                        (u.roles ->> 'is_vaatleja')::BOOLEAN OR
                        (u.roles ->> 'is_eel_koostaja')::BOOLEAN OR
                        (u.roles ->> 'is_eel_aktsepterja')::BOOLEAN OR
                        (u.roles ->> 'is_eel_allkirjastaja')::BOOLEAN)
                    AND exists(
                               SELECT 1
                               FROM docs.doc d
                                        INNER JOIN libs.library l ON d.doc_type_id = l.id
                               WHERE d.id = docId
                                 AND (l.properties :: JSONB -> 'module')::JSONB <@ to_jsonb(ARRAY ['Eelarve'])
                                 AND l.library = 'DOK'))
                   OR (SELECT (d.rigths -> command) @> to_jsonb(ARRAY [userId])
                       FROM docs.doc d
                       WHERE id = docId)
            )
           );
$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT ALL ON FUNCTION docs.usersRigths(docId INTEGER, command TEXT, userId INTEGER) TO dbadmin;
GRANT EXECUTE ON FUNCTION docs.usersRigths(docId INTEGER, command TEXT, userId INTEGER) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.usersRigths(docId INTEGER, command TEXT, userId INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.usersRigths(docId INTEGER, command TEXT, userId INTEGER) TO dbpeakasutaja;

/*
select rigths, docs.usersRigths(d.id, 'select', 1) from docs.doc d where id = 294142

select roles->>'is_rekl_administraator',* from ou.userid where id = 1

select d.rigths, (d.rigths -> 'select') @> to_jsonb(array[3]) 
		from docs.doc d where id = 297419


update docs.doc set rigths = '[]' where id = 294142

select * from docs.doc where id = 294142

alter table docs.doc disable trigger trigU_doc_before_rights

		*/