DROP FUNCTION IF EXISTS docs.sp_lausendikontrol(params JSONB);
DROP FUNCTION IF EXISTS docs.sp_lausendikontrol(params JSONB);

CREATE OR REPLACE FUNCTION docs.sp_lausendikontrol(params JSONB)
    RETURNS TEXT AS
$BODY$

DECLARE
    l_db       TEXT = trim(params ->> 'db');
    l_kr       TEXT = trim(params ->> 'kr');
    l_tp_d     TEXT = params ->> 'tpd';
    l_tp_k     TEXT = params ->> 'tpk';
    l_tt       TEXT = params ->> 'tt';
    l_allikas  TEXT = params ->> 'allikas';
    l_eelarve  TEXT = params ->> 'eelarve';
    l_rahavoog TEXT = params ->> 'rahavoog';
    l_oma_tp   TEXT = params ->> 'oma_tp';
    l_kpv      DATE = coalesce((params ->> 'kpv')::DATE, current_date);
    lnTPD      INT  = 0;
    lnTPK      INT  = 0;
    lnTT       INT  = 0;
    lnEelarve  INT  = 0;
    lnAllikas  INT  = 0;
    lnRahavoog INT  = 0;
    l_msg      TEXT = '';
    lcMsg1     TEXT = '';
    ldKpv      DATE;
    v_konto_d  RECORD;
    v_konto_k  RECORD;
    v_lib      RECORD;
    is_error   INTEGER;
BEGIN

    IF l_kpv < make_date(2020, 12, 31)
    THEN
        -- Valentina B. 07.02.2023
        RAISE EXCEPTION 'Viga: Vale kuupäev %', l_kpv;
        RETURN l_msg;
    END IF;

    -- убериаем из под контроля формирование нач. сальдо или итогов
    IF (l_db = '299000' OR l_db = '298000' OR l_kr = '299000' OR l_kr = '298000' OR l_db = '999990')
    THEN
        RETURN l_msg;
    END IF;

-- kontrollin oma TP
    IF l_oma_tp IS NOT NULL AND NOT (char_length(l_oma_tp) = 0) AND (l_tp_d = l_oma_tp OR l_tp_k = l_oma_tp)
    THEN
        lcMsg1 = ' TP kood on vale, ei saa kasutada tehingus oma TP kood ';
        IF (left(l_oma_tp, 6) = '185101' OR l_oma_tp = '185130') AND (left(l_db, 1) = '7' OR left(l_kr, 1) = '7')
        THEN
            lcMsg1 = '';
        END IF;
        l_msg = l_msg + lcMsg1;
    END IF;

    /*    -- kontrollin tegevusalla
        IF l_tt = '06601'
        THEN
            lcMsg1 = 'Tegevusalla ei kehti ';
            l_msg = l_msg + lcMsg1;
        END IF;
    */
    -- Tp kontoll

    IF left(ltrim(rtrim(l_tp_d)), 4) = '1851' AND char_length(ltrim(rtrim(l_tp_d))) = 6
    THEN
        lcMsg1 = 'TP-D Ei saa kasuta vana kohalik TP koodid';
        l_msg = l_msg + lcMsg1;

    END IF;

    IF left(ltrim(rtrim(l_tp_k)), 4) = '1851' AND char_length(ltrim(rtrim(l_tp_k))) = 6
    THEN
        lcMsg1 = 'TP-K Ei saa kasuta vana kohalik TP koodid';
        l_msg = l_msg + lcMsg1;
    END IF;

    --TP kehtivus
    --K


    SELECT l.tun5 AS valid INTO v_lib FROM libs.library l WHERE kood = l_tp_k AND library = 'TP' LIMIT 1;
    IF v_lib IS NOT NULL AND v_lib.valid IS NOT NULL AND NOT public.empty(v_lib.valid)
        AND l_kpv > make_date((left(v_lib.valid::TEXT, 4))::INTEGER, (substr(v_lib.valid::TEXT, 5, 2))::INTEGER,
                              (substr(v_lib.valid::TEXT, 7, 2))::INTEGER)
    THEN
        lcMsg1 = 'TP-K,Ei saa kasuta, sest TP kood ei ole kehtiv;';
        l_msg = l_msg + lcMsg1;
    END IF;

    -- контроль ТП кода
    IF not empty(coalesce(l_tp_k, '')) and not exists
    (
        select
            id
        from
            libs.library
        where
              kood = l_tp_k
          and library.library = 'TP'
          and status < 3
    ) then

        lcMsg1 = 'TP-K, kood (' || coalesce(l_tp_k, '') || ') registris puudub; ';
        l_msg = l_msg + lcMsg1;

    END IF;

    -- D
    SELECT l.tun5 AS valid, l.kood INTO v_lib FROM libs.library l WHERE kood = l_tp_d AND library = 'TP' LIMIT 1;

    IF v_lib IS NOT NULL AND v_lib.valid IS NOT NULL AND NOT public.empty(v_lib.valid)
        AND l_kpv > make_date((left(v_lib.valid::TEXT, 4))::INTEGER, (substr(v_lib.valid::TEXT, 5, 2))::INTEGER,
                              (substr(v_lib.valid::TEXT, 7, 2))::INTEGER)
    THEN
        lcMsg1 = 'TP-D,Ei saa kasuta, sest TP kood ei ole kehtiv ';
        l_msg = l_msg + lcMsg1;
    END IF;

    -- контроль ТП кода
    IF not empty(coalesce(l_tp_d, '')) and not exists
    (
        select
            id
        from
            libs.library
        where
              kood = l_tp_d
          and library.library = 'TP'
          and status < 3
    ) then

        lcMsg1 = 'TP-D, kood (' || l_tp_d || ') registris puudub;';
        l_msg = l_msg + lcMsg1;

    END IF;


