-- =============================================================================
-- Schema Drop - Perseus Database Migration
-- =============================================================================
-- Drops all schemas created by the Perseus database.
-- Uses CASCADE to remove all contained objects (tables, views, functions, etc.)
-- Must run AFTER all object-level DROP scripts, or standalone with CASCADE.
--
-- WARNING: This is a DESTRUCTIVE operation. All data will be lost.
-- Ensure backups exist before running in STAGING/PROD environments.
--
-- Schemas:
--   perseus  - Main application schema (91 tables)
--   hermes   - FDW schema for hermes linked server (6 foreign tables)
--   demeter  - FDW schema for demeter linked server (2 foreign tables)
--
-- Counterpart: 11. create-database/01-create-schemas.sql
-- =============================================================================

DROP SCHEMA IF EXISTS hermes CASCADE;
DROP SCHEMA IF EXISTS demeter CASCADE;
DROP SCHEMA IF EXISTS perseus CASCADE;
