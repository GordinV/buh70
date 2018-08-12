drop view if exists cur_asutused;

CREATE VIEW cur_asutused AS
  SELECT
    a.id,
    a.regkood,
    a.nimetus,
    a.omvorm,
    a.aadress,
    a.tp,
    a.email,
    a.mark,
    ((a.properties ->> 'kehtivus' :: TEXT)) :: DATE AS kehtivus,
    a.staatus
  FROM libs.asutus a
  WHERE (a.staatus <> 3);
