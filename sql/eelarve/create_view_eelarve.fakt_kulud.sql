DROP VIEW IF EXISTS eelarve.fakt_kulud;

CREATE VIEW eelarve.fakt_kulud AS
  SELECT DISTINCT ltrim(rtrim((kood) :: TEXT)) || '%'  AS kood
  FROM libs.library l
  WHERE l.library = 'KULUKONTOD'
  ORDER BY ltrim(rtrim((kood) :: TEXT)) || '%';




GRANT SELECT ON TABLE eelarve.fakt_kulud TO dbpeakasutaja;
GRANT SELECT ON TABLE eelarve.fakt_kulud TO dbkasutaja;
GRANT SELECT ON TABLE eelarve.fakt_kulud TO dbvaatleja;
GRANT SELECT ON TABLE eelarve.fakt_kulud TO eelaktsepterja;