-- konto kehtivus (D)
    SELECT
        l.kood,
        l.nimetus,
        l.muud,
        l.tun1                                                             AS tp,
        l.tun2                                                             AS tegev,
        l.tun3                                                             AS allikas,
        l.tun4                                                             AS rahavoog,
        l.tun5                                                             AS tyyp,
        l.properties::JSONB ->> 'valid'                                    AS valid,
        coalesce((l.properties::JSONB ->> 'tp_req')::CHAR(1), '')::CHAR(1) AS tp_req,
        coalesce((l.properties::JSONB ->> 'tt_req')::CHAR(1), '')::CHAR(1) AS tt_req,
        coalesce((l.properties::JSONB ->> 'a_req')::CHAR(1), '')::CHAR(1)  AS a_req,
        coalesce((l.properties::JSONB ->> 'rv_req')::CHAR(1), '')::CHAR(1) AS rv_req
    INTO v_konto_d
    FROM
        libs.library l
    WHERE
          l.library = 'KONTOD'
      AND l.kood::TEXT = l_db::TEXT
      AND status <> 3
    LIMIT 1;

    IF v_konto_d.valid IS NOT NULL AND char_length(v_konto_d.valid::TEXT) >= 8 AND
       NOT public.empty(v_konto_d.valid::TEXT)
    THEN
        IF char_length(v_konto_d.valid::TEXT) = 8
        THEN
            ldKpv = make_date((left(v_konto_d.valid::TEXT, 4))::INTEGER, (substr(v_konto_d.valid::TEXT, 5, 2))::INTEGER,
                              (substr(v_konto_d.valid::TEXT, 7, 2))::INTEGER);
        ELSE
            -- новый формат
            ldKpv = v_konto_d.valid::DATE;
        END IF;

        IF l_kpv > ldKpv
        THEN
            lcMsg1 = 'Konto D, Ei saa kasuta, sest kood ei ole kehtiv';
            l_msg = l_msg + lcMsg1;
        END IF;
    END IF;

    -- kontod
