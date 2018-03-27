DROP VIEW IF EXISTS eelarve.fakt_tulud;

CREATE VIEW eelarve.fakt_tulud AS
  SELECT DISTINCT ltrim(rtrim((l.kood))) || '%'  AS kood
  FROM libs.library l
  WHERE l.library = 'TULUKONTOD'
  ORDER BY ltrim(rtrim((l.kood))) || '%';
