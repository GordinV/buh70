DROP FUNCTION IF EXISTS docs.sp_kooperi_pv_kaart(INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_kooperi_pv_kaart(user_id INTEGER,
                                                    base_kaart_id INTEGER, last_kaart_id integer default 0
)
    RETURNS INTEGER AS
$BODY$

DECLARE
    v_pv_kaart    RECORD;
    v_pv_oper     RECORD;
    l_doc_id      INTEGER;
    l_pv_kaart_id integer;
    l_inv_kood    text;
    l_pv_oper_id  integer;
BEGIN
    -- paring andmed

    select l.*, coalesce ((l.properties :: JSONB ->> 'konto'), '') :: VARCHAR (20) AS konto
        into v_pv_kaart
        from
        libs.library l
        where
        l.id = base_kaart_id;

    -- new inv kood
    select
--        left(p.kood, len(ltrim(rtrim(p.kood))) - len((p.kood::integer)::text)) + (p.kood::integer + 1)::text
        ltrim(rtrim(p.kood)) + '-0'  +
        coalesce((select count(id)
                  from cur_pohivara pk
                  where pk.rekvid = v_pv_kaart.rekvid
                     and kood like ltrim(rtrim(v_pv_kaart.kood)) + '%'),0)::text
    into l_inv_kood
    from
        cur_pohivara p
    where
        p.id = (case when last_kaart_id > 0 then last_kaart_id else base_kaart_id end)
    limit 1;

    RAISE NOTICE 'start l_inv_kood %, last_kaart_id %', l_inv_kood, last_kaart_id;

    if exists
    (
        select
            id
        from
            cur_pohivara p
        where
              p.rekvid = v_pv_kaart.rekvid
          and p.kood = l_inv_kood
    ) then
        raise exception 'Viga: PV kaart juba olemas % ', l_inv_kood;
    end if;

    -- копируем карточку
    insert into
        libs.library (rekvid, kood, nimetus, library, muud, tun1, tun2, tun3, tun4, tun5, properties, status)
    select
        rekvid,
        l_inv_kood as kood,
        nimetus,
        library,
        muud,
        tun1,
        tun2,
        tun3,
        tun4,
        tun5,
        properties,
        status
    from
        libs.library l
    where
        id = base_kaart_id
    returning id into l_pv_kaart_id;

    if l_pv_kaart_id is null then
        raise exception 'Viga: PV kaart ei leidnud %',l_pv_kaart_id;
    end if;

    -- копирум док
    insert into docs.doc (doc_type_id, bpm, history, rigths, rekvid)
    select
        doc_type_id,
        bpm,
        history,
        rigths,
        rekvid
    from
        docs.doc
    where
        id in (
                  select
                      parentid
                  from
                      docs.pv_oper po
                  where
                        pv_kaart_id = v_pv_kaart.id
                    and liik = 1
                  order by id desc
                  limit 1
              )
    returning id into l_doc_id;

    if l_doc_id is null then
        raise exception 'Viga: PV paig.dok  ei leidnud %',l_doc_id;
    end if;

    -- копируем операцию постановки
    insert into
        docs.pv_oper (parentid, pv_kaart_id, nomid, liik, kpv, summa, muud, kood1, kood2, kood3, kood4, kood5,
                      konto, tp, asutusid, tunnus, proj, journalid, doklausid, properties)
    select
        l_doc_id      as parentid,
        l_pv_kaart_id as pv_kaart_id,
        nomid,
        liik,
        kpv,
        summa,
        muud,
        kood1,
        kood2,
        kood3,
        kood4,
        kood5,
        konto,
        tp,
        asutusid,
        tunnus,
        proj,
        journalid,
        doklausid,
        properties
    from
        docs.pv_oper
    where
          pv_kaart_id = v_pv_kaart.id
      and liik = 1
    order by id desc
    limit 1
    returning id into l_pv_oper_id;

    if l_pv_oper_id is null then
        raise exception 'Viga: PV oper  ei leidnud %',l_pv_oper_id;
    end if;

    if coalesce(v_pv_kaart.konto, '') <> '' then
        perform docs.gen_lausend_pv_oper(l_doc_id, user_id);
    end if;

    RETURN l_pv_kaart_id;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_kooperi_pv_kaart(INTEGER, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_kooperi_pv_kaart(INTEGER, INTEGER, INTEGER) TO dbpeakasutaja;


--select docs.sp_kooperi_pv_kaart(2477, 284797)
