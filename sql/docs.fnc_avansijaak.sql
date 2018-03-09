DROP FUNCTION IF EXISTS fnc_avansijaak( INTEGER );
DROP FUNCTION IF EXISTS docs.fnc_avansijaak( INTEGER );

CREATE OR REPLACE FUNCTION docs.fnc_avansijaak(tnId INTEGER, OUT result        INTEGER,
                                                             OUT error_message TEXT,
                                                             OUT selgitus      TEXT)

RETURNS RECORD AS
$BODY$

DECLARE
  tnId ALIAS FOR $1;
  lnTasuSumma  NUMERIC(14, 2) = 0;
  lnSumma      NUMERIC(14, 2) = 0;
  lnJaak       NUMERIC(14, 2) = 0;
  v_avans      RECORD;
  lnDokValuuta NUMERIC(14, 4) = 1;
  a_dokvaluuta TEXT [] = enum_range(NULL :: DOK_VALUUTA);
BEGIN

  -- summa, korkonto
  SELECT
    coalesce((dp.details :: JSONB ->> 'konto'), space(20)) AS konto,
    a1.id                                                  AS avans_id,
    a1.asutusId,
    a1.rekvId,
    a1.number,
    a1.kpv
  INTO v_avans
  FROM docs.doc d
    INNER JOIN docs.avans1 a1 ON a1.parentid = d.id
    LEFT OUTER JOIN libs.dokprop dp ON dp.id = a1.dokpropId
  WHERE d.id = tnId;


  SELECT v.kuurs
  INTO lnDokValuuta
  FROM docs.dokvaluuta1 v
  WHERE dokid IN (SELECT id
                  FROM docs.avans2
                  WHERE parentid = v_avans.avans_id
                  LIMIT 1)
        AND dokliik = array_position(a_dokvaluuta, 'avans2');

  lnDokValuuta = coalesce(lnDokValuuta, 1);

  -- tasumine via päevaraamat

  DELETE FROM docs.avans3
  WHERE parentid = tnId AND liik = 1;

  INSERT INTO docs.avans3 (parentid, dokid, liik, muud, summa)
    SELECT
      v_avans.avans_id,
      d.id,
      1,
      'JOURNAL',
      (j1.summa * coalesce(v.kuurs, 1))
    FROM docs.doc d
      INNER JOIN docs.journal j ON j.parentid = d.id
      INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
      LEFT OUTER JOIN docs.dokvaluuta1 v ON (v.dokid = j.id AND v.dokliik = array_position(a_dokvaluuta, 'journal'))
    WHERE j.rekvid = v_avans.rekvid
          AND j.asutusId = v_avans.AsutusId
          AND ltrim(rtrim(j.dok)) = ltrim(rtrim(v_avans.number))
          AND year(j.kpv) = year(v_avans.Kpv)
          AND ((ltrim(rtrim(j1.deebet)) = ltrim(rtrim(v_avans.konto)) AND
                ltrim(rtrim(j1.kreedit)) IN (SELECT aa.konto
                                             FROM ou.aa aa
                                             WHERE aa.parentid = v_avans.rekvid)) OR
               (ltrim(rtrim(j1.kreedit)) = ltrim(rtrim(v_avans.konto)) AND
                ltrim(rtrim(j1.deebet)) IN (SELECT aa.konto
                                            FROM ou.aa aa
                                            WHERE aa.parentid = v_avans.rekvid)));

  -- arvestame tasud
  SELECT
    sum(tasu)  AS tasu,
    sum(avans) AS avans
  INTO lnTasuSumma, lnSumma
  FROM (
         SELECT
           sum(a3.summa)       AS tasu,
           0 :: NUMERIC(12, 2) AS avans
         FROM docs.avans1 a1
           INNER JOIN docs.avans3 a3 ON a1.id = a3.parentid
         WHERE a1.parentid = tnId
         UNION ALL
         SELECT
           0 :: NUMERIC(12, 2)               AS tasu,
           sum(summa * coalesce(v.kuurs, 1)) AS avans
         FROM docs.avans1 a1
           INNER JOIN docs.avans2 a2 ON a1.id = a2.parentid
           LEFT OUTER JOIN docs.dokvaluuta1 v
             ON (v.dokid = a2.id AND v.dokliik = array_position(a_dokvaluuta, 'avans2'))
         WHERE a1.parentid = tnId) qry;


  result = round((coalesce(lnSumma, 0) - coalesce(lnTasuSumma, 0)), 2);

  UPDATE docs.avans1
  SET jaak = result
  WHERE parentid = tnId;

  return;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    error_message = SQLERRM;
    result = 0;
    RETURN;
END;

$BODY$
LANGUAGE 'plpgsql' VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION docs.fnc_avansijaak(INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.fnc_avansijaak(INTEGER) TO dbpeakasutaja;


SELECT docs.fnc_avansijaak(d.id)
FROM docs.doc d INNER JOIN docs.avans1 a1 ON a1.parentid = d.id

/*
select docs.fnc_avansijaak(d.id) from docs.doc d inner join docs.avans1 a1 on a1.parentid = d.id

 */