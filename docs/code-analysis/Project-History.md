# Project History



## Purpose & context


Pierre is leading the Perseus Database Migration project, a comprehensive SQL Server to PostgreSQL 17 migration. This project started with a small scope. As a senior DBA/DBRE, he systematically converted over 15 stored procedures from T-SQL to PL/pgSQL using a structured 5-phase workflow (Analysis, Correction, Validation, Testing, and Deployment). The project emphasizes zero-downtime migration with performance targets within 20% of SQL Server baseline, requiring detailed quality assurance with scoring across five dimensions: syntax correctness, logic preservation, performance, maintainability, and security.

The project is organized into sprints with database objects prioritized by business criticality versus technical complexity, tracked through GitHub issues and comprehensive documentation in the sqlserver-to-postgresql-migration repository. The migration involves complex manufacturing/supply chain procedures with graph relationships, nested set algorithms, and external system integrations requiring careful dependency management and transaction control.



## Key learnings & principles



Critical patterns have emerged from systematic analysis: AWS SCT consistently fails on transaction control, temp table initialization, and produces excessive LOWER() function usage that blocks database indexes. The "coordinator pattern" procedures that orchestrate other procedures present higher complexity due to dependencies.
Quality scoring methodology has proven effective across five dimensions, with post-fix projections consistently achieving 8.0-8.5/10 scores. Medium complexity procedures with simple data flow tend to achieve higher conversion quality, while procedures with external system calls (OPENQUERY, linked servers) require complete manual rewrites using Foreign Data Wrapper infrastructure.
The dual-environment approach has demonstrated 1-2 hours time savings per procedure through focused separation of strategic analysis and tactical execution. Military-style communication protocols and structured handoffs between sessions maintain project continuity and prevent context loss.
Size increases during AWS SCT conversion are often misleading - apparent massive growth (215-541%) frequently consists of verbose warning comments rather than actual code complexity. Real code growth typically ranges 20-25% after comment removal.



## Approach & patterns


Pierre employs systematic sprint organization with procedures categorized as P1 (critical), P2 (medium), and P3 (low priority). Each procedure follows a standardized analysis workflow: AWS SCT analysis, P0/P1/P2 issue identification, Code Web instruction creation, repository commits, and GitHub issue closure.
Quality assurance uses consistent scoring methodology with detailed documentation committed to GitHub, comprehensive issue tracking, and cross-referencing between related procedures. Token budget management includes "Safe Zone" monitoring and proactive session transitions with context migration artifacts.
Documentation follows strict patterns: analysis files use descriptive naming conventions, commit messages follow conventional format with detailed metrics, and all artifacts are centralized in the GitHub repository's docs directory. Visual documentation emphasizes dependency relationships through mind maps and Mermaid diagrams.
Project management integrates comprehensive progress tracking, milestone validation, and resource planning. Sessions include guardrail compliance checks, systematic preparation workflows, and detailed handoff reports for multi-session coordination.



## Tools & resources


The project relies heavily on GitHub integration through github-official MCP tools for repository management, issue tracking, and documentation commits. The sqlserver-to-postgresql-migration repository serves as the central hub with established directory structures and naming conventions.
AWS Schema Conversion Tool provides initial conversion baseline, though requiring significant manual correction. PostgreSQL 17 staging environment with 600GB disk space and proper CPU/RAM allocation supports testing and validation activities.
Sequential thinking tools support complex technical analysis and systematic quality assessment.
Context7 MCP and Serena tools assist with token usage monitoring and session resource management. File management tools handle artifact creation and delivery when GitHub API limitations require alternative approaches for large documents. Code-review plugin is an automated code review for pull requests using multiple specialized agents with confidence-based scoring. Feature-dev plugin is a comprehensive feature development workflow with specialized agents for codebase exploration, architecture design, and quality review. Serena plugin is a semantic code analysis MCP server providing intelligent code understanding, refactoring suggestions, and codebase navigation through language server protocol integration. Claude-mem is a persistent memory system for Claude Code - seamlessly preserve context across sessions. Claude Context is an MCP plugin that adds semantic code search to Claude Code and other AI coding agents, giving them deep context from your entire codebase.
