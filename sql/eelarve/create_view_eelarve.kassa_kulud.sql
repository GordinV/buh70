DROP VIEW IF EXISTS eelarve.kassa_kulud;

CREATE VIEW eelarve.kassa_kulud AS
  SELECT DISTINCT ltrim(rtrim(l.kood)) || '%'  AS kood
  FROM libs.library l
  WHERE l.library = 'KASSAKULUD'
  ORDER BY ltrim(rtrim(l.kood)) || '%';
