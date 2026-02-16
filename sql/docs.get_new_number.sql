DROP FUNCTION IF EXISTS docs.get_new_number(TEXT, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_get_number(tnrekvid INTEGER,
                                              tcdok TEXT,
                                              tnyear INTEGER,
                                              tndokpropid INTEGER)
  RETURNS TEXT
  LANGUAGE 'plpgsql'
  COST 100
AS
$BODY$

DECLARE
  v_number          RECORD;
  lcPref            TEXT = '%';
  lcNumber          TEXT = '0';
  lcTableName       TEXT;
  lcAdditionalWhere TEXT = '';
  lcSqlString       TEXT;
  l_seq_name        TEXT;

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
    WHEN tcDok = 'TEATIS'
        THEN
            l_seq_name = docs.create_number_sequence(tnrekvid, tcDok, FALSE);
            SELECT nextval(l_seq_name) AS number INTO v_number;

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
        lcTableName =
            '(select left(l.number,2)::text as number, l.parentid, l.rekvid, l.algkpv as kpv from rekl.luba l)';
    END CASE;

  -- building sql query with regexp for only numbers
  lcSqlString = 'select (max(SUBSTRING(''0'' || coalesce(tbl.number,''0''), ' || quote_literal('Y*[0-9]\d+') ||
                ')::bigint) ::bigint) as number from docs.doc d inner join '
    || lcTableName || ' tbl on d.id = tbl.parentid and d.status <> 3 '
    ||
                ' where tbl.rekvId = $1::integer and date_part(''year'',tbl.kpv) = $2::integer and encode(tbl.number::bytea, ''escape'')::text  ilike $3::text';

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

$BODY$;



GRANT EXECUTE ON FUNCTION docs.sp_get_number(INTEGER, TEXT, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_get_number(INTEGER, TEXT, INTEGER, INTEGER) TO dbkasutaja;


/*

select docs.get_new_number('VORDER', 1, null);

SELECT *
                       FROM docs.korder1 k
                       WHERE k.tyyp = 1
                             AND k.rekvid = 1
                             order by number desc
                             AND (year(k.kpv) = aasta OR aasta IS NULL)
 */