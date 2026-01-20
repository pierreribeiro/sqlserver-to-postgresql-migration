# Feature Specification: T-SQL to PostgreSQL Database Migration

**Feature Branch**: `001-tsql-to-pgsql`
**Created**: 2026-01-19
**Status**: Draft
**Input**: User description: "Migrate T-SQL (SQL Server) objects to PGSQL (PostgreSQL)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Database Administrator Migrates Critical Views (Priority: P1)

As a Database Administrator, I need to migrate all views from SQL Server to PostgreSQL so that applications querying data through views continue to function after the migration.

**Why this priority**: Views provide essential data abstractions used by the Pegasus application. The `translated` view (materialized) and recursive CTEs (`upstream`, `downstream`) are critical for material lineage tracking - a core business capability.

**Independent Test**: Can be fully tested by deploying migrated views to a test environment, executing existing application queries against them, and comparing result sets with SQL Server outputs. Delivers immediate value by validating that data access patterns remain intact.

**Acceptance Scenarios**:

1. **Given** a SQL Server view with standard SELECT logic, **When** the view is migrated to PostgreSQL, **Then** queries against the PostgreSQL view return identical results to the SQL Server version
2. **Given** an indexed view in SQL Server, **When** migrated to PostgreSQL as a materialized view, **Then** query performance remains within 20% of the SQL Server baseline
3. **Given** a recursive CTE view, **When** migrated to PostgreSQL, **Then** the recursion logic produces correct hierarchical results for material lineage queries
4. **Given** a view with cross-database references (linked servers), **When** migrated to PostgreSQL, **Then** Foreign Data Wrappers (FDW) provide equivalent data access to external databases

---

### User Story 2 - Database Administrator Migrates Table-Valued Functions (Priority: P1)

As a Database Administrator, I need to migrate all table-valued functions (TVFs) from SQL Server to PostgreSQL so that stored procedures and application code calling these functions continue to work correctly.

**Why this priority**: The McGet* function family (McGetUpStream, McGetDownStream, McGetUpStreamByList, McGetDownStreamByList) are called by multiple procedures and represent core material lineage logic. Without these functions, material reconciliation and processing workflows will fail.

**Independent Test**: Can be fully tested by calling each migrated function with known input parameters and comparing output result sets with SQL Server. Delivers value by validating critical data retrieval logic independently of calling procedures.

**Acceptance Scenarios**:

1. **Given** a table-valued function accepting parameters, **When** the function is migrated to PostgreSQL, **Then** calling the function with the same parameters returns identical rows and columns as SQL Server
2. **Given** a function using the GooList user-defined table type, **When** migrated to PostgreSQL using temporary table pattern, **Then** the function correctly processes batch input lists
3. **Given** a function with complex CTEs and joins, **When** migrated to PostgreSQL, **Then** query execution completes within 20% of SQL Server performance
4. **Given** a scalar function, **When** migrated to PostgreSQL, **Then** the function returns the same scalar value for equivalent inputs

---

### User Story 3 - Database Administrator Migrates Table Structures (Priority: P1)

As a Database Administrator, I need to migrate all table schemas, indexes, and constraints from SQL Server to PostgreSQL so that data storage structures support application operations and maintain referential integrity.

**Why this priority**: Tables are the foundation of the database. Without properly migrated table schemas, indexes, and constraints, no other database objects can function. The 91 tables include critical structures like `goo` (material master), `material_transition`, and `transition_material` that store core business data.

**Independent Test**: Can be fully tested by creating tables in PostgreSQL, validating all constraints (primary keys, foreign keys, check constraints), testing index performance, and verifying data type compatibility. Delivers value by establishing the foundational data layer.

**Acceptance Scenarios**:

1. **Given** a SQL Server table schema, **When** migrated to PostgreSQL, **Then** all columns preserve data types with appropriate conversions (e.g., NVARCHAR to VARCHAR, IDENTITY to GENERATED ALWAYS AS IDENTITY)
2. **Given** table constraints (primary keys, foreign keys, check constraints), **When** migrated to PostgreSQL, **Then** all constraints enforce the same business rules and referential integrity
3. **Given** table indexes, **When** migrated to PostgreSQL, **Then** query performance for indexed columns remains within 20% of SQL Server baseline
4. **Given** tables with large row counts, **When** migrated to PostgreSQL, **Then** data loads complete successfully with zero data loss and matching row counts

---

### User Story 4 - Database Administrator Configures External Data Integrations (Priority: P2)

As a Database Administrator, I need to configure Foreign Data Wrappers (FDW) to replace SQL Server linked servers so that the Perseus database can continue accessing data from external databases (hermes, sqlapps, deimeter).

**Why this priority**: The Pegasus application requires cross-database queries to enrich material data with experimental and run information. While critical for full functionality, this can be implemented after core objects are migrated since applications can temporarily use direct database connections.

**Independent Test**: Can be fully tested by configuring FDW connections, executing queries that join local tables with foreign tables, and validating that result sets match current linked server queries. Delivers value by restoring cross-database query capabilities.

**Acceptance Scenarios**:

1. **Given** SQL Server linked server queries to hermes database, **When** replaced with postgres_fdw, **Then** queries return identical results with acceptable performance
2. **Given** views joining local and foreign tables, **When** executed in PostgreSQL, **Then** the query optimizer efficiently pushes predicates to foreign servers where appropriate
3. **Given** FDW connections to sqlapps.common database, **When** queries access foreign tables, **Then** connection pooling and authentication work reliably without manual intervention
4. **Given** scheduled jobs querying foreign data, **When** executed in PostgreSQL, **Then** FDW connections remain stable and do not cause job failures

---

### User Story 5 - Database Administrator Establishes Data Replication (Priority: P2)

As a Database Administrator, I need to configure SymmetricDS replication from PostgreSQL to sqlwarehouse2 so that downstream data warehouse systems continue receiving updated Perseus data.

**Why this priority**: Data warehouse systems depend on Perseus data for reporting and analytics. While important, replication can be configured after core migration since warehouse refreshes can temporarily run in batch mode or use alternative data pipelines.

**Independent Test**: Can be fully tested by configuring SymmetricDS, inserting/updating/deleting data in source tables, and verifying changes replicate to sqlwarehouse2 within acceptable latency. Delivers value by restoring automated data synchronization.

**Acceptance Scenarios**:

1. **Given** a table configured for replication, **When** rows are inserted in PostgreSQL, **Then** the same rows appear in sqlwarehouse2 within the defined replication SLA (e.g., 5 minutes)
2. **Given** a table with updates, **When** rows are modified in PostgreSQL, **Then** changes replicate to sqlwarehouse2 preserving data integrity
3. **Given** replication monitoring, **When** replication lag exceeds thresholds, **Then** alerts notify administrators of replication issues
4. **Given** a replication failure scenario, **When** connectivity is restored, **Then** SymmetricDS resumes replication without data loss

---

### User Story 6 - Database Administrator Migrates SQL Agent Jobs (Priority: P3)

As a Database Administrator, I need to migrate SQL Server Agent jobs to PostgreSQL scheduling mechanisms (pgAgent or cron) so that automated database maintenance and processing tasks continue running on schedule.

**Why this priority**: Jobs automate routine tasks like data reconciliation and cleanup. While necessary for long-term operations, these can be manually executed during initial migration phases, making this lower priority than core data objects.

**Independent Test**: Can be fully tested by configuring equivalent jobs in PostgreSQL, executing them manually first, then validating scheduled execution produces expected results (e.g., reconciliation completes, logs are created). Delivers value by restoring automation and reducing manual intervention.

**Acceptance Scenarios**:

1. **Given** a SQL Server Agent job calling stored procedures, **When** migrated to pgAgent, **Then** the job executes on the same schedule and calls equivalent PostgreSQL procedures
2. **Given** job failure scenarios, **When** a job step fails in PostgreSQL, **Then** error handling behaves equivalently to SQL Server (e.g., notifications sent, retries attempted)
3. **Given** job dependencies, **When** jobs are scheduled in PostgreSQL, **Then** dependent jobs execute in the correct sequence
4. **Given** job logging, **When** jobs execute in PostgreSQL, **Then** execution history is captured for troubleshooting and audit purposes

---

### Edge Cases

- What happens when a view references a table that hasn't been migrated yet? Migration must follow dependency order identified in dependency analysis files.
- How does the system handle views with proprietary SQL Server syntax (e.g., NOLOCK hints)? Remove hints and rely on PostgreSQL's MVCC model for concurrency.
- What happens when a table has SQL Server-specific data types (e.g., MONEY, UNIQUEIDENTIFIER)? Convert to appropriate PostgreSQL types (NUMERIC, UUID) with explicit casting.
- How does the system handle functions using cursors? Refactor to set-based operations following the constitution's prohibition of Row-By-Agonizing-Row patterns.
- What happens when GooList table-valued parameter type is used by functions? Implement temporary table pattern as defined in the constitution and project specification.
- How does the system handle indexed views that don't exist in PostgreSQL? Convert to materialized views with trigger-based or scheduled refresh strategies.
- What happens when FDW connections to external databases fail? Implement retry logic and connection pooling; provide fallback mechanisms for critical queries.
- How does the system handle replication lag exceeding acceptable thresholds? Configure SymmetricDS monitoring with alerting and automatic retry mechanisms.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST migrate all 22 SQL Server views to PostgreSQL preserving query logic and result sets
- **FR-002**: System MUST convert SQL Server indexed views to PostgreSQL materialized views with appropriate refresh mechanisms
- **FR-003**: System MUST migrate all 25 functions (15 table-valued, 10 scalar) from T-SQL to PL/pgSQL preserving input/output signatures and logic
- **FR-004**: System MUST migrate all 91 tables with correct data type mappings, preserving all columns and metadata
- **FR-005**: System MUST migrate all 352 indexes ensuring query performance remains within 20% of SQL Server baseline
- **FR-006**: System MUST migrate all 271 constraints (primary keys, foreign keys, check constraints, unique constraints) maintaining referential integrity
- **FR-007**: System MUST convert SQL Server user-defined type GooList to PostgreSQL temporary table pattern for use in functions
- **FR-008**: System MUST configure Foreign Data Wrappers for external database access (hermes - 6 tables, sqlapps.common - 9 tables, deimeter - 2 tables)
- **FR-009**: System MUST configure SymmetricDS replication to sqlwarehouse2 for all replicated tables maintaining data synchronization
- **FR-010**: System MUST migrate 7 SQL Server Agent jobs to PostgreSQL scheduling mechanism (pgAgent or cron) preserving execution schedules
- **FR-011**: System MUST validate each migrated object through analysis, refactoring, validation, and deployment phases as defined in the project workflow
- **FR-012**: System MUST maintain dependency order during migration, ensuring dependent objects are migrated after their dependencies
- **FR-013**: System MUST achieve quality scores ≥7.0/10 across all five dimensions (syntax correctness, logic preservation, performance, maintainability, security) for each migrated object
- **FR-014**: System MUST produce identical result sets for queries executed against PostgreSQL compared to SQL Server for equivalent inputs
- **FR-015**: System MUST document all naming conversions from PascalCase to snake_case in a mapping table for application team reference
- **FR-016**: System MUST use schema-qualified object references for all database objects to prevent ambiguity and security vulnerabilities
- **FR-017**: System MUST implement explicit error handling with specific exception types for all migrated functions and procedures
- **FR-018**: System MUST preserve all business logic from SQL Server objects while adapting to PostgreSQL idioms and best practices

### Key Entities *(include if feature involves data)*

- **View**: Represents a virtual table providing data abstraction; includes standard views, recursive CTE views, and materialized views (converted from indexed views); critical examples include `translated`, `upstream`, `downstream`, `goo_relationship`
- **Function**: Represents reusable logic returning table sets or scalar values; includes McGet* family (upstream/downstream lineage), Get* family (legacy queries), and utility functions; depends on views and temporary tables
- **Table**: Represents physical data storage structure; 91 tables including critical entities like `goo` (material master), `material_transition`, `transition_material`, `m_upstream`, `m_downstream`, `container`, `fatsmurf`; foundation for all other objects
- **Index**: Represents performance optimization structure for tables; 352 indexes including primary key indexes, foreign key indexes, and query optimization indexes
- **Constraint**: Represents data integrity rules including primary keys, foreign keys, unique constraints, check constraints; 271 constraints enforce business rules
- **User-Defined Type**: Represents custom data type (GooList) used as table-valued parameter; requires conversion to temporary table pattern in PostgreSQL
- **Foreign Data Wrapper (FDW)**: Represents connection to external database allowing local queries to access remote tables; replaces SQL Server linked servers for hermes, sqlapps, deimeter
- **Replication Configuration**: Represents SymmetricDS setup for synchronizing data to sqlwarehouse2; includes table registration, triggers, and routing configuration
- **Job**: Represents scheduled automated task; 7 SQL Server Agent jobs require migration to pgAgent or cron with equivalent schedules and error handling

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All 22 views return identical result sets in PostgreSQL compared to SQL Server for the same queries (100% data correctness)
- **SC-002**: All 25 functions produce identical outputs in PostgreSQL compared to SQL Server for equivalent inputs (100% logic preservation)
- **SC-003**: All 91 tables are migrated with zero data loss verified by row count and checksum validation (100% data integrity)
- **SC-004**: Query performance for migrated objects remains within 20% of SQL Server baseline measured by execution time comparison
- **SC-005**: All 352 indexes are created and query plans utilize them appropriately verified by EXPLAIN ANALYZE
- **SC-006**: All 271 constraints are enforced correctly verified by constraint violation testing
- **SC-007**: Foreign Data Wrapper queries to external databases (hermes, sqlapps, deimeter) return correct results with acceptable performance (<2x SQL Server linked server latency)
- **SC-008**: SymmetricDS replication to sqlwarehouse2 maintains data synchronization within 5-minute SLA measured by replication lag monitoring
- **SC-009**: All 7 migrated jobs execute successfully on schedule with logging and error handling equivalent to SQL Server Agent
- **SC-010**: Zero production incidents during cutover to PostgreSQL verified by incident tracking
- **SC-011**: Migration cutover downtime is less than 8 hours measured from application shutdown to successful restart
- **SC-012**: Test coverage exceeds 90% for unit and integration tests covering all migrated objects
- **SC-013**: All migrated objects achieve quality scores ≥8.0/10 average across the five quality dimensions
- **SC-014**: Complete documentation is delivered including technical specifications, operational runbooks, and training materials verified by documentation review checklist
- **SC-015**: Database availability post-migration meets 99.9% uptime SLA measured over 30-day period

## Assumptions

- **AS-001**: AWS Schema Conversion Tool (SCT) output provides a reasonable starting point (70% complete) requiring manual review and correction for remaining 30%
- **AS-002**: Development, Staging, and Production PostgreSQL environments are available and properly configured before migration begins
- **AS-003**: Production SQL Server database remains available for parallel validation during migration phases
- **AS-004**: Test data representative of production workloads is available for performance benchmarking
- **AS-005**: Stored procedures (15 core + 6 MS replication) have already been successfully migrated and are excluded from this scope
- **AS-006**: Dependency analysis files (lote1-lote4 and consolidated) accurately represent object dependencies and will be used for migration sequencing
- **AS-007**: Application code changes are out of scope; applications will connect to PostgreSQL using updated connection strings without code modifications
- **AS-008**: PostgreSQL 17 is the target version and provides all required features for migration
- **AS-009**: Performance degradation up to 20% is acceptable based on cost/benefit analysis of migration
- **AS-010**: External databases (hermes, sqlapps, deimeter) are PostgreSQL-compatible or have FDW drivers available
- **AS-011**: SymmetricDS is the approved replication tool for synchronizing data to sqlwarehouse2
- **AS-012**: The constitution's seven core principles (ANSI-SQL primacy, strict typing, set-based execution, atomic transactions, idiomatic naming, structured error handling, modular logic) are binding requirements for all migrated objects
- **AS-013**: Each object follows the four-phase workflow: Analysis, Refactoring (correction), Validation (testing), Deployment
- **AS-014**: Rollback capability to SQL Server must be maintained until production has been stable for at least 30 days

