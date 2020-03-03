DROP VIEW IF EXISTS palk.com_maksukood;

CREATE VIEW palk.com_maksukood AS
  SELECT
    l.id,
    l.rekvid,
    l.kood,
    l.nimetus,
    l.status,
    l.tun1 as tm_maar,
    l.tun2 as sm_arv,
    l.tun3 as sm_kuu,
    l.tun4 as tk_arv,
    l.tun5 as pm_arv
  FROM libs.library l
  WHERE l.library = 'MAKSUKOOD'
        AND l.status <> array_position(enum_range(NULL :: DOK_STATUS), 'deleted');

GRANT SELECT ON TABLE palk.com_maksukood TO dbkasutaja;
GRANT SELECT ON TABLE palk.com_maksukood TO dbvaatleja;
GRANT SELECT ON TABLE palk.com_maksukood TO dbpeakasutaja;
