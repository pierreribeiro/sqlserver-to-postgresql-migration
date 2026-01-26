-- ============================================================================
-- Object: material_inventory_threshold_notify_user
-- Type: TABLE
-- Priority: P2
-- Description: Notification recipients for inventory threshold alerts
-- ============================================================================

DROP TABLE IF EXISTS perseus.material_inventory_threshold_notify_user CASCADE;

CREATE TABLE perseus.material_inventory_threshold_notify_user (
    material_inventory_threshold_id INTEGER NOT NULL,
    perseus_user_id INTEGER NOT NULL,
    CONSTRAINT pk_material_inventory_threshold_notify_user PRIMARY KEY (material_inventory_threshold_id, perseus_user_id)
);

CREATE INDEX idx_mat_inv_thresh_notify_user_user_id ON perseus.material_inventory_threshold_notify_user(perseus_user_id);

COMMENT ON TABLE perseus.material_inventory_threshold_notify_user IS
'Notification recipients for inventory threshold alerts (many-to-many).
Updated: 2026-01-26 | Owner: Perseus DBA Team';
