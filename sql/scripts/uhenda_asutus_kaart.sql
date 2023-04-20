DROP FUNCTION IF EXISTS uhenda_asutus_kaart(oige_id INTEGER, vale_id INTEGER);

CREATE FUNCTION uhenda_asutus_kaart(oige_id INTEGER, vale_id INTEGER)
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_vn    RECORD;
    l_count INTEGER = 0;
BEGIN
    /*
    select * from libs.asutus where regkood = '49607193722' and staatus < 3 ;
    -- oige 41813
    -- vale 5269, 30971

     */
    IF NOT exists(SELECT id FROM libs.asutus WHERE id = oige_id AND staatus < 3)
    THEN
        RAISE EXCEPTION 'Õige valik puudub või kustutatud';
    END IF;

    -- journal
    IF exists(SELECT id FROM docs.journal WHERE asutusid = vale_id)
    THEN
        UPDATE docs.journal SET asutusid = oige_id WHERE asutusid = vale_id;
    END IF;

    -- arv
    IF exists(SELECT id FROM docs.arv WHERE asutusid = vale_id)
    THEN
        UPDATE docs.arv SET asutusid = oige_id WHERE asutusid = vale_id;
    END IF;

    -- mk
    IF exists(SELECT id FROM docs.mk1 WHERE asutusid = vale_id)
    THEN
        UPDATE docs.mk1 SET asutusid = oige_id WHERE asutusid = vale_id;
    END IF;

    -- korder
    IF exists(SELECT id FROM docs.korder1 WHERE asutusid = vale_id)
    THEN
        UPDATE docs.korder1 SET asutusid = oige_id WHERE asutusid = vale_id;
    END IF;

    -- avans
    IF exists(SELECT id FROM docs.avans1 WHERE asutusid = vale_id)
    THEN
        UPDATE docs.avans1 SET asutusid = oige_id WHERE asutusid = vale_id;
    END IF;

    -- leping
    IF exists(SELECT id FROM docs.leping1 WHERE asutusid = vale_id)
    THEN
        UPDATE docs.leping1 SET asutusid = oige_id WHERE asutusid = vale_id;
    END IF;

    -- ettemaksud
    IF exists(SELECT id FROM rekl.ettemaksud WHERE asutusid = vale_id)
    THEN
        UPDATE rekl.ettemaksud SET asutusid = oige_id WHERE asutusid = vale_id;
    END IF;

    -- luba
    IF exists(SELECT id FROM rekl.luba WHERE asutusid = vale_id)
    THEN
        UPDATE rekl.luba SET asutusid = oige_id WHERE asutusid = vale_id;
    END IF;

    -- luba
    IF exists(SELECT id FROM rekl.toiming WHERE asutusid = vale_id)
    THEN
        UPDATE rekl.toiming SET asutusid = oige_id WHERE asutusid = vale_id;
    END IF;

    -- pv_oper
    IF exists(SELECT id FROM docs.pv_oper WHERE asutusid = vale_id)
    THEN
        UPDATE docs.pv_oper SET asutusid = oige_id WHERE asutusid = vale_id;
    END IF;


    -- teatis
    IF exists(SELECT id FROM docs.teatis WHERE asutusid = vale_id)
    THEN
        UPDATE docs.teatis SET asutusid = oige_id WHERE asutusid = vale_id;
    END IF;

    -- palk leping
    IF exists(SELECT id FROM palk.tooleping WHERE parentid = vale_id)
    THEN
        UPDATE palk.tooleping SET parentid = oige_id WHERE parentid = vale_id;
    END IF;

    -- palk_kaart
    IF exists(SELECT id FROM palk.palk_kaart WHERE parentid = vale_id)
    THEN
        UPDATE palk.palk_kaart SET parentid = oige_id WHERE parentid = vale_id;
    END IF;

    -- palk_oper
    IF exists(SELECT id FROM palk.palk_oper WHERE parentid = vale_id)
    THEN
        UPDATE palk.palk_oper SET parentid = oige_id WHERE parentid = vale_id;
    END IF;

    -- hooettemaksud
    IF exists(SELECT id FROM hooldekodu.hooettemaksud WHERE isikid = vale_id)
    THEN
        UPDATE hooldekodu.hooettemaksud SET isikid = oige_id WHERE isikid = vale_id;
    END IF;

    -- hoojaak
    IF exists(SELECT id FROM hooldekodu.hoojaak WHERE isikid = vale_id)
    THEN
        UPDATE hooldekodu.hoojaak SET isikid = oige_id WHERE isikid = vale_id;
    END IF;

    -- hooldaja
    IF exists(SELECT id FROM hooldekodu.hooldaja WHERE isikid = vale_id)
    THEN
        UPDATE hooldekodu.hooldaja SET isikid = oige_id WHERE isikid = vale_id;
    END IF;
    IF exists(SELECT id FROM hooldekodu.hooldaja WHERE hooldajaid = vale_id)
    THEN
        UPDATE hooldekodu.hooldaja SET hooldajaid = oige_id WHERE hooldajaid = vale_id;
    END IF;

    -- hooleping
    IF exists(SELECT id FROM hooldekodu.hooleping WHERE isikid = vale_id)
    THEN
        UPDATE hooldekodu.hooleping SET isikid = oige_id WHERE isikid = vale_id;
    END IF;

    -- hootaabel
    IF exists(SELECT id FROM hooldekodu.hootaabel WHERE isikid = vale_id)
    THEN
        UPDATE hooldekodu.hootaabel SET isikid = oige_id WHERE isikid = vale_id;
    END IF;
    -- hootehingud
    IF exists(SELECT id FROM hooldekodu.hootehingud WHERE isikid = vale_id)
    THEN
        UPDATE hooldekodu.hootehingud SET isikid = oige_id WHERE isikid = vale_id;
    END IF;
    -- hootoendid
    IF exists(SELECT id FROM hooldekodu.hootoendid WHERE isikid = vale_id)
    THEN
        UPDATE hooldekodu.hootoendid SET isikid = oige_id WHERE isikid = vale_id;
    END IF;
    -- hoouhendused
    IF exists(SELECT id FROM hooldekodu.hoouhendused WHERE isikid = vale_id)
    THEN
        UPDATE hooldekodu.hoouhendused SET isikid = oige_id WHERE isikid = vale_id;
    END IF;

    -- vanem
    IF exists(SELECT id FROM lapsed.vanemad WHERE asutusid = vale_id AND staatus < 3)
    THEN
        UPDATE lapsed.vanemad SET asutusid = oige_id WHERE asutusid = vale_id AND staatus < 3;
    END IF;

    IF exists(SELECT id FROM lapsed.vanem_arveldus WHERE asutusid = vale_id)
    THEN
        UPDATE lapsed.vanem_arveldus SET asutusid = oige_id WHERE asutusid = vale_id;
    END IF;

    UPDATE libs.asutus
    SET regkood = 'VALE_' || regkood,
        staatus = 3
    WHERE id = vale_id;

    RETURN 1;

END;
$$;

/*
SELECT uhenda_asutus_kaart(41813, 30971)


select * from lapsed.vanemad where asutusid in (41813, 30971)

update lapsed.vanemad set staatus = 3 where id = 284
*/

--30971