-- konto kehtivus (K)
    SELECT
        l.kood,
        l.nimetus,
        l.muud,
        l.tun1                                                             AS tp,
        l.tun2                                                             AS tegev,
        l.tun3                                                             AS allikas,
        l.tun4                                                             AS rahavoog,
        l.properties::JSONB ->> 'tyyp'                                     AS tyyp,
        l.properties::JSONB ->> 'valid'                                    AS valid,
        coalesce((l.properties::JSONB ->> 'tp_req')::CHAR(1), '')::CHAR(1) AS tp_req,
        coalesce((l.properties::JSONB ->> 'tt_req')::CHAR(1), '')::CHAR(1) AS tt_req,
        coalesce((l.properties::JSONB ->> 'a_req')::CHAR(1), '')::CHAR(1)  AS a_req,
        coalesce((l.properties::JSONB ->> 'rv_req')::CHAR(1), '')::CHAR(1) AS rv_req

    INTO v_konto_k
    FROM
        libs.library l
    WHERE
          l.library = 'KONTOD'
      AND l.kood::TEXT = l_kr::TEXT
      AND status <> 3
    LIMIT 1;

    IF v_konto_k.valid IS NOT NULL AND NOT public.empty(v_konto_k.valid) AND char_length(v_konto_k.valid::TEXT) >= 8
    THEN
        IF char_length(v_konto_k.valid::TEXT) = 8
        THEN
            ldKpv = date((left(v_konto_k.valid::TEXT, 4))::INTEGER, (substr(v_konto_k.valid::TEXT, 5, 2))::INTEGER,
                         (substr(v_konto_k.valid, 7, 2))::INTEGER);
        ELSE
            ldKpv = v_konto_k.valid::DATE;
        END IF;
        IF l_kpv > ldKpv
        THEN
            l_msg = l_msg + 'Konto K, Ei saa kasuta, sest kood ei ole kehtiv';
        END IF;
    END IF;

    -- deebet

    IF v_konto_d.kood IS NULL OR NOT char_length(l_db) > 0 OR char_length(l_db) < 6
    THEN
        l_msg = l_msg + ' Deebet konto: puudub või vale konto (' || l_db || ')' ;
    END IF;

-- Требование к ТП коду
    IF v_konto_d.tp::TEXT = '1' AND char_length(l_tp_d) = 0
    THEN
        lnTPD = 1;

        -- если * и RV = 01 то требование остается, иначе нет
        IF (v_konto_d.tp_req = '*' AND l_rahavoog <> '01')
        THEN
            lnTPD = 0;
        END IF;

    END IF;


    IF v_konto_d.tegev::TEXT = '1' AND (public.empty(l_tt) OR public.empty(l_eelarve))
    THEN
        IF NOT public.empty(l_tt)
        THEN
            lnTT = 0;
        END IF;
        lnEelarve = 1;
        IF (left(l_db, 1) = '9' OR LEFT(l_db, 2) = '61')
        THEN
            lnEelarve = 0;
        END IF;

        -- если * и RV = 01 то требование остается, иначе нет
        IF (v_konto_d.tt_req = '*' AND l_rahavoog <> '01')
        THEN

            lnTT = 0;
            lnEelarve = 0;
        END IF;

    END IF;

    -- kontrollin 'RE' (только для отчетов)
    IF NOT public.empty(l_allikas) AND l_allikas = 'RE'
    THEN
        l_msg = l_msg + ' Ei saa kasutada allikas RE';
    END IF;

    IF v_konto_d.allikas::TEXT = '1' AND (public.empty(l_allikas) OR public.isdigit(l_allikas) = 0)
    THEN
        lnAllikas = 1;
        -- если * и RV = 01 то требование остается, иначе нет
        IF (v_konto_d.a_req = '*' AND l_rahavoog <> '01')
        THEN
            lnAllikas = 10;
        END IF;
    END IF;

    IF v_konto_d.rahavoog::TEXT = '1' AND public.empty(l_rahavoog)
    THEN
        lnRahavoog = 1;

        -- если * и RV = 01 то требование остается, иначе нет
        IF (v_konto_d.rv_req = '*' AND l_rahavoog <> '01')
        THEN
            lnRahavoog = 0;
        END IF;

    END IF;

