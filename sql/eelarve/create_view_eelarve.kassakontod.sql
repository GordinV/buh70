DROP VIEW IF EXISTS eelarve.kassa_kontod;

CREATE OR REPLACE VIEW eelarve.kassa_kontod AS
  SELECT DISTINCT ltrim(rtrim(l.kood)) || '%' AS kood
  FROM libs.library l
  WHERE l.library = 'KASSAKONTOD' 
