-- 10
update libs.library
set tun1 = 22,
    properties = coalesce(properties,'{}')::jsonb || jsonb_build_object('maksuvaba_arvestus', true,
                                                                        'tulumaks', true,
                                                                        'tm_maar', 22,
                                                                        'tm_liik','[610,650]',
                                                                        'pm_640', false,
                                                                        'sm', true,
                                                                        'sm_kuu_maaralt',true, 'pm',true, 'tk', true)
    where   kood in ('10') and library = 'MAKSUKOOD' and status < 3;

--12
update libs.library
set tun1 = 22,
    properties = coalesce(properties,'{}')::jsonb || jsonb_build_object('maksuvaba_arvestus', true,
                                                                        'tulumaks', true,
                                                                        'tm_maar', 22,
                                                                        'tm_liik','[610,650]',
                                                                        'pm_640', false,
                                                                        'sm', false,
                                                                        'sm_kuu_maaralt',false,
                                                                        'pm',false, 'tk', false)
where   kood in ('12') and library = 'MAKSUKOOD' and status < 3;

-- 13

update libs.library
set tun1 = 22,
    properties = coalesce(properties,'{}')::jsonb || jsonb_build_object('maksuvaba_arvestus', true,
                                                                        'tulumaks', true,
                                                                        'tm_maar', 22,
                                                                        'tm_liik','[610,650]',
                                                                        'pm_640', false,
                                                                        'sm', true,
                                                                        'sm_kuu_maaralt',true,
                                                                        'pm',true,
                                                                        'tk', false)
where   kood in ('13') and library = 'MAKSUKOOD' and status < 3;

-- 15
update libs.library
set tun1 = 22,
    properties = coalesce(properties,'{}')::jsonb || jsonb_build_object('maksuvaba_arvestus', true,
                                                                        'tulumaks', true,
                                                                        'tm_maar', 22,
                                                                        'tm_liik','[610,650]',
                                                                        'pm_640', false,
                                                                        'sm', true,
                                                                        'sm_kuu_maaralt',false,
                                                                        'pm',true,
                                                                        'tk', false)
where   kood in ('15') and library = 'MAKSUKOOD' and status < 3;

select * from libs.library where kood = '15' and library = 'MAKSUKOOD' and status < 3