-- kontrollin kontogrupp '7'
    IF left(l_db, 1) = '7'
    THEN
        IF (left(l_tp_d, 3) = '800' OR left(l_tp_d, 3) = '900')
        THEN
            l_msg = l_msg + ' Ei saa kasutada see (' || l_tp_d || ') TP kood ';
        END IF;

        IF l_oma_tp IS NOT NULL AND NOT public.empty(l_oma_tp) AND left(l_tp_d, 4) <> left(l_oma_tp, 4)
        THEN
            l_msg = l_msg +
                    ' Ei saa kasutada see TP kood: saab siirdeid kajastada ainult nende TP koodidega, mille esimesed 4 numbrit on samad ';
        END IF;
    END IF;

    IF left(l_db, 5) = '20200'
    THEN
        IF (l_tp_d::TEXT = '800699'::TEXT OR left(l_tp_d, 4)::TEXT = '9006'::TEXT)
        THEN
            -- ok
        ELSE
            l_msg = l_msg + ' Ei saa kasutada see TP kood: alati 800699 ' + left(l_tp_d, 4);

        END IF;
    END IF;

    IF left(l_db, 5) = '10393' AND l_tp_d <> '800699'
    THEN
        l_msg = l_msg + ' Ei saa kasutada see TP kood: alati 800699 ';
    END IF;

-- pank
    IF (left(l_db, 4) = '1001' OR l_db = '550012' OR l_db = '655000') AND left(l_tp_d, 4) <> '8004'
    THEN
        l_msg = l_msg + 'Deebet, ei saa kasutada see TP kood: alati 8004** ';
    END IF;

--palk
    IF left(l_db, 3) = '500'
    THEN
        IF (l_tp_d::TEXT = '800699'::TEXT OR left(l_tp_d, 4)::TEXT = '9006'::TEXT)
        THEN
            --ok
        ELSE
            l_msg = l_msg + ' Ei saa kasutada see TP kood: alati 800699 ';
        END IF;
    END IF;

--omakapital
    IF left(l_db, 3) = '298' AND
       (l_rahavoog <> '28' AND l_rahavoog <> '00' AND l_rahavoog <> '05' AND l_rahavoog <> '18' AND
        l_rahavoog <> '38' AND l_rahavoog <> '21' AND l_rahavoog <> '41' AND l_rahavoog <> '43')
    THEN
        l_msg = l_msg + ' Ei saa kasutada see RV kood ';
    END IF;

--eraldised
    IF (left(l_db, 3) = '206' OR left(l_db, 3) = '256') AND
       (l_rahavoog <> '00' AND l_rahavoog <> '06' AND l_rahavoog <> '41' AND l_rahavoog <> '42')
    THEN
        l_msg = l_msg + ' Ei saa kasutada see RV kood ';
    END IF;

--laenud
    IF v_konto_d.rahavoog IS NOT NULL AND v_konto_d.rahavoog::TEXT = '1'
    THEN
        IF (left(l_db, 3) = '208' OR left(l_db, 3) = '258') AND
           (l_rahavoog <> '00' AND l_rahavoog <> '36' AND l_rahavoog <> '35' AND l_rahavoog <> '05' AND
            l_rahavoog <> '06' AND
            l_rahavoog <> '41' AND l_rahavoog <> '42' AND l_rahavoog <> '43')
        THEN
            l_msg = l_msg + ' Ei saa kasutada see RV kood ';
        END IF;

        IF (left(l_db, 4) = '1032' OR left(l_db, 4) = '1532') AND NOT public.empty(l_rahavoog) AND
           (l_rahavoog <> '01' AND l_rahavoog <> '02' AND l_rahavoog <> '23' AND l_rahavoog <> '02' AND
            l_rahavoog <> '21')
        THEN
            l_msg = l_msg + ' Ei saa kasutada see RV kood ';
        END IF;
    END IF;

    -- Kreedit

    IF v_konto_k.kood IS NULL OR public.empty(l_kr) OR char_length(l_kr) < 6
    THEN
        l_msg = l_msg + ' Kreedit konto: puudub või vale konto ';
    END IF;

