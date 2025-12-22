CREATE OR REPLACE FUNCTION perseus_dbo.transitiontomaterial()
AS
$BODY$
BEGIN
    INSERT INTO perseus_dbo.transition_material (material_id, transition_id)
    VALUES ("@MaterialUid", "@TransitionUid");
END;
$BODY$
LANGUAGE  plpgsql;

