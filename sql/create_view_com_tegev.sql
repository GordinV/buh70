                DROP VIEW IF EXISTS com_tegev;

                CREATE OR REPLACE VIEW com_tegev AS

                  SELECT *
                  FROM (SELECT
                          0                 AS id,
                          '' :: VARCHAR(20) AS kood,
                          '' :: VARCHAR(20) AS nimetus,
                          NULL :: INTEGER   AS rekvId
                        UNION
                        SELECT
                          l.id,
                          l.kood,
                          l.nimetus,
                          l.rekvId
                        FROM libs.Library l
                        WHERE l.library = 'TEGEV'
                              AND l.status <> 3
                       ) qry
                  ORDER BY kood;

                GRANT SELECT ON TABLE com_tegev TO dbkasutaja;
                GRANT SELECT ON TABLE com_tegev TO dbvaatleja;
                GRANT SELECT ON TABLE com_tegev TO dbpeakasutaja;

