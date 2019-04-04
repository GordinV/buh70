DROP FUNCTION IF EXISTS docs.get_avans_jaak(INTEGER);

CREATE OR REPLACE FUNCTION docs.get_avans_jaak(l_id INTEGER)
  RETURNS NUMERIC AS
$BODY$


DECLARE
  l_tasu_summa NUMERIC(14, 2);
  v_avans      RECORD;
  l_jaak       NUMERIC(14, 2) = 0;
  a_docs_ids   INTEGER [];
BEGIN

  -- summa, korkonto
  SELECT
    a.parentid                                                          AS id,
    coalesce((d.details ->> 'konto') :: VARCHAR(20), '') :: VARCHAR(20) AS konto,
    a.asutusId,
    a.rekvId,
    a.number,
    a.kpv,
    (SELECT sum(summa)
     FROM docs.avans2 a2
     WHERE a2.parentid = a.id)                                          AS summa,
    a.jaak
    INTO v_avans
  FROM docs.doc doc
         INNER JOIN docs.avans1 a ON a.parentid = doc.id
         INNER JOIN docs.avans2 a2 ON a2.parentid = a.id
         LEFT OUTER JOIN libs.dokprop d ON d.id = a.dokpropId
  WHERE a.parentid = l_id;

  -- tasumine via päevaraamat

  DELETE
  FROM docs.avans3
  WHERE parentid = v_avans.id
    AND liik = 1;

  -- salvestame tasud
  INSERT INTO docs.avans3 (parentid, dokid, liik, muud, summa)
  SELECT
    v_avans.id,
    j.id,
    1,
    'JOURNAL',
    sum(j1.summa) AS summa
  FROM docs.doc d
         INNER JOIN docs.journal j ON j.parentid = d.Id
         INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
  WHERE j.rekvid = v_avans.rekvid
    AND j.asutusId = v_avans.AsutusId
    AND ltrim(rtrim(j.dok)) = ltrim(rtrim(v_avans.number))
    AND year(j.kpv) = year(v_avans.Kpv)
    AND ((ltrim(rtrim(j1.deebet)) = ltrim(rtrim(v_avans.konto)) AND
          ltrim(rtrim(j1.kreedit)) LIKE '100100%') OR
         (ltrim(rtrim(j1.kreedit)) = ltrim(rtrim(v_avans.konto)) AND
          ltrim(rtrim(j1.deebet)) LIKE '100100%'))
  GROUP BY j.id;

  -- arvestame jaak
  SELECT sum(summa)
         INTO l_tasu_summa
  FROM docs.avans3
  WHERE parentid = l_id;

  l_jaak = v_avans.summa - coalesce(l_tasu_summa, 0);

  IF v_avans.jaak <> l_jaak
  THEN
    -- lisame docsids
    a_docs_ids = (SELECT array_agg(dokid)
                  FROM docs.avans3
                  WHERE parentid = v_avans.id);

    UPDATE docs.doc
    SET docs_ids = docs_ids || a_docs_ids
    WHERE id = l_id;

    UPDATE docs.avans1
    SET jaak = v_avans.summa - coalesce(l_tasu_summa, 0)
    WHERE parentid = l_id;
  END IF;

  RETURN l_jaak;

END;


$BODY$
  LANGUAGE plpgsql
  VOLATILE
  COST 100;

GRANT EXECUTE ON FUNCTION docs.get_avans_jaak(INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.get_avans_jaak(INTEGER) TO dbpeakasutaja;

/*
SELECT docs.get_avans_jaak(parentid)
FROM docs.avans1

*/