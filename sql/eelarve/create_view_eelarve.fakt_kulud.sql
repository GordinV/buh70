DROP VIEW IF EXISTS eelarve.fakt_kulud;

CREATE VIEW fakt_kulud AS
  SELECT DISTINCT ltrim(rtrim((kood) :: TEXT)) || '%'  AS kood
  FROM libs.library l
  WHERE l.library = 'KULUKONTOD'
  ORDER BY ltrim(rtrim((kood) :: TEXT)) || '%';
