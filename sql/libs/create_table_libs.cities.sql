DROP TABLE IF EXISTS libs.cities;

CREATE TABLE libs.cities
(
    id         SERIAL,
    ctry       varCHAR(2)   NOT NULL,
    linn       varCHAR(254) NOT NULL,
    riik       varchar(254) not null,
    muud       TEXT,
    properties JSONB,
    CONSTRAINT cities_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE libs.cities TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT ON TABLE libs.cities TO dbkasutaja;
GRANT ALL ON TABLE libs.cities TO dbadmin;
GRANT SELECT ON TABLE libs.cities TO dbvaatleja;

insert into
    libs.cities (ctry, linn, riik)
select
    el ->> 'ctry' as ctry,
    el ->> 'linn' as linn,
    el ->> 'riik' as riik
from
    jsonb_array_elements('[
      { "linn": "Abja-Paluoja", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Antsla", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Elva", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Haapsalu", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Jõgeva", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Jõhvi", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Kallaste", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Kärdla", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Karksi-Nuia", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Kehra", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Keila", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Kilingi-Nõmme", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Kiviõli", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Kohtla-Järve", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Kunda", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Kuressaare", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Lihula", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Loksa", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Maardu", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Mõisaküla", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Mustvee", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Narva", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Narva-Jõesuu", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Otepää", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Paide", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Paldiski", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Pärnu", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Põltsamaa", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Põlva", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Püssi", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Rakvere", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Rapla", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Räpina", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Saue", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Sillamäe", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Sindi", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Suure-Jaani", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Tallinn", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Tamsalu", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Tapa", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Tartu", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Tõrva", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Türi", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Valga", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Viljandi", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Võhma", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Võru", "riik": "Eesti", "ctry": "EE" },
      { "linn": "Rīga", "riik": "Läti", "ctry": "LV" },
      { "linn": "Vilnius", "riik": "Leedu", "ctry": "LT" },
      { "linn": "Helsinki", "riik": "Soome", "ctry": "FI" },
      { "linn": "Stockholm", "riik": "Rootsi", "ctry": "SE" },
      { "linn": "Oslo", "riik": "Norra", "ctry": "NO" },
      { "linn": "København", "riik": "Taani", "ctry": "DK" },
      { "linn": "Berlin", "riik": "Saksamaa", "ctry": "DE" },
      { "linn": "Paris", "riik": "Prantsusmaa", "ctry": "FR" },
      { "linn": "Amsterdam", "riik": "Madalmaad", "ctry": "NL" },
      { "linn": "Warszawa", "riik": "Poola", "ctry": "PL" },
      { "linn": "Bruxelles", "riik": "Belgia", "ctry": "BE" },
      { "linn": "Wien", "riik": "Austria", "ctry": "AT" },
      { "linn": "Dublin", "riik": "Iirimaa", "ctry": "IE" },
      { "linn": "Roma", "riik": "Itaalia", "ctry": "IT" },
      { "linn": "Madrid", "riik": "Hispaania", "ctry": "ES" },
      { "linn": "Praha", "riik": "Tšehhi", "ctry": "CZ" },
      { "linn": "London", "riik": "Suurbritannia", "ctry": "GB" },
      { "linn": "Bern", "riik": "Šveits", "ctry": "CH" },
      { "linn": "Washington D.C.", "riik": "Ameerika Ühendriigid", "ctry": "US" },
      { "linn": "Kyiv", "riik": "Ukraina", "ctry": "UA" },
      { "linn": "Ottawa", "riik": "Kanada", "ctry": "CA" }
    ]'::jsonb) el;
