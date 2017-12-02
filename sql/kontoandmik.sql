select * from (
	select 0 as algsaldo, '000' as konto, null::text as korkonto, null::text as asutus, null::numeric as db, null::numeric as kr, null::numeric as loppsaldo
	union all
	select null::numeric as algsaldo, '000' as konto, '111'::text as korkonto, 'Asutus'::text as asutus, 1::numeric as db, 2::numeric as kr, null::numeric as loppsaldo
	union all
	select null::numeric as algsaldo, '000' as konto, null::text as korkonto, null::text as asutus, null::numeric as db, null::numeric as kr, 3::numeric as loppsaldo
) qry