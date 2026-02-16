update libs.library
set
    properties = properties::jsonb || jsonb_build_object('puudumise_tyyp', 1)
where
      kood in (
                  select
                      unnest(pk.puhkused_kontod)
                  from
                      palk.palk_kulu_kontod pk
              )
  and library = 'KONTOD'
  and kood like '500%'
  and trim(kood) like '%21'
  and status < 3;

-- Lisapuhkusetasu ametiühingutega kollektiivlepingu alusel
--  500XXХ25

update libs.library
set
    properties = properties::jsonb || jsonb_build_object('puudumise_tyyp', 120)
where
      kood in (
                  select
                      unnest(pk.puhkused_kontod)
                  from
                      palk.palk_kulu_kontod pk
              )
  and library = 'KONTOD'
  and kood like '500%'
  and trim(kood) like '%025'
  and status < 3;


select *
from
    libs.library l
where
      l.library = 'KONTOD'
  and kood like '500%'
--  and trim(kood) like '%21'
and kood = '50028025'