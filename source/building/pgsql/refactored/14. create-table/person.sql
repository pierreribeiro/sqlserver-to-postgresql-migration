-- ============================================================================
-- Object: person
-- Type: TABLE (Tier 0)
-- Priority: P3
-- Description: Person records (possibly legacy/deprecated table)
-- ============================================================================

DROP TABLE IF EXISTS perseus.person CASCADE;

CREATE TABLE perseus.person (
    id INTEGER NOT NULL,
    domain_id VARCHAR(100) NOT NULL,
    km_session_id VARCHAR(200),
    login VARCHAR(100) NOT NULL,
    name VARCHAR(200) NOT NULL,
    email VARCHAR(200),
    last_login TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_person PRIMARY KEY (id)
);

CREATE INDEX idx_person_login ON perseus.person(login);
CREATE INDEX idx_person_email ON perseus.person(email);

COMMENT ON TABLE perseus.person IS
'Person records - possibly legacy table. Check if still used vs perseus_user. Updated: 2026-01-26';

COMMENT ON COLUMN perseus.person.is_active IS 'True if person account is active (default: TRUE)';
