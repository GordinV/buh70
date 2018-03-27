DROP VIEW IF EXISTS eelarve.kassa_kontod;

CREATE VIEW eelarve.kassa_kontod AS
  SELECT DISTINCT ltrim(rtrim(l.kood))|| '%'  AS kood
  FROM libs.library l
  WHERE l.library = 'KASSAKONTOD' 
  ORDER BY ltrim(rtrim(l.kood))|| '%';
