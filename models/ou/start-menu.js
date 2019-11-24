module.exports = {
    sqlString: `SELECT DISTINCT *
                FROM (
                         SELECT trim(BOTH '"' FROM module::TEXT)::TEXT AS id,
                                '0'                                    AS parentId,
                                trim(BOTH '"' FROM module::TEXT)       AS kood,
                                trim(BOTH '"' FROM module::TEXT)       AS name,
                                NULL::TEXT                             AS props,
                                TRUE                                   AS is_node
                         FROM (SELECT DISTINCT jsonb_array_elements((properties::JSONB -> 'module')) AS module
                               FROM libs.library l
                               WHERE l.library = 'DOK'
                                 AND l.status < 3) modules
                         UNION ALL
                         SELECT 'document' AS id,
                                'Lapsed'     AS parentId,
                                'document' AS kood,
                                'Dokumendid' AS name,
                                NULL::TEXT   AS props,
                                TRUE         AS is_node
                         UNION ALL
                         -- groups
                         SELECT 'library'    AS id,
                                'Lapsed'     AS parentId,
                                'library'    AS kood,
                                'Püsiandmed' AS name,
                                NULL::TEXT   AS props,
                                TRUE         AS is_node
                         UNION ALL
                         -- groups
                         SELECT 'aruanne'    AS id,
                                'Lapsed'     AS parentId,
                                'aruanne'    AS kood,
                                'Aruanned' AS name,
                                NULL::TEXT   AS props,
                                TRUE         AS is_node
                         UNION ALL
                         SELECT 'settings'    AS id,
                                'Lapsed'     AS parentId,
                                'settings'    AS kood,
                                'Häälestamine' AS name,
                                NULL::TEXT   AS props,
                                TRUE         AS is_node
                         UNION ALL
                         SELECT l.id::TEXT,
                                CASE
                                    WHEN l.properties::JSONB ->> 'type' = 'document' THEN 'document'
                                    WHEN l.properties::JSONB ->> 'type' = 'library' THEN 'library'
                                    WHEN l.properties::JSONB ->> 'type' = 'aruanne' THEN 'aruanne'
                                    WHEN l.properties::JSONB ->> 'type' = 'settings' THEN 'settings'
                                    ELSE
                                        trim(BOTH '"' FROM modules.module::TEXT)::TEXT END AS parentId,
                                ltrim(rtrim(kood))::TEXT                                   AS kood,
                                trim(l.nimetus)::TEXT                                      AS name,
                                properties::TEXT                                           AS props,
                                FALSE                                                      AS is_node
                         FROM libs.library l
                                  LEFT OUTER JOIN (SELECT DISTINCT jsonb_array_elements((properties::JSONB -> 'module')) AS module
                                                   FROM libs.library l
                                                   WHERE l.status < 3
                                                     AND l.library = 'DOK'
                         ) modules ON (properties::JSONB -> 'module')::JSONB @> modules.module
                         WHERE l.library = 'DOK'
                           AND l.status < 3) qry
                WHERE (props::JSONB -> 'module')::JSONB @> '["Lapsed"]'::JSONB
                   OR (upper(id) = upper($1) OR upper(parentid) = upper($1))
    `,
    params: ['rekvId', 'module'] // $1 module
};
