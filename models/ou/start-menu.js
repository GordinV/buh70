module.exports = {
    sqlString: `SELECT *
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
                         SELECT l.id::TEXT,
                                trim(BOTH '"' FROM modules.module::TEXT)::TEXT AS parentId,
                                ltrim(rtrim(kood))::TEXT                       AS kood,
                                trim(l.nimetus)::TEXT                          AS name,
                                properties::TEXT                               AS props,
                                FALSE                                          AS is_node
                         FROM libs.library l
                                  LEFT OUTER JOIN (SELECT DISTINCT jsonb_array_elements((properties::JSONB -> 'module')) AS module
                                                   FROM libs.library l
                                                   WHERE l.status < 3
                                                     AND l.library = 'DOK'
                         ) modules ON (properties::JSONB -> 'module')::JSONB @> modules.module
                         WHERE l.library = 'DOK'
                           AND l.status < 3) qry
                WHERE (id = $1 OR parentid = $1)
    `,
    params: ['rekvId', 'module']
};
