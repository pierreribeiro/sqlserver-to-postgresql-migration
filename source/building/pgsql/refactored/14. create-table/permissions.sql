-- ============================================================================
-- Object: permissions
-- Type: TABLE (Tier 0)
-- Priority: P3
-- Description: User permission mappings
-- ============================================================================

DROP TABLE IF EXISTS perseus.permissions CASCADE;

CREATE TABLE perseus.permissions (
    emailaddress VARCHAR(255) NOT NULL,
    permission VARCHAR(50) NOT NULL,

    CONSTRAINT pk_permissions PRIMARY KEY (emailaddress, permission)
);

CREATE INDEX idx_permissions_email ON perseus.permissions(emailaddress);

COMMENT ON TABLE perseus.permissions IS
'User permission mappings. Composite PK on (emailaddress, permission). Updated: 2026-01-26';

COMMENT ON COLUMN perseus.permissions.emailaddress IS 'User email address';
COMMENT ON COLUMN perseus.permissions.permission IS 'Permission code (single character or short code)';
