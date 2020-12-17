DROP VIEW IF EXISTS com_artikkel;

CREATE OR REPLACE VIEW com_artikkel AS

SELECT *
FROM (SELECT 0                AS id,
             '':: VARCHAR(20) AS kood,
             '':: VARCHAR(20) AS nimetus,
             NULL :: INTEGER  AS rekvId,
             TRUE             AS is_kulud,
             NULL::DATE       AS valid
      UNION
      SELECT l.id,
             l.kood,
             l.nimetus,
             l.rekvId,
             (CASE WHEN l.tun5 = 1 THEN FALSE ELSE TRUE END) AS is_kulud,
             (l.properties::JSONB ->> 'valid')::DATE
      FROM libs.library l
      WHERE l.library = 'TULUDEALLIKAD'
        AND l.status <> 3
      UNION ALL
      SELECT 3655000                                   AS id,
             '3, 655'                                  AS kood,
             'Tulud (siirded eelarvesse, tagastamine)' AS nimetus,
             999999                                    AS rekvid,
             FALSE                                     AS is_kulud,
             NULL::DATE                                AS valid
      UNION ALL
      SELECT 152586456            AS id,
             '15,2586,4,5,6'      AS kood,
             'Põhitegevuse kulud' AS nimetus,
             999999               AS rekvid,
             TRUE                 AS is_kulud,
             NULL::DATE           AS valid
      UNION ALL
      SELECT 152586454            AS id,
             '1,2,3,6'                  AS kood,
             'Tulud' AS nimetus,
             999999               AS rekvid,
             FALSE                AS is_kulud,
             NULL::DATE           AS valid
      UNION ALL

      SELECT 152586455            AS id,
             '3'                  AS kood,
             'Põhitegevuse tulud' AS nimetus,
             999999               AS rekvid,
             FALSE                AS is_kulud,
             NULL::DATE           AS valid
      UNION ALL
      SELECT 152586457               AS id,
             '2585(A80)'             AS kood,
             'Kohustuse võtmine (Allikas 80)' AS nimetus,
             999999                  AS rekvid,
             FALSE                   AS is_kulud,
             NULL::DATE              AS valid
     ) qry
ORDER BY kood;

GRANT SELECT ON TABLE com_artikkel TO dbkasutaja;
GRANT SELECT ON TABLE com_artikkel TO dbvaatleja;
GRANT SELECT ON TABLE com_artikkel TO dbpeakasutaja;

