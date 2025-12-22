CREATE OR REPLACE FUNCTION perseus_dbo.rounddatetime(IN "@InputDateTime" TIMESTAMP WITHOUT TIME ZONE)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    var_ReturnDateTime TIMESTAMP WITHOUT TIME ZONE;
BEGIN
    var_ReturnDateTime := 0 + (aws_sqlserver_ext.datediff('minute', 0::TIMESTAMP, "@InputDateTime"::TIMESTAMP)::NUMERIC || ' MINUTE')::INTERVAL;
    RETURN var_ReturnDateTime;
END;
$BODY$
LANGUAGE  plpgsql;

