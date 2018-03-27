DROP VIEW IF EXISTS eelarve.kassa_tulud;

CREATE VIEW eelarve.kassa_tulud AS
  SELECT DISTINCT ltrim(rtrim(l.kood)) || '%' AS kood
  FROM libs.library l
  WHERE l.library = 'KASSATULUD' 
  ORDER BY ltrim(rtrim(l.kood)) || '%';