## Dependencies

- **DP-001**: Migration depends on availability of PostgreSQL 17 cluster (AWS RDS or EC2) with appropriate sizing and configuration
- **DP-002**: Migration depends on completion of stored procedure migration (15 procedures already completed)
- **DP-003**: Migration depends on access to production SQL Server database for extracting object definitions and test data
- **DP-004**: Migration depends on availability of dependency analysis documents (docs/code-analysis/dependency-analysis-*.md) for correct sequencing
- **DP-005**: Migration depends on access to AWS Schema Conversion Tool for baseline object conversion
- **DP-006**: Migration depends on availability of project constitution (`.specify/memory/constitution.md`) defining coding standards
- **DP-007**: Foreign Data Wrapper configuration depends on network connectivity and authentication to external databases (hermes, sqlapps, deimeter)
- **DP-008**: Replication configuration depends on SymmetricDS installation and licensing
- **DP-009**: Job migration depends on selection and installation of PostgreSQL job scheduling tool (pgAgent recommended)
- **DP-010**: Testing depends on availability of representative test data and test environments (DEV, STAGING)
- **DP-011**: Production deployment depends on approval from technical lead and DBA reviewers based on quality gate criteria
- **DP-012**: Application teams depend on naming conversion mapping table to update any hardcoded object references

## Out of Scope

- **OOS-001**: Application code changes and API modifications are out of scope; applications must work with migrated database using connection string updates only
- **OOS-002**: New replication topology design is out of scope; existing replication to sqlwarehouse2 will be recreated with same architecture using SymmetricDS
- **OOS-003**: End-user acceptance testing (UAT) is out of scope; testing focuses on technical validation of database objects
- **OOS-004**: User manuals and end-user documentation are out of scope; focus is on technical documentation for database administrators and developers
- **OOS-005**: Stored procedures migration is out of scope (already completed in previous sprints 1-8)
- **OOS-006**: Database redesign or schema optimization is out of scope; migration preserves existing structure and logic with minimal changes required for PostgreSQL compatibility
- **OOS-007**: Performance optimization beyond 20% baseline is out of scope unless critical issues emerge
- **OOS-008**: Migration of non-Perseus databases is out of scope; focus is exclusively on Perseus database objects
- **OOS-009**: Application architecture changes or microservices refactoring are out of scope
- **OOS-010**: Data archival or purging strategies are out of scope; all current production data will be migrated

## Constraints

- **CN-001**: Migration must achieve zero data loss verified through row count and checksum validation
- **CN-002**: Migration cutover downtime must not exceed 8 hours to minimize business impact
- **CN-003**: All migrated objects must comply with the seven core principles defined in the project constitution
- **CN-004**: Performance must remain within 20% of SQL Server baseline for equivalent queries
- **CN-005**: Quality scores for all migrated objects must achieve ≥7.0/10 overall with no dimension below 6.0/10
- **CN-006**: Migration must maintain referential integrity across all 271 constraints
- **CN-007**: All object names must follow snake_case lowercase naming convention per constitution
- **CN-008**: All transactions must be explicitly managed with BEGIN/COMMIT/ROLLBACK per constitution
- **CN-009**: All type conversions must use explicit CAST or :: notation per constitution's strict typing principle
- **CN-010**: All database object references must be schema-qualified to prevent search_path vulnerabilities
- **CN-011**: Migration must preserve existing security model and permissions
- **CN-012**: Rollback procedures must be tested and ready before production deployment
