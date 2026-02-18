CREATE OR REPLACE FUNCTION perseus_dbo.gethermesrun(IN "@HermesUid" CITEXT)
RETURNS INTEGER
AS
$BODY$
DECLARE
    var_Experiment INTEGER;
BEGIN
    /*
    [7811 - Severity CRITICAL - PostgreSQL doesn't support the PARSENAME(SYSNAME,INT) function. DMS SC skips this unsupported function in the converted code. Create a user-defined function to replace the unsupported function.]
    SET @Experiment = PARSENAME(REPLACE(REPLACE(@HermesUid, 'H', ''), '-', '.'), 1)
    */
    RETURN var_Experiment;
END;
$BODY$
LANGUAGE  plpgsql;

