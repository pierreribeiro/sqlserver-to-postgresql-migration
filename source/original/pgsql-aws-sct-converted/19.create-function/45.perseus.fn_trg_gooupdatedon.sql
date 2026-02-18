CREATE OR REPLACE FUNCTION perseus_dbo.fn_trg_gooupdatedon()
RETURNS trigger
AS
$BODY$
BEGIN
    UPDATE perseus_dbo.goo
    SET updated_on = clock_timestamp()
        WHERE id IN (SELECT DISTINCT
            id
            FROM inserted);
    RETURN NULL;
END;
$BODY$
LANGUAGE  plpgsql;