-- Требование к ТП коду
    IF v_konto_k.tp::TEXT = '1' AND char_length(l_tp_k) = 0
    THEN
        lnTPK = 1;

        -- если * и RV = 01 то требование остается, иначе нет
        IF (v_konto_k.tp_req = '*' AND l_rahavoog <> '01')
        THEN
            lnTPK = 0;
        END IF;

    END IF;


    IF v_konto_k.tegev IS NOT NULL AND v_konto_k.tegev::TEXT = '1' AND
       (public.empty(l_tt) OR public.empty(l_eelarve)) AND lnTT = 0
    THEN
        IF NOT public.empty(l_tt)
        THEN
            lnTT = 0;
        END IF;
        lnEelarve = 1;
        IF (left(l_kr, 1) = '9' OR left(l_kr, 3) = '154' OR left(l_kr, 3) = '155' OR left(l_kr, 3) = '156' OR
            l_kr = '350000')
        THEN
            lnEelarve = 0;
        END IF;

        -- если * и RV = 01 то требование остается, иначе нет
        IF (v_konto_k.tt_req = '*' AND l_rahavoog <> '01')
        THEN
            lnEelarve = 0;
            lnTT = 0;
        END IF;

    END IF;

    -- контроль TT кода
    IF not empty(coalesce(l_tt, '')) and not exists
    (
        select
            id
        from
            libs.library
        where
              kood = l_tt
          and library.library = 'TEGEV'
          and status < 3
    ) then

        lcMsg1 = 'TEGEVUSALA, kood (' || l_tt || ') registris puudub;';
        l_msg = l_msg + lcMsg1;

    END IF;


    IF v_konto_k.allikas IS NOT NULL AND v_konto_k.allikas::TEXT = '1' AND
       (public.empty(l_allikas) OR public.isdigit(l_allikas) = 0) AND lnAllikas = 0
    THEN
        lnAllikas = 1;

        -- если * и RV = 01 то требование остается, иначе нет
        IF (v_konto_k.a_req = '*' AND l_rahavoog <> '01')
        THEN
            lnAllikas = 0;
        END IF;

    END IF;

    -- контроль Allikas кода
    IF not empty(coalesce(l_allikas, '')) and not exists
    (
        select
            id
        from
            libs.library
        where
              kood = l_allikas
          and library.library = 'ALLIKAD'
          and status < 3
    ) then

        lcMsg1 = 'Allikas, kood (' || l_allikas || ') registris puudub;';
        l_msg = l_msg + lcMsg1;

    END IF;


    IF v_konto_k.rahavoog IS NOT NULL AND v_konto_k.rahavoog::TEXT = '1' AND public.empty(l_rahavoog) AND lnRahavoog = 0
    THEN
        lnRahavoog = 1;
        -- если * и RV = 01 то требование остается, иначе нет
        IF (v_konto_k.rv_req = '*' AND l_rahavoog <> '01')
        THEN
            lnRahavoog = 0;
        END IF;

    END IF;


    IF left(l_kr, 1) = '7'
    THEN
        IF (left(l_tp_k, 3) = '800' OR left(l_tp_k, 3) = '900')
        THEN
            l_msg = l_msg + ' Ei saa kasutada see TP kood ';
        END IF;

        IF NOT public.empty(l_oma_tp) AND left(l_tp_k, 4) <> left(l_oma_tp, 4)
        THEN
            l_msg = l_msg +
                    ' Ei saa kasutada see TP kood: saab siirdeid kajastada ainult nende TP koodidega, mille esimesed 4 numbrit on samad ';
        END IF;

    END IF;

    --maksud

    IF left(l_kr, 5) = '20200'
    THEN
        IF (l_tp_k::TEXT = '800699'::TEXT OR left(l_tp_k::TEXT, 4)::TEXT = '9006')
        THEN
            -- ok
        ELSE
            l_msg = l_msg + ' Ei saa kasutada see TP kood: TP kood alati 800699 (9006**)';
        END IF;

    END IF;

    IF (left(l_kr, 5) = '10393') AND l_tp_k <> '800699'
    THEN
        l_msg = l_msg + ' Ei saa kasutada see TP kood: TP kood alati 800699 ';
    END IF;

    -- Sots.toetused
-- pank
    IF (left(l_kr, 4) = '1001' OR l_kr = '550012' OR l_kr = '655000') AND left(l_tp_k, 4) <> '8004'
    THEN

        l_msg = l_msg + 'Kreedit, ei saa kasutada see TP kood: alati 8004** ';
    END IF;

--palk
    IF left(l_kr, 3) = '500'
    THEN
        IF (l_tp_k = '800699' OR left(l_tp_k, 4) = '9006')
        THEN
            -- OK
        ELSE
            l_msg = l_msg + ' Ei saa kasutada see TP kood: alati 800699 ';
        END IF;
    END IF;

