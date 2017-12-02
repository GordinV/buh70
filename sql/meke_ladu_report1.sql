select qH.hind, q.nomId, algkogus,algJaak, dbKogus, krKogus, db, kr,
n.kood, n.nimetus, n.uhik,
coalesce(a.number,'') as number, a.kpv, coalesce(q.tunnus,'') as tunnus,
coalesce(c.nimetus,'') as asutus
from (
select sum(algkogus) as algkogus, 
	sum(algkogus * hind * (case when algkogus = 0 then 0 else 1 end)) as algJaak, 
	sum(dbKogus) as dbKogus, sum(krKogus) as krKogus, 
	sum(db) as db,
	sum(kr) as kr,
	nomId, arvid, tunnus
	from (
			select  SUM(kogus * (case when a.liik = 1 then 1 else -1 end)) as algkogus, 
				0 as dbKogus, 0 as krKogus, 0 as db, 0 as kr, 
				nomid, 0 as arvId, null::text as tunnus, 0 as hind
				from curladuarved a 
				where a.kpv < date(2016,09,01) -- algkpv 
				and a.rekvId = 1
			 	group by a.nomId
	union all
		select  0 as algkogus,
			(kogus * (case when a.liik = 1 then 1 else 0 end)) as dbKogus,
			(kogus * (case when a.liik = 2 then 1 else 0 end)) as krKogus, 
			(hind * kogus * (case when a.liik = 1 then 1 else 0 end)) as db, 
			(hind * kogus * (case when a.liik = 2 then 1 else 0 end)) as kr, 
			nomid,
			a.id as arvId, a.tunkood::text as tunnus,
			0 as hind
		from curladuarved a 
		where a.kpv >= date(2016,09,01) -- algkpv 
		and a.kpv <= date(2016,09,30) -- lookpv 
		and a.rekvId = 1
--		 group by a.nomId
) as qry
--where algkogus <> 0 or dbKogus <> 0 or krKogus <> 0
group by nomId, arvid, tunnus
order by arvid, nomId
) as q
inner join (
	select (summaKokku / kogusKokku) as hind, nomId
			from (
				select  SUM(kogus * hind) as summaKokku, sum(kogus) as kogusKokku,
				nomid
				from curladuarved a 
				where a.liik = 1 -- ainult sissetuliku hind 
				and a.kpv < date(2016,09,30)::date -- algkpv 
				and a.rekvId = 1
				 group by a.nomId
				 ) qryHind
			where qryHind.kogusKokku > 0
) qH on qH.nomId = q.nomid
inner join nomenklatuur n on n.id  = q.nomid
JOIN ladu_grupp ON ladu_grupp.nomid = n.id
JOIN library grupp ON grupp.id = ladu_grupp.parentid
left outer join arv a on a.id = q.arvid
left outer join asutus c on c.id = a.asutusid
where (algkogus <> 0 or dbKogus <> 0 or krKogus <> 0)
and n.kood = '1010'


--select sum(kogus),liik from curladuarved where nomid = 1999 group by liik
