CREATE OR REPLACE PROCEDURE perseus_dbo.transitiontomaterial(IN "@TransitionUid" CITEXT, IN "@MaterialUid" CITEXT)
AS 
$BODY$
BEGIN
    INSERT INTO perseus_dbo.transition_material (material_id, transition_id)
    VALUES ("@MaterialUid", "@TransitionUid");
END;
$BODY$
LANGUAGE plpgsql;