--omakapital
    IF v_konto_k.rahavoog IS NOT NULL AND v_konto_k.rahavoog::TEXT = '1'
    THEN
        IF left(l_kr, 3) = '298' AND
           (l_rahavoog <> '28' AND l_rahavoog <> '00' AND l_rahavoog <> '05' AND l_rahavoog <> '18' AND
            l_rahavoog <> '38' AND l_rahavoog <> '21' AND l_rahavoog <> '41' AND l_rahavoog <> '43')
        THEN
            l_msg = l_msg + ' Ei saa kasutada see RV kood ';
        END IF;
    END IF;

--eraldised
    IF v_konto_k.rahavoog IS NOT NULL AND v_konto_k.rahavoog::TEXT = '1' AND
       (left(l_kr, 3) = '206' OR left(l_kr, 3) = '256') AND
       (l_rahavoog <> '00' AND l_rahavoog <> '06' AND l_rahavoog <> '41' AND l_rahavoog <> '42')
    THEN
        l_msg = l_msg + ' Ei saa kasutada see RV kood ';
    END IF;

--laenud
    IF v_konto_k.rahavoog IS NOT NULL AND v_konto_k.rahavoog::TEXT = '1'
    THEN
        IF (left(l_kr, 3) = '208' OR left(l_kr, 3) = '258') AND
           (l_rahavoog <> '00' AND l_rahavoog <> '36' AND l_rahavoog <> '35' AND l_rahavoog <> '05' AND
            l_rahavoog <> '06' AND
            l_rahavoog <> '41' AND l_rahavoog <> '42' AND l_rahavoog <> '43')
        THEN
            l_msg = l_msg + ' Ei saa kasutada see RV kood ';
        END IF;

        IF (left(l_kr, 4) = '1032' OR left(l_kr, 4) = '1532') AND
           (l_rahavoog <> '01' AND l_rahavoog <> '02' AND l_rahavoog <> '23' AND l_rahavoog <> '02' AND
            l_rahavoog <> '21')
        THEN
            l_msg = l_msg + ' Ei saa kasutada see RV kood ';
        END IF;
    END IF;


    IF lnTPD = 1
    THEN
        l_msg = l_msg + 'TP-D ';
    END IF;

    IF lnTPK = 1
    THEN
        l_msg = l_msg + ' TP-K';
    END IF;

    IF lnTt = 1
    THEN
        l_msg = l_msg + ' Tegevusalla ';
    END IF;

    IF lnEelarve = 1
    THEN
        l_msg = l_msg + ' Eelarve ';
    END IF;

    IF lnAllikas = 1
    THEN
        l_msg = l_msg + ' Allikas ';
    END IF;

    IF lnRahavoog = 1
    THEN
        l_msg = l_msg + 'Rahavoog ';
    END IF;

-- kontrollin grupp 506
    IF left(l_db, 3) = '506'
    THEN
        IF l_tp_d <> '800699' AND left(l_tp_d, 4) <> '9006'
        THEN
            l_msg = l_msg + ' TP-D kood on vale, peaks olla 800699 ';
        END IF;
    END IF;

-- kontrollin kontogrupp '9'
    IF (left(l_db, 1) = '9' OR left(l_kr, 1) = '9') AND (l_db <> '999999' AND l_kr <> '999999') AND
       left(l_rahavoog, 1) <> '9' AND lnRahavoog = 1
    THEN
        l_msg = l_msg + ' RV kood on vale, peaks olla 90-99 ';
    END IF;

    IF (l_rahavoog = '11' OR l_rahavoog = '12') AND left(l_db, 3) <> left(l_kr, 3)
    THEN
        is_error = 1;
        IF left(l_db, 2) = '61'
        THEN
            is_error = 0;
        END IF;

        IF is_error = 1 AND left(l_db, 2) = '29'
        THEN
            is_error = 0;
        END IF;

        if (left(l_db, 6) = '888888' or left(l_kr, 6) = '888888' ) and l_rahavoog = '12' then
            -- частичное списание
            is_error = 0;
        end if;
        IF is_error = 1
        THEN
            l_msg = l_msg + ' DB konto on vale, see peab olema vordne kontodega 61xxx  ';
        END IF;
    END IF;

