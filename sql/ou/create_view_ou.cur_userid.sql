DROP VIEW IF EXISTS ou.cur_userid;

CREATE VIEW ou.cur_userid AS
SELECT u.id,
       r.nimetus                                       AS asutus,
       u.kasutaja,
       u.ametnik,
       u.properties ->> 'email'                        AS email,
       (u.roles ->> 'is_admin')::BOOLEAN               AS is_admin,
       (u.roles ->> 'is_kasutaja')::BOOLEAN            AS is_kasutaja,
       (u.roles ->> 'is_peakasutaja')::BOOLEAN         AS is_peakasutaja,
       (u.roles ->> 'is_eel_koostaja')::BOOLEAN        AS is_eel_koostaja,
       (u.roles ->> 'is_eel_allkirjastaja')::BOOLEAN   AS is_eel_allkirjastaja,
       (u.roles ->> 'is_eel_aktsepterja')::BOOLEAN     AS is_eel_aktsepterja,
       (u.roles ->> 'is_eel_admin')::BOOLEAN           AS is_eel_admin,
       (u.roles ->> 'is_asutuste_korraldaja')::BOOLEAN AS is_asutuste_korraldaja,
       (u.roles ->> 'is_rekl_administraator')::BOOLEAN AS is_rekl_administraator,
       (u.roles ->> 'is_rekl_maksuhaldur')::BOOLEAN    AS is_rekl_maksuhaldur,
       (u.roles ->> 'is_ladu_kasutaja')::BOOLEAN       AS is_ladu_kasutaja,
       (u.roles ->> 'is_arvestaja')::BOOLEAN           AS is_arvestaja,
       (u.roles ->> 'is_palga_kasutaja')::BOOLEAN      AS is_palga_kasutaja,
       (u.roles ->> 'is_pohivara_kasutaja')::BOOLEAN   AS is_pohivara_kasutaja,
       (u.roles ->> 'is_sa_ametnik')::BOOLEAN          AS is_sa_ametnik,
       (u.roles ->> 'is_hk_ametnik')::BOOLEAN          AS is_hk_ametnik,
       u.rekvid
FROM ou.userid u
         INNER JOIN ou.rekv r ON r.id = u.rekvid
WHERE u.status <> 3;


GRANT ALL ON TABLE ou.cur_userid TO dbadmin;
GRANT SELECT ON TABLE ou.cur_userid TO dbpeakasutaja;
GRANT SELECT ON TABLE ou.cur_userid TO dbkasutaja;
GRANT SELECT ON TABLE ou.cur_userid TO dbvaatleja;
GRANT SELECT ON TABLE ou.cur_userid TO eelaktsepterja;
GRANT SELECT ON TABLE ou.cur_userid TO eelallkirjastaja;
GRANT SELECT ON TABLE ou.cur_userid TO eelallkirjastaja;

/*
eelesitajaselect * from ou.cur_userid
 */