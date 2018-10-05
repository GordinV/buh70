DROP VIEW IF EXISTS eelarve.kassa_tulud;

CREATE OR replace VIEW eelarve.kassa_tulud AS
  SELECT DISTINCT ltrim(rtrim(l.kood)) || '%' AS kood
FROM libs.library l
WHERE l.library = 'KASSATULUD'
