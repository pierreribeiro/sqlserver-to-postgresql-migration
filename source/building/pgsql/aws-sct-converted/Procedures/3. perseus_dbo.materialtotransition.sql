CREATE OR REPLACE PROCEDURE perseus_dbo.materialtotransition(IN par_materialuid VARCHAR, IN par_transitionuid VARCHAR)
AS 
$BODY$
BEGIN
    INSERT INTO perseus_dbo.material_transition (material_id, transition_id)
    VALUES (par_MaterialUid, par_TransitionUid);
END;
$BODY$
LANGUAGE plpgsql;

