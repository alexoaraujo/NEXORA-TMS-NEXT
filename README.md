# NEXORA TMS NEXT

## Official Engineering Infrastructure

NEXORA TMS NEXT is governed by PEOS and integrated across GitHub, Neon PostgreSQL, and Atlassian Jira/Confluence.

### System-of-record boundaries

| Layer | System | Responsibility |
|---|---|---|
| Governance | PEOS | Prompts, agents, engineering rules, quality/release gates |
| Work management | Jira | Backlog, epics, stories, tasks, bugs, dependencies |
| Knowledge | Confluence | Architecture, ADRs, specifications, runbooks |
| Source control | GitHub | Source code, branches, PRs, CI/CD, repository governance |
| Data | Neon | PostgreSQL Development, Staging and Production |

### Engineering flow

Requirement -> Jira -> ADR when needed -> Git branch -> implementation -> tests -> PR -> review -> quality gates -> Staging -> release gate -> Production -> evidence.

### PEOS baseline

The repository follows Evidence-First execution and the PEOS prompt families 0021, 0022, 0023, 0024, 0025, 0026, 0028, 3501, 3502, 3505, 3506, 3509, 3510, 3511 and 3512.

Do not treat absent configuration as configured. Current infrastructure state must be verified through the connected systems before release or production changes.
