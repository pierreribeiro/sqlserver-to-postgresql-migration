# Activity Tracking Process
## Perseus Database Migration Project

**Document Type:** Process Definition
**Version:** 1.0
**Created:** 2026-01-18
**Owner:** Pierre Ribeiro

---

## 1. Overview

This document defines the activity tracking process for the Perseus Database Migration project. It establishes standards for tracking progress, reporting status, and maintaining project visibility.

---

## 2. Tracking Artifacts

### 2.1 Primary Tracking Documents

| Document | Location | Update Frequency | Owner |
|----------|----------|------------------|-------|
| **Progress Tracker** | tracking/progress-tracker.md | Daily (during active sprints) | Pierre |
| **Priority Matrix** | tracking/priority-matrix.csv | Per sprint (or when priorities change) | Pierre |
| **Sprint Archive** | tracking/progress-tracker-archive-sprints-*.md | End of sprint | Pierre |
| **Activity Log** | tracking/activity-log-YYYY-MM.md | Per session | Claude/Pierre |

### 2.2 Supporting Documents

| Document | Location | Purpose |
|----------|----------|---------|
| GitHub Issues | GitHub Repository | Task tracking & assignments |
| PR Comments | GitHub Repository | Code review feedback |
| Dependency Analysis | docs/code-analysis/ | Technical reference |

---

## 3. Tracking Process

### 3.1 Daily Tracking (During Active Sprints)

**Trigger:** Start of each work session

**Actions:**
1. Update `tracking/progress-tracker.md`:
   - Mark completed tasks
   - Update time spent
   - Note any blockers
   - Update metrics dashboard

2. Log activity in `tracking/activity-log-YYYY-MM.md`:
   - Session date/time
   - Tasks worked on
   - Decisions made
   - Issues encountered

### 3.2 Task Completion Tracking

**When a task is completed:**

1. **Update Priority Matrix (tracking/priority-matrix.csv):**
   ```
   status: CORRECTED (or appropriate status)
   actual_hours: [actual time]
   notes: [key details, quality score, issue reference]
   ```

2. **Update Progress Tracker:**
   - Mark task as complete
   - Update percentage complete
   - Note any follow-up items

3. **Close GitHub Issue (if applicable):**
   - Add completion comment with metrics
   - Close issue with appropriate labels

### 3.3 Sprint Tracking

**At Sprint Start:**
1. Create sprint section in progress-tracker.md
2. Define objectives and success criteria
3. Assign tasks with time estimates
4. Create GitHub issues for each task

**During Sprint:**
1. Daily progress updates
2. Weekly status report (see Section 4.2)
3. Blocker escalation within 24 hours

**At Sprint End:**
1. Archive sprint data to progress-tracker-archive-sprints-*.md
2. Calculate sprint metrics
3. Document lessons learned
4. Plan next sprint

---

## 4. Reporting

### 4.1 Daily Status Update

**Format:**
```markdown
## Daily Status - [YYYY-MM-DD]

### Completed Today
- [Task]: [Brief description] [Time spent]

### In Progress
- [Task]: [Status] [% complete]

### Blockers
- [Blocker]: [Impact] [Escalation needed?]

### Tomorrow's Plan
- [Task]: [Estimated time]
```

### 4.2 Weekly Status Report

**Frequency:** End of each week (Friday)
**Audience:** Stakeholders, Team

**Template:**
```markdown
# Weekly Status Report - Week [N] (YYYY-MM-DD to YYYY-MM-DD)

## Executive Summary
[1-2 sentence summary of week's progress]

## Metrics
| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Tasks Completed | [N] | [N] | [emoji] |
| Hours Invested | [N]h | [N]h | [emoji] |
| Quality Score Avg | 8.0 | [N] | [emoji] |
| Blockers Resolved | [N] | [N] | [emoji] |

## Completed This Week
1. [Task/Milestone]: [Summary] [Quality Score if applicable]
2. ...

## In Progress
1. [Task]: [Status] [Expected completion]
2. ...

## Blockers & Risks
| Issue | Impact | Mitigation | Owner |
|-------|--------|------------|-------|
| [Issue] | [Impact] | [Action] | [Name] |

## Next Week's Plan
1. [Task]: [Priority] [Estimated hours]
2. ...

## Decisions Needed
- [Decision]: [Options] [Deadline]
```

### 4.3 Sprint Report

**Frequency:** End of each sprint
**Audience:** Project stakeholders

**Template:**
```markdown
# Sprint [N] Report

## Sprint Goal
[Sprint objective statement]

## Results Summary
| Metric | Target | Actual | Variance |
|--------|--------|--------|----------|
| Tasks Planned | [N] | [N] | [±N] |
| Tasks Completed | [N] | [N] | [±N] |
| Hours Budgeted | [N]h | [N]h | [±N]h |
| Quality Score Avg | 8.0 | [N] | [±N] |

## Deliverables
- [x] [Deliverable 1]: [Status]
- [x] [Deliverable 2]: [Status]
- [ ] [Deliverable 3]: [Reason incomplete]

## Quality Summary
| Object | Quality Score | Issues Resolved |
|--------|---------------|-----------------|
| [Object 1] | [N]/10 | P0: [N], P1: [N], P2: [N] |
| ...

## Lessons Learned
### What Went Well
- [Item]

### What Could Improve
- [Item]

### Action Items
- [Action]: [Owner] [Due Date]

## Next Sprint Preview
[Brief description of next sprint focus]
```

---

## 5. Metrics & KPIs

### 5.1 Project-Level Metrics

| Metric | Formula | Target | Tracking Location |
|--------|---------|--------|-------------------|
| **Overall Progress** | Completed Objects / Total Objects | 100% | progress-tracker.md |
| **Quality Score Average** | Sum(Quality Scores) / Count | ≥8.0/10 | priority-matrix.csv |
| **Time Efficiency** | Actual Hours / Budgeted Hours | ≤100% | priority-matrix.csv |
| **P0 Resolution Rate** | P0 Resolved / P0 Identified | 100% | GitHub Issues |
| **Sprint Velocity** | Story Points Completed / Sprint | Stable | Sprint reports |

### 5.2 Object-Level Metrics

Tracked in `priority-matrix.csv`:

| Metric | Description |
|--------|-------------|
| **original_loc** | Original T-SQL lines of code |
| **converted_loc** | PostgreSQL lines of code |
| **aws_sct_warnings** | AWS SCT warnings count |
| **criticality_score** | Business criticality (1-5) |
| **complexity_score** | Technical complexity (1-5) |
| **estimated_hours** | Original time estimate |
| **actual_hours** | Actual time spent |
| **quality_score** | Final quality score (0-10) |
| **status** | Current status |

### 5.3 Status Values

```
EXTRACTED       → Original T-SQL extracted + AWS SCT conversion done
ANALYZED        → Analysis complete, ready for correction
IN_PROGRESS     → Currently being worked on
CORRECTED       → Correction complete, ready for testing
TESTING         → Testing phase
DEV_DEPLOYED    → Deployed to DEV environment
STAGING_DEPLOYED → Deployed to STAGING
PRODUCTION_DEPLOYED → In production
COMPLETED       → Fully done with retrospective
```

---

## 6. Activity Log Template

**Location:** `tracking/activity-log-YYYY-MM.md`

```markdown
# Activity Log - [Month] [Year]

---

## [YYYY-MM-DD]

**Session:** [Start Time] - [End Time] ([Duration])
**Sprint:** [Sprint N]
**Focus:** [Brief description]

### Tasks Worked
1. **[Task Name]**
   - Status: [Started/Continued/Completed]
   - Time: [Duration]
   - Notes: [Key observations]
   - Issues: [Any problems encountered]

### Decisions Made
- [Decision]: [Rationale]

### Artifacts Created/Updated
- [File/Document]: [Brief description]

### Follow-up Items
- [ ] [Item]: [Priority] [Due]

---
```

---

## 7. GitHub Integration

### 7.1 Issue Tracking

**Issue Labels:**
| Label | Purpose |
|-------|---------|
| `priority:P0` | Critical blocking issues |
| `priority:P1` | High priority |
| `priority:P2` | Medium priority |
| `priority:P3` | Low priority |
| `sprint:N` | Sprint assignment |
| `type:procedure` | Stored procedure work |
| `type:function` | Function work |
| `type:view` | View work |
| `status:in-progress` | Currently being worked |
| `status:review` | Needs review |
| `status:blocked` | Blocked by dependency |

### 7.2 Issue Template

```markdown
## Description
[Brief description of the work item]

## Object Details
- **Name:** [Object name]
- **Type:** [Procedure/Function/View/Type]
- **Priority:** [P0/P1/P2/P3]
- **Sprint:** [Sprint N]

## Acceptance Criteria
- [ ] PostgreSQL syntax validates
- [ ] Logic matches SQL Server original
- [ ] Quality score ≥8.0/10
- [ ] Unit tests pass
- [ ] Documentation updated

## Dependencies
- [Dependency 1]
- [Dependency 2]

## Estimated Effort
[N] hours
```

### 7.3 Commit Message Format

```
<type>(<scope>): <description>

- <change 1>
- <change 2>

Quality: [N]/10
Time: [N]h
Closes #[issue number]
```

**Types:**
- `feat` - New feature/conversion
- `fix` - Bug fix
- `docs` - Documentation
- `refactor` - Refactoring
- `test` - Tests
- `chore` - Maintenance

**Example:**
```
feat(procedure): convert ReconcileMUpstream to PL/pgSQL

- Converted temp table initialization pattern
- Fixed transaction control (P0)
- Removed unnecessary LOWER() calls (P1)
- Added explicit error handling

Quality: 8.2/10
Time: 5h
Closes #27
```

---

## 8. Escalation Process

### 8.1 Blocker Escalation

| Blocker Type | Response Time | Escalation Path |
|--------------|---------------|-----------------|
| **P0 - Critical** | Immediate | Project Owner → Technical Lead → Management |
| **P1 - High** | 4 hours | Project Owner → Technical Lead |
| **P2 - Medium** | 24 hours | Project Owner |
| **P3 - Low** | Next sprint | Backlog |

### 8.2 Escalation Template

```markdown
## Blocker Escalation

**Date:** [YYYY-MM-DD]
**Severity:** [P0/P1/P2/P3]
**Reported By:** [Name]

### Issue Description
[Clear description of the blocker]

### Impact
- [What is blocked]
- [Timeline impact]
- [Business impact]

### Root Cause (if known)
[Root cause analysis]

### Proposed Solutions
1. [Option 1]: [Pros/Cons]
2. [Option 2]: [Pros/Cons]

### Decision Needed By
[Date/Time]

### Stakeholders
- [Name]: [Role]
```

---

## 9. Review & Improvement

### 9.1 Process Review Schedule

| Review Type | Frequency | Participants |
|-------------|-----------|--------------|
| Daily Standup | Daily | Project team |
| Sprint Retrospective | End of sprint | Project team |
| Process Review | Monthly | Project owner + stakeholders |

### 9.2 Continuous Improvement

After each sprint retrospective:
1. Document lessons learned
2. Identify process improvements
3. Update this document if needed
4. Communicate changes to team

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-18 | Pierre Ribeiro + Claude | Initial release |

---

**End of Tracking Process Document**
