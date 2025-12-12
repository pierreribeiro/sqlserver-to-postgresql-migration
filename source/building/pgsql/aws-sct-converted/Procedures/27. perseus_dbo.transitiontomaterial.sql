CREATE OR REPLACE PROCEDURE perseus_dbo.transitiontomaterial(IN par_transitionuid VARCHAR, IN par_materialuid VARCHAR)
AS 
$BODY$
BEGIN
    INSERT INTO perseus_dbo.transition_material (material_id, transition_id)
    VALUES (par_MaterialUid, par_TransitionUid);
END;
$BODY$
LANGUAGE plpgsql;

