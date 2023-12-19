/*
DROP TABLE IF EXISTS tmp_isikud;
CREATE TABLE IF NOT EXISTS tmp_isikud (ik text);

INSERT INTO tmp_isikud(ik)
SELECT ltrim(rtrim(t.f[1]))::text   AS ik
FROM (
         SELECT regexp_split_to_array(l, ';') AS f
         FROM regexp_split_to_table(
                      $$ik
36303143717
36303143717
37112170045
37112170045
45711033716
45711033716
46204183715
46204183715
46302203724
46302203724
46311293731
46311293731
46312132212
46312132212
46606163712
46606163712
46710273713
46710273713
46804033714
46804033714
46805173720
46805173720
46805173720
47105313726
47105313726
47109149519
47109149519
47202112266
47202112266
47206122216
47206122216
47206122216
47302232238
47302232238
47304142238
47304142238
47311263712
47311263712
47408273731
47408273731
47409273769
47409273769
47505143714
47505143714
47509043717
47509043717
47610023731
47610023731
47701123719
47701123719
47808082240
47808082240
47901253719
47901253719
47901253719
47903155216
47903155216
48001113715
48001113715
48001113715
48002263717
48002263717
48002263717
48105143715
48105143715
48105143715
48106163712
48106163712
48407243718
48407243718
48506203710
48506203710
48509090119
48509090119
48509243720
48509243720
48603053721
48603053721
48711193719
48711193719$$, '\n') AS l) t;

DROP TABLE IF EXISTS tmp_kontol;
CREATE TABLE IF NOT EXISTS tmp_kontol (        ik text,
                                               nimi text,
                                               aadress text,
                                               kas_tootaja BOOLEAN,
                                               palk_asutused text,
                                               isiku_aa text,
                                               priznak_aa text,
                                               platel_ko text,
                                               iban text,
                                               e_arve BOOLEAN
);

*/
DROP FUNCTION IF EXISTS lapsed.asutuste_kontrol();

CREATE FUNCTION lapsed.asutuste_kontrol()
    RETURNS TABLE (
        ik            TEXT,
        nimi          TEXT,
        aadress       TEXT,
        kas_tootaja   BOOLEAN,
        palk_asutused TEXT,
        isiku_aa      TEXT,
        platel_ko     TEXT,
        iban          TEXT,
        e_arve        TEXT
    )
AS
$BODY$
SELECT a.regkood::TEXT                                                                  AS ik,
       ltrim(rtrim(a.nimetus))::TEXT                                                    AS nimi,
       ltrim(rtrim(a.aadress))::TEXT,
       exists(SELECT id FROM palk.tooleping t WHERE t.parentid = a.id AND t.status < 3) AS kas_tootaja,
       pa.asutused::TEXT                                                                AS palk_asutused,
       aa.aa::TEXT                                                                         isiku_aa,
       ko.asutused::TEXT                                                                AS platel_ko,
       ko.iban::TEXT                                                                    AS iban,
       ko.earve::TEXT                                                                   AS e_arve
FROM libs.asutus a
         LEFT OUTER JOIN (
    SELECT a.id,
           array_to_string(get_unique_value_from_array(array_agg(ltrim(rtrim(r.nimetus)))), ',') AS asutused
    FROM palk.tooleping t
             INNER JOIN libs.asutus a ON a.id = t.parentid
             INNER JOIN ou.rekv r ON r.id = t.rekvid
    WHERE t.status < 3
      AND ltrim(rtrim(a.regkood)) IN (SELECT left(i.ik, 11) FROM tmp_isikud i)
    GROUP BY a.id
) pa ON pa.id = a.id
         LEFT OUTER JOIN (
    SELECT qry.id, array_to_string(get_unique_value_from_array(array_agg(qry.aa || ' ' || qry.tyyp)), ',') AS aa
    FROM (
             SELECT a.id,
                    (e.element ->> 'aa') :: VARCHAR(20) AS aa,
                    CASE
                        WHEN coalesce(((e.element ->> 'kas_palk') :: BOOLEAN), FALSE) THEN 'PALK'
                        WHEN coalesce(((e.element ->> 'kas_raama') :: BOOLEAN), FALSE) THEN 'RAAMA'
                        WHEN coalesce(((e.element ->> 'kas_oppetasu') :: BOOLEAN), FALSE) THEN 'OPPETASU'
                        ELSE '' END                     AS tyyp
             FROM libs.asutus a,
                  json_array_elements(CASE
                                          WHEN (a.properties ->> 'asutus_aa') IS NULL THEN '[]'::JSON
                                          ELSE (a.properties -> 'asutus_aa') :: JSON END) AS e (element)
             WHERE ltrim(rtrim(a.regkood)) IN (SELECT left(i.ik, 11) FROM tmp_isikud i)
         ) qry
    GROUP BY id
) aa ON aa.id = a.id
         LEFT OUTER JOIN (
    SELECT a.id,
           array_to_string(get_unique_value_from_array(array_agg(ltrim(rtrim(r.nimetus)))), ',') AS asutused,
           array_to_string(get_unique_value_from_array(array_agg(coalesce(va.properties ->> 'iban', ''))),
                           ',')                                                                  AS iban,
           array_to_string(get_unique_value_from_array(array_agg(CASE
                                                                     WHEN coalesce((va.properties ->> 'kas_earve')::BOOLEAN, FALSE)::BOOLEAN
                                                                         THEN 'Jah'
                                                                     ELSE 'Ei' END)),
                           ',')                                                                  AS earve
    FROM libs.asutus a
             INNER JOIN lapsed.vanem_arveldus va ON va.asutusid = a.id AND va.arveldus
             INNER JOIN ou.rekv r ON r.id = va.rekvid
    WHERE ltrim(rtrim(a.regkood)) IN (SELECT left(i.ik, 11) FROM tmp_isikud i)
    GROUP BY a.id
) ko ON ko.id = a.id
WHERE a.regkood IN (SELECT left(i.ik, 11) FROM tmp_isikud i)
ORDER BY a.regkood ;

$BODY$
    LANGUAGE SQL
    VOLATILE;

SELECT * from lapsed.asutuste_kontrol();

DROP FUNCTION IF EXISTS lapsed.asutuste_kontrol();

