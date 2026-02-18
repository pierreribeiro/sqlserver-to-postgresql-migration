CREATE OR REPLACE  VIEW perseus_dbo.vw_lot_path (src_lot_id, dst_lot_id, path, length) AS
SELECT
    sl.id AS src_lot_id, dl.id AS dst_lot_id, mu.path, mu.level AS length
    FROM perseus_dbo.m_upstream AS mu
    JOIN perseus_dbo.vw_lot AS sl
        ON sl.uid = mu.end_point
    JOIN perseus_dbo.vw_lot AS dl
        ON dl.uid = mu.start_point;

