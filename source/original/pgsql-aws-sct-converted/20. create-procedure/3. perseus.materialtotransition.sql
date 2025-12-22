CREATE OR REPLACE PROCEDURE perseus_dbo.materialtotransition(IN "@MaterialUid" CITEXT, IN "@TransitionUid" CITEXT)
AS 
$BODY$
BEGIN
    INSERT INTO perseus_dbo.material_transition (material_id, transition_id)
    VALUES ("@MaterialUid", "@TransitionUid");
END;
$BODY$
LANGUAGE plpgsql;

