CREATE OR REPLACE FUNCTION perseus_dbo.fn_tr_fatsmurf_biu()
RETURNS trigger
AS
$BODY$
BEGIN
IF ((TG_OP = 'INSERT' AND NEW.run_complete IS NOT NULL) OR (TG_OP = 'UPDATE' AND NEW.run_complete <> OLD.run_complete)) THEN
    RAISE EXCEPTION ' The column "run_complete" cannot be modified because it is a computed column ';
END IF;
NEW.run_complete := (CASE
    WHEN NEW.duration IS NULL THEN clock_timestamp()
    ELSE NEW.run_on + (NEW.duration * (60)::NUMERIC || ' MINUTE')::INTERVAL
END);
RETURN NEW;
END;
$BODY$
LANGUAGE  plpgsql;