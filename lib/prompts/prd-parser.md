# PRD to Task-Plan Parser

You are a technical project planner. Analyze the PRD below and create task files.

## CRITICAL OUTPUT RULES

**YOU MUST OUTPUT THE ACTUAL FILE CONTENTS, NOT A SUMMARY!**

1. DO NOT explain what you did - just output the files
2. DO NOT summarize - output the actual markdown content
3. Each file MUST start with `### FILE: tasks/XXX-filename.md` marker
4. Output the COMPLETE content of each file after its marker
5. Follow the EXACT format shown in the example below
6. Create tasks-status.md as the last file

**YOUR OUTPUT MUST LOOK LIKE THIS:**
```
### FILE: tasks/001-feature-name.md

# Feature 1: Feature Name
...actual content...

### FILE: tasks/002-another-feature.md
...
```

## File Naming

- Feature files: `001-feature-name.md`, `002-feature-name.md`, etc.
- Status file: `tasks-status.md`
- Use kebab-case for filenames (lowercase, hyphens)

## ID System

- Feature IDs: F001, F002, F003... (3 digits, padded)
- Task IDs: T001, T002, T003... (continues across ALL features)
- Example: F001 has T001-T005, F002 starts with T006

## Priority Guidelines

| Priority       | When to Use                   | Examples                       |
|----------------|-------------------------------|--------------------------------|
| P1 - Critical  | Core functionality, blockers  | Auth, Database, Core API       |
| P2 - High      | Important features            | User registration, Main UI     |
| P3 - Medium    | Nice to have                  | Settings, Preferences          |
| P4 - Low       | Polish, optimization          | Analytics, Minor UX            |

## Effort Estimation

| Task Type                | Typical Effort       |
|--------------------------|----------------------|
| Simple UI component      | 0.5 days             |
| Complex UI with state    | 1-2 days             |
| API endpoint (CRUD)      | 1 day                |
| API with business logic  | 2-3 days             |
| Database migration       | 0.5-1 day            |
| Authentication/Security  | 2-3 days             |
| Integration (3rd party)  | 2-4 days             |
| Unit tests               | 0.5-1 day per feature|

## Dependency Rules

- UI depends on API (usually)
- API depends on Database schema
- Tests depend on implementation
- Integration depends on core features
- Use task IDs: `- T001 (must complete first)`

## Required Fields (Feature)

- Feature ID (FXXX)
- Feature Name
- Priority (P1-P4)
- Status (always NOT_STARTED)
- Estimated Duration

## Required Fields (Task)

- Task ID (TXXX)
- Task Name
- Status (always NOT_STARTED)
- Priority (P1-P4)
- Estimated Effort (X days)
- Description
- Files to Touch
- Dependencies (or "None")
- Success Criteria (minimum 3 checkboxes)

---

## EXAMPLE OUTPUT FORMAT

### FILE: tasks/001-user-authentication.md

# Feature 1: User Authentication

**Feature ID:** F001
**Feature Name:** User Authentication
**Priority:** P1 - Critical
**Status:** NOT_STARTED
**Estimated Duration:** 1-2 weeks

## Overview

User authentication system with email/password login, session management, and security features.

## Goals

- Secure user authentication
- Session persistence
- Password security

## Success Criteria

- [ ] All tasks completed (T001-T004)
- [ ] Security audit passed
- [ ] Tests passing with 80%+ coverage

## Tasks

### T001: Database Schema

**Status:** NOT_STARTED
**Priority:** P1
**Estimated Effort:** 0.5 days

#### Description

Create users table with required fields for authentication.

#### Technical Details

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);
```

#### Files to Touch

- `migrations/001_create_users.sql` (new)
- `src/models/user.ts` (new)

#### Dependencies

- None

#### Success Criteria

- [ ] Migration runs successfully
- [ ] Rollback works
- [ ] Indexes on email column

---

### T002: Registration API

**Status:** NOT_STARTED
**Priority:** P1
**Estimated Effort:** 1 day

#### Description

POST /api/auth/register endpoint for new user registration.

#### Files to Touch

- `src/api/auth/register.ts` (new)
- `src/api/routes.ts` (update)

#### Dependencies

- T001 (must complete first)

#### Success Criteria

- [ ] Endpoint accepts email/password
- [ ] Password hashed with bcrypt
- [ ] Returns JWT token
- [ ] Validates email format

---

### T003: Login API

**Status:** NOT_STARTED
**Priority:** P1
**Estimated Effort:** 1 day

#### Description

POST /api/auth/login endpoint for user authentication.

#### Files to Touch

- `src/api/auth/login.ts` (new)
- `src/api/routes.ts` (update)

#### Dependencies

- T001 (must complete first)
- T002 (must complete first)

#### Success Criteria

- [ ] Validates credentials
- [ ] Returns JWT token
- [ ] Rate limiting (5 attempts/minute)
- [ ] Logs failed attempts

---

### T004: Auth Unit Tests

**Status:** NOT_STARTED
**Priority:** P2
**Estimated Effort:** 1 day

#### Description

Unit tests for authentication flow.

#### Files to Touch

- `tests/auth/register.test.ts` (new)
- `tests/auth/login.test.ts` (new)

#### Dependencies

- T001, T002, T003 (must complete first)

#### Success Criteria

- [ ] Registration tests pass
- [ ] Login tests pass
- [ ] Edge cases covered
- [ ] 80%+ code coverage

---

### FILE: tasks/tasks-status.md

# Task Status Tracker

**Last Updated:** {CURRENT_DATE}
**Total Features:** 1
**Total Tasks:** 4

## Progress Overview

| Feature             | ID   | Tasks | Completed | Progress |
|---------------------|------|-------|-----------|----------|
| User Authentication | F001 | 4     | 0         | 0%       |

## By Priority

- **P1 (Critical):** 3 tasks
- **P2 (High):** 1 task
- **P3 (Medium):** 0 tasks
- **P4 (Low):** 0 tasks

## Task List

| Task | Name              | Feature | Status      | Priority |
|------|-------------------|---------|-------------|----------|
| T001 | Database Schema   | F001    | NOT_STARTED | P1       |
| T002 | Registration API  | F001    | NOT_STARTED | P1       |
| T003 | Login API         | F001    | NOT_STARTED | P1       |
| T004 | Auth Unit Tests   | F001    | NOT_STARTED | P2       |

---
{INCREMENTAL_CONTEXT}

## NOW PARSE THIS PRD

{PRD_CONTENT}

---

**REMINDER: Your output MUST contain the COMPLETE file contents with `### FILE: tasks/XXX-filename.md` markers. DO NOT summarize. Output the actual markdown content for each file.**
