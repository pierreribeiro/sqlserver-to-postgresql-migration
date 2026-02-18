CREATE OR REPLACE  VIEW perseus_dbo.vw_lot_edge (src_lot_id, dst_lot_id, created_on) AS
SELECT
    sl.id AS src_lot_id, dl.id AS dst_lot_id, mt.added_on AS created_on
    FROM perseus_dbo.material_transition AS mt
    JOIN perseus_dbo.vw_lot AS sl
        ON sl.uid = mt.material_id
    JOIN perseus_dbo.vw_lot AS dl
        ON dl.process_uid = mt.transition_id;

