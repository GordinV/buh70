-- pank_vv

/*
select * from lapsed.pank_vv
ORDER BY id desc limit 10
*/
update lapsed.pank_vv set doc_id = null where doc_id is not null ;

--liidestamine

/*select * from lapsed.liidestamine
limit 10
*/
delete from lapsed.liidestamine;

-- taabelid

select * from lapsed.lapse_taabel
where staatus = 2
ORDER BY id desc limit 1000