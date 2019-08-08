DROP VIEW IF EXISTS palk.com_palk_kaart;

CREATE VIEW palk.com_palk_kaart AS
  SELECT
    pk.id,
    pk.libid,
    pk.lepingid,
    pk.summa,
    pk.minsots,
    l.kood,
    l.nimetus,
    l.rekvid,
    (l.properties::jsonb->>'tegev') as tegev,
    (l.properties::jsonb->>'allikas') as allikas,
    (l.properties::jsonb->>'rahavoog') as rahavoog,
    (l.properties::jsonb->>'artikkel') as artikkel,
    (l.properties::jsonb->>'uritus') as uritus,
    (l.properties::jsonb->>'konto') as konto,
    (l.properties::jsonb->>'proj') as proj,
    (l.properties::jsonb->>'tunnus') as tunnus,
    (l.properties::jsonb->>'liik')::integer as liik,
    (l.properties::jsonb->>'tund')::integer as tund,
    coalesce((l.properties::jsonb->>'percent_')::integer,pk.percent_)::INTEGER as percent_,
    (l.properties::jsonb->>'maks')::integer as tulumaks,
    (l.properties::jsonb->>'asutusest')::integer as asutusest,
    (l.properties::jsonb->>'round')::numeric as round,
    pk.status
  FROM libs.library l
    INNER JOIN palk.palk_kaart pk ON pk.libId = l.id
  WHERE pk.status <> 3;


GRANT SELECT ON TABLE palk.com_palk_kaart TO dbkasutaja;
GRANT SELECT ON TABLE palk.com_palk_kaart TO dbpeakasutaja;
GRANT SELECT ON TABLE palk.com_palk_kaart TO dbvaatleja;
GRANT ALL ON TABLE palk.com_palk_kaart TO dbadmin;
