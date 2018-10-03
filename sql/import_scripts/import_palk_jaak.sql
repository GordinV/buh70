delete from palk.palk_jaak;
INSERT INTO palk.palk_jaak (lepingid, kuu, aasta, jaak, arvestatud, kinni, tki, tka, pm, tulumaks, sotsmaks, muud, g31)
  SELECT
    i.new_id as lepingid,
    pj.kuu,
    pj.aasta,
    pj.jaak,
    pj.arvestatud,
    pj.kinni,
    pj.tki,
    pj.tka,
    pj.pm,
    pj.tulumaks,
    pj.sotsmaks,
    pj.muud,
    pj.g31
  FROM palk_jaak pj
    INNER JOIN import_log i ON i.old_id = pj.lepingid AND i.lib_name = 'TOOLEPING';
