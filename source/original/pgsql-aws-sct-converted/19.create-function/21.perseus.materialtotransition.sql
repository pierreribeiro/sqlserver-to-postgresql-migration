CREATE OR REPLACE FUNCTION perseus_dbo.materialtotransition()
AS
$BODY$
BEGIN
    INSERT INTO perseus_dbo.material_transition (material_id, transition_id)
    VALUES ("@MaterialUid", "@TransitionUid");
END;
$BODY$
LANGUAGE  plpgsql;

