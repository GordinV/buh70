DROP VIEW IF EXISTS cur_korder_lausend;

CREATE OR REPLACE VIEW cur_korder_lausend AS
SELECT
    d.id,
    d.rekvid                                  AS rekvid,
    k.kpv                                     AS kpv,
    trim(k.number) :: VARCHAR(20)             AS number,
    CASE
        WHEN empty(k.nimi)
            THEN coalesce(a.nimetus, '')
        ELSE k.nimi END :: VARCHAR(254)       AS nimi,
    trim(k.dokument)                          AS dokument,
    k.tyyp,
    CASE
        WHEN k.tyyp = 1
            THEN k2.summa
        ELSE 0 END :: NUMERIC(14, 2)          AS deebet,
    CASE
        WHEN k.tyyp = 2
            THEN k2.summa
        ELSE 0 END :: NUMERIC(14, 2)          AS kreedit,
    COALESCE(Jid.number, 0) :: INTEGER        AS lausend,
    aa.konto                                  AS akonto,
    aa.nimetus                                AS kassa,
    CASE
        WHEN k.tyyp = 1
            THEN aa.konto
        ELSE k2.konto END :: VARCHAR(20)      AS db,
    CASE
        WHEN k.tyyp = 1
            THEN k2.konto
        ELSE aa.konto END :: VARCHAR(20)      AS kr,
    k.journalid
FROM
    docs.doc                           d
        INNER JOIN      docs.korder1   k ON d.id = k.parentid
        INNER JOIN      docs.korder2   k2 ON k.id = k2.parentid
        LEFT OUTER JOIN ou.aa          aa ON k.kassaid = aa.id AND aa.parentid = k.rekvid
        LEFT OUTER JOIN libs.asutus    a ON k.asutusId = a.id
        LEFT OUTER JOIN docs.journal   j ON j.parentid = k.journalid
        LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
where d.status <> 3;

GRANT SELECT ON TABLE cur_korder_lausend TO dbkasutaja;
GRANT SELECT ON TABLE cur_korder_lausend TO dbvaatleja;
GRANT SELECT ON TABLE cur_korder_lausend TO dbpeakasutaja;
