-- =============================================================================
-- Schema Creation - Perseus Database Migration
-- =============================================================================
-- Creates all schemas required by the Perseus database.
-- Must run BEFORE any CREATE TABLE, CREATE INDEX, or constraint scripts.
--
-- Schemas:
--   perseus  - Main application schema (91 tables)
--   hermes   - FDW schema for hermes linked server (6 foreign tables)
--   demeter  - FDW schema for demeter linked server (2 foreign tables)
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS perseus;
CREATE SCHEMA IF NOT EXISTS hermes;
CREATE SCHEMA IF NOT EXISTS demeter;
