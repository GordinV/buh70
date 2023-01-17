/*select a.nimetus, hl.*
from hooldekodu.hooleping hl
INNER JOIN libs.asutus a on a.id = hl.isikid
*/

delete
from hooldekodu.hooteenused
    where lepingid in (
        select id from hooldekodu.hooleping
where isikid in (13346, 44420, 20225)
        );

delete from hooldekodu.hooleping
where isikid in (13346, 44420, 20225);

delete
from hooldekodu.hootehingud ht
where isikid in (13346, 44420, 20225);

update hooldekodu.hootehingud set journalid = null;

    delete from hooldekodu.hootaabel
where isikid in (13346, 44420, 20225);

UPDATE hooldekodu.hootaabel set arvid = 0, sugulane_arv_id = null;

select *
from hooldekodu.hoojaak
where isikid in (13346, 44420, 20225);


select hooldekodu.sp_calc_hoojaak(id)
from libs.asutus where id in (13346, 44420, 20225);
