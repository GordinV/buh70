DROP FUNCTION IF EXISTS palk.arvuta_puhkuse_vm_paev(JSONB);

CREATE FUNCTION palk.arvuta_puhkuse_vm_paev(IN params JSONB,
                                            OUT kpv DATE)
AS
$BODY$

DECLARE
    l_puudumise_id  integer = params ->> 'puudumise_id';
    l_puhkuse_algus date    = params ->> 'alg_kpv';
    l_makse_paev    date    = params ->> 'makse_kpv';
    l_esimine_paev  date;
    l_toopaevad     integer = 0;
BEGIN
    if l_makse_paev is not null then
        kpv = l_makse_paev;
        return;
    end if;

    if l_puhkuse_algus is null then
        select p.kpv1
        into l_puhkuse_algus
        from palk.puudumine p
        where p.id = l_puudumise_id;
    end if;

    if l_puhkuse_algus is null then
        raise exception 'Viga: vale parametrid';
    end if;

    l_esimine_paev = (l_puhkuse_algus - interval '1 day')::date;

    raise notice 'l_puhkuse_algus %, l_esimine_paev %',l_puhkuse_algus, l_esimine_paev;
    -- 2 раб. дня до отпуска

    for i in l_toopaevad .. 2
        loop
            if dow(l_esimine_paev) not in (6, 7, 0) and not exists (SELECT 1
                                                                    FROM cur_tahtpaevad l
                                                                    WHERE (l.rekvId IS NULL OR l.rekvid = 63)
                                                                      AND l.paEv = DAY(l_esimine_paev)
                                                                      AND kuu = MONTH(l_esimine_paev)
                                                                      AND aasta = year(l_esimine_paev)) then
                l_toopaevad = l_toopaevad + 1;
            end if;

            if l_toopaevad < 2 then
                l_esimine_paev = l_esimine_paev - interval '1 day';
            end if;
            if l_toopaevad = 2 then
                exit;
            end if;
        end loop;
    kpv = l_esimine_paev;
    RETURN;

END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;

GRANT EXECUTE ON FUNCTION palk.arvuta_puhkuse_vm_paev( JSONB ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.arvuta_puhkuse_vm_paev( JSONB ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.arvuta_puhkuse_vm_paev( JSONB ) TO dbvaatleja;

--   "puudumise_id": 152438,
select *
from palk.arvuta_puhkuse_vm_paev('{
  "alg_kpv": "2025-08-01"
}')

/*
*/