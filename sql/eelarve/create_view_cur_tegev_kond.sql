DROP VIEW IF EXISTS cur_tegev_kond;

CREATE VIEW cur_tegev_kond AS
    SELECT 1 AS id, '01'::varchar(20) AS kood, 'ÜLDISED VALITSUSSEKTORI TEENUSED' AS nimetus
    UNION ALL
    SELECT 2 AS id, '02'::varchar(20) AS kood, 'RIIGIKAITSE' AS nimetus
    UNION ALL
    SELECT 3 AS id, '03'::varchar(20) AS kood, 'AVALIK KORD JA JULGEOLEK' AS nimetus
    UNION ALL
    SELECT 4 AS id, '04'::varchar(20) AS kood, 'MAJANDUS' AS nimetus
    UNION ALL
    SELECT 5 AS id, '05'::varchar(20) AS kood, 'KESKKONNAKAITSE' AS nimetus
    UNION ALL
    SELECT 6 AS id, '06'::varchar(20) AS kood, 'ELAMU- JA KOMMUNAALMAJANDUS' AS nimetus
    UNION ALL
    SELECT 7 AS id, '07'::varchar(20) AS kood, 'TERVISHOID' AS nimetus
    UNION ALL
    SELECT 8 AS id, '08'::varchar(20) AS kood, 'VABA AEG, KULTUUR, RELIGIOON' AS nimetus
    UNION ALL
    SELECT 9 AS id, '09'::varchar(20) AS kood, 'HARIDUS' AS nimetus
    UNION ALL
    SELECT 10 AS id, '10'::varchar(20) AS kood, 'SOTSIAALNE KAITSE' AS nimetus


GRANT SELECT ON TABLE cur_tegev_kond TO dbkasutaja;
GRANT SELECT ON TABLE cur_tegev_kond TO dbvaatleja;
GRANT SELECT ON TABLE cur_tegev_kond TO dbpeakasutaja;

/*
select len(kood), * from cur_tegev_kond
*/