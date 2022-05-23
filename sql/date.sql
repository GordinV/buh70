CREATE FUNCTION date(INTEGER, INTEGER, INTEGER) RETURNS DATE
    LANGUAGE plpgsql
AS
$$
DECLARE

    tnYear ALIAS FOR $1;

    tnMonth ALIAS FOR $2;

    tnDay ALIAS FOR $3;
    lcYear  VARCHAR(4);

    lcMonth VARCHAR(2);

    lcDay   VARCHAR(2);

BEGIN

    lcYear := str(tnYear, 4);

    IF tnMonth < 10
    THEN

        lcMonth := '0' + str(tnMonth, 1);

    ELSE

        lcMonth := str(tnMonth, 2);

    END IF;

    IF tnDay < 10
    THEN

        lcDay := '0' + str(tnDay, 1);

    ELSE

        lcDay := str(tnday, 2);

    END IF;

    RETURN to_date(lcYear + lcMonth + lcDay, 'YYYYMMDD');
END;
$$;