-- allikas, kehtivus
    SELECT
        l.kood,
        (l.properties::JSONB ->> 'valid')::DATE AS valid
    INTO v_lib
    FROM
        libs.library l
    WHERE
          l.library = 'ALLIKAD'
      AND l.kood::TEXT = l_allikas::TEXT
      AND l.status <> 3
    LIMIT 1;

    IF v_lib.valid IS NOT NULL AND NOT public.empty(v_lib.valid)
    THEN
        IF l_kpv > v_lib.valid
        THEN
            l_msg = l_msg + ', Allikas (' || l_allikas || '), Ei saa kasuta, sest kood ei ole kehtiv';
        END IF;
    END IF;

-- artikkel, kehtivus
    SELECT
        l.kood,
        (l.properties::JSONB ->> 'valid')::DATE AS valid
    INTO v_lib
    FROM
        libs.library l
    WHERE
          l.library = 'TULUDEALLIKAD'
      AND l.kood::TEXT = l_eelarve::TEXT
      AND l.status <> 3
    LIMIT 1;

    IF v_lib.valid IS NOT NULL AND NOT public.empty(v_lib.valid)
    THEN
        IF l_kpv > v_lib.valid
        THEN
            l_msg = l_msg + ', Artikkel (' || l_eelarve || '), Ei saa kasuta, sest kood ei ole kehtiv';
        END IF;
    END IF;

    -- контроль Artikkel кода
    IF not empty(coalesce(l_eelarve, '')) and not exists
    (
        select
            id
        from
            libs.library
        where
              kood = l_eelarve
          and library.library = 'TULUDEALLIKAD'
          and status < 3
    ) then

        lcMsg1 = 'Artikkel, kood (' || l_eelarve || ') registris puudub;';
        l_msg = l_msg + lcMsg1;

    END IF;


-- tegev, kehtivus
    SELECT
        l.kood,
        (l.properties::JSONB ->> 'valid')::DATE AS valid
    INTO v_lib
    FROM
        libs.library l
    WHERE
          l.library = 'TEGEV'
      AND l.kood::TEXT = l_tt::TEXT
      AND l.status <> 3
    LIMIT 1;

    IF v_lib.valid IS NOT NULL AND NOT public.empty(v_lib.valid)
    THEN
        IF l_kpv > v_lib.valid
        THEN
            l_msg = l_msg + ', Tegevusalla (' || l_tt || '), Ei saa kasuta, sest kood ei ole kehtiv';
        END IF;
    END IF;

-- Rahavoog, kehtivus
    SELECT
        l.kood,
        (l.properties::JSONB ->> 'valid')::DATE AS valid
    INTO v_lib
    FROM
        libs.library l
    WHERE
          l.library = 'RAHA'
      AND l.kood::TEXT = l_rahavoog::TEXT
      AND l.status <> 3
    LIMIT 1;

    IF v_lib.valid IS NOT NULL AND NOT public.empty(v_lib.valid)
    THEN
        IF l_kpv > v_lib.valid
        THEN
            l_msg = l_msg + ', Rahavoog (' || l_rahavoog || '), Ei saa kasuta, sest kood ei ole kehtiv';
        END IF;
    END IF;


    IF NOT public.empty(l_msg::TEXT)
    THEN
        l_msg = 'Viga Db:' || coalesce(l_db::TEXT, '') || ' ' || 'Kr:' || coalesce(l_kr::TEXT, '') ||
                ' puudub eelarve koodid: ' || l_msg;
    END IF;

    RETURN l_msg;
END;
$BODY$
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_lausendikontrol(params JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_lausendikontrol(params JSONB) TO dbpeakasutaja;

/*

select rekvid, kpv, deebet, lisa_d, kreedit, lisa_k, kood1, kood2, kood3, kood4, kood5 from cur_journal where kreedit = '150020'
order by kpv desc

SELECT docs.sp_lausendikontrol(('{
  "db": "10010008",
  "tpd": "800401XXX",
  "kr": "350050",
  "tpk": "",
  "oma_tp"  : "18510130",
  "allikas": "",
  "rahavoog": "16",
  "eelarve": "3220",
  "tt": "09110"
}'::JSONB);

*/