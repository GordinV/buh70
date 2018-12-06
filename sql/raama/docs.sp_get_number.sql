DROP FUNCTION IF EXISTS sp_get_number(tnrekvid INTEGER, tcdok TEXT, tnyear INTEGER, tndokpropid INTEGER );
DROP FUNCTION IF EXISTS docs.sp_get_number(tnrekvid INTEGER, tcdok TEXT, tnyear INTEGER, tndokpropid INTEGER );

CREATE FUNCTION docs.sp_get_number(tnrekvid INTEGER, tcdok TEXT, tnyear INTEGER, tndokpropid INTEGER)
  RETURNS TEXT
LANGUAGE plpgsql
AS $$
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

  lcPref = coalesce(lcPref, '%');

  CASE
    WHEN tcDok = 'ARV'
    THEN
      lcTableName = 'docs.arv';
      lcAdditionalWhere = ' and liik = 0 ';
    WHEN tcDok = 'SARV'
      THEN
        lcTableName = 'docs.arv';
        lcAdditionalWhere = ' and liik = 1 and operid is not null and not empty(operid)';
    WHEN tcDok = 'SORDER'
    THEN
      lcTableName = 'docs.korder1';
      lcAdditionalWhere = ' and tyyp = 1 ';
    WHEN tcDok = 'VORDER'
    THEN
      lcTableName = 'docs.korder1';
      lcAdditionalWhere = ' and tyyp = 2 ';
    WHEN tcDok = 'MK'
    THEN
      lcTableName = 'docs.mk';
      lcAdditionalWhere = ' and OPT = 1 ';
    WHEN tcDok = 'SMK'
    THEN
      lcTableName = 'docs.mk';
      lcAdditionalWhere = ' and OPT = 1 ';
    WHEN tcDok = 'VMK'
    THEN
      lcTableName = 'docs.mk';
      lcAdditionalWhere = ' and OPT = 2 ';
    WHEN tcDok = 'LEPING'
    THEN
      lcTableName = 'docs.leping1';
    WHEN tcDok = 'TAOTLUS'
    THEN
      lcTableName = 'eelarve.taotlus';
    WHEN tcDok = 'LUBA'
    THEN
      lcTableName = '(select left(l.number,2)::text as number, l.parentid, l.rekvid, l.algkpv as kpv from rekl.luba l)';
  END CASE;

  -- building sql query with regexp for only numbers
  lcSqlString = 'select (max(SUBSTRING(''0'' || coalesce(tbl.number,''0''), ' || quote_literal('Y*[0-9]\d+') ||
                ')::bigint) ::bigint) as number from docs.doc d inner join '
                || lcTableName || ' tbl on d.id = tbl.parentid and d.status <> 3 '
                || ' where tbl.rekvId = $1::integer and year(tbl.kpv) = $2::integer and encode(tbl.number::bytea, ''escape'')::text  ilike $3::text';

  lcSqlString = lcSqlString || lcAdditionalWhere;
  EXECUTE lcSqlString
  INTO v_number
  USING tnRekvId, tnYear, lcPref;

  -- will plus pref and encrement

  IF lcPref = '%'
  THEN
    lcPref = '';
  END IF;

  lcNumber = lcPref || (coalesce(v_number.number, 0) + 1) :: TEXT;

  RETURN lcNumber;
END;
$$;


/*
select docs.sp_get_number(130, 'ARV', 2018, null)
 */