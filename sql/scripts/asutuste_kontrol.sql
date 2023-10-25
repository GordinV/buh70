/*
DROP TABLE IF EXISTS tmp_ebat;
CREATE TABLE IF NOT EXISTS tmp_ebat (number integer, asutus text);

INSERT INTO tmp_ebat(number, asutus)
SELECT t.f[1]::integer   AS number, t.f[2]::text as asutus
FROM (
         SELECT regexp_split_to_array(l, ';') AS f
         FROM regexp_split_to_table(
                      $$37004303743
37004303743
37911193711
37911193711
45812293727
45812293727
45902243713
45902243713
46005043757
46005043757
46101222229
46101222229
46101222229
46103033710
46103033710
46103272252
46103272252
46110292222
46110292222
46307263725
46307263725
46307263725
46310093714
46310093714
46310183713
46310183713
46504012226
46504012226
46603113739
46603113739
46605083737
46605083737
46605083737
46606103714
46606103714
46609093720
46609093720
46706253747
46706253747
46707243712
46707243712
46906152249
46906152249
46911047015
46911047015
47003073715
47003073715
47010123719
47010123719
47011023718
47011023718
47011143716
47011143716
47012263730
47012263730
47111063727
47111063727
47112063710
47112063710
47306063710
47306063710
47311133738
47311133738
47404023719
47404023719
47405303728
47405303728
47407113711
47407113711
47502023712
47502023712
47509073727
47509073727
47512303718
47512303718
47603233717
47603233717
47706063711
47706063711
47707093715
47707093715
47807243717
47807243717
48111042246
48111042246
48206173711
48206173711
48207193719
48207193719
48207193719
48207193719
48305062242
48305062242
48306043713
48306043713
48505163730
48505163730
48611073718
48611073718
48703113757
48703113757
48705073737
48705073737
48708043714
48708043714
48712183728
48712183728
48910242237
48910242237
49110023719
49110023719
49302033717
49302033717
49410133720
49410133720
49505127040
49505127040$$, '\n') AS l) t;

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

