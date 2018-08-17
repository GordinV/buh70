DROP FUNCTION IF EXISTS docs.sp_get_number( INTEGER, TEXT, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION docs.sp_get_number(
  tnrekvid    INTEGER,
  tcdok       TEXT,
  tnyear      INTEGER,
  tndokpropid INTEGER)
  RETURNS TEXT AS
$BODY$
DECLARE
  v_number          RECORD;
  lcPref            TEXT = '%';
  lcNumber          TEXT = '0';
  lcTableName       TEXT;
  lcAdditionalWhere TEXT = '';
  lcSqlString       TEXT;
BEGIN
  IF tnDokPropId IS NOT NULL
  THEN
    SELECT ltrim(rtrim(proc_))
    INTO lcPref
    FROM libs.dokprop
    WHERE id = tnDokPropId;
  END IF;

  lcPref = coalesce(lcPref, '');

  CASE tcDok
    WHEN 'ARV'
    THEN
      lcTableName = 'docs.arv';

    WHEN 'SORDER'
    THEN
      lcTableName = 'docs.korder1';
      lcAdditionalWhere = ' and tyyp = 1 ';
    WHEN 'VORDER'
    THEN
      lcTableName = 'docs.korder1';
      lcAdditionalWhere = ' and tyyp = 2 ';
    WHEN 'MK'
    THEN
      lcTableName = 'docs.mk';
      lcAdditionalWhere = ' OPT = 1 ';
    WHEN 'LEPING'
    THEN
      lcTableName = 'docs.leping1';
    WHEN 'TAOTLUS'
    THEN
      lcTableName = 'eelarve.taotlus';
  END CASE;

  -- building sql query with regexp for only numbers
  lcSqlString = 'select (max(SUBSTRING(''0'' || coalesce(number,''0''), ' || quote_literal('Y*[0-9]\d+') ||
                ')::integer) ::integer) + 1 as number from '
                || lcTableName
                || ' where rekvId = $1::integer and year(kpv) = $2::integer and number ilike $3::text';

  lcSqlString = lcSqlString || lcAdditionalWhere;

  EXECUTE lcSqlString
  INTO v_number
  USING tnRekvId, tnYear, lcPref;

  -- will plus pref and encrement

  RAISE NOTICE 'lcSqlString %', lcSqlString;
  if lcPref = '%' THEN
    lcPref = '';
  END IF;

  lcNumber = lcPref || (coalesce(v_number.number, 0) + 1) :: TEXT;

  RETURN lcNumber;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_get_number(INTEGER, TEXT, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_get_number(INTEGER, TEXT, INTEGER, INTEGER) TO dbkasutaja;

/*
select docs.sp_get_number(1, 'ARV', 2018, NULL)
 */