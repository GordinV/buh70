DROP VIEW IF EXISTS cur_lepingud;

CREATE VIEW cur_lepingud AS
  SELECT
    d.id,
    l.rekvid,
    l.number,
    l.kpv,
    l.tahtaeg,
    l.selgitus :: CHARACTER VARYING(254)                                         AS selgitus,
    ltrim(rtrim(a.nimetus)) :: BPCHAR || ' ' ||
    ltrim(rtrim(a.omvorm)) :: CHARACTER VARYING(254)                             AS asutus,
    l.asutusid,
    COALESCE((objekt.properties :: JSONB ->> 'nait14') :: NUMERIC, 0) :: NUMERIC AS maja,
    COALESCE((objekt.properties :: JSONB ->> 'nait15') :: NUMERIC, 0) :: NUMERIC AS korter,
    COALESCE((objekt.properties :: JSONB ->> 'pakett'), '') :: VARCHAR(254)      AS pakett,
    coalesce(objekt.kood, '') :: VARCHAR(20)                                     AS objkood,
    coalesce(objekt.nimetus, '') :: VARCHAR(254)                                 AS objnimi
  FROM docs.doc d
    JOIN docs.leping1 l ON l.parentid = d.id
    JOIN libs.asutus a ON l.asutusid = a.id
    LEFT JOIN libs.library objekt ON objekt.id = l.objektid;

/*

select * from cur_lepingud
 */