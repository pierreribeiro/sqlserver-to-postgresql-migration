CREATE OR REPLACE FUNCTION perseus_dbo.gethermesuid(IN "@ExperimentId" INTEGER, IN "@RunId" INTEGER)
RETURNS CITEXT
AS
$BODY$
DECLARE
    var_Uid CITEXT;
BEGIN
    var_Uid := 'H' || CAST ("@ExperimentId" AS VARCHAR(25)) || '-' || CAST ("@RunId" AS VARCHAR(25));
    RETURN var_Uid;
END;
$BODY$
LANGUAGE  plpgsql;

