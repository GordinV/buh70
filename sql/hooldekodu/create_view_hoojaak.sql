DROP VIEW IF EXISTS hooldekodu.cur_hoojaak;

CREATE VIEW hooldekodu.cur_hoojaak AS
SELECT hj.*,
       (hj.pension85 + hj.pension15 + hj.taskuraha_kov +  hj.toetus + hj.vara + hj.muud) AS summa,
       a.regkood                                                     AS isikukood,
       a.nimetus                                                     AS nimi
FROM hooldekodu.hoojaak hj
         INNER JOIN libs.asutus a ON a.id = hj.isikid
ORDER BY a.nimetus
;

GRANT SELECT ON TABLE hooldekodu.cur_hoojaak TO hkametnik;
GRANT SELECT ON TABLE hooldekodu.cur_hoojaak TO soametnik;


SELECT *
FROM hooldekodu.cur_hoojaak
