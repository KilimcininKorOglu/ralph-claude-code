# Feature Analyzer

You are a technical project planner. Analyze the feature description below and create a detailed task breakdown.

## Output Rules

1. Output ONLY the file content - no explanations, no commentary
2. Start with `### FILE: tasks/{FILE_NUMBER}-feature-name.md` marker
3. Follow the exact format shown below
4. Use kebab-case for filename (lowercase, hyphens)

## Starting IDs

- Feature ID: F{NEXT_FEATURE_ID}
- First Task ID: T{NEXT_TASK_ID}
- Continue task IDs sequentially (T{NEXT_TASK_ID}, T{NEXT_TASK_ID+1}, ...)

{PRIORITY_INSTRUCTION}

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

## OUTPUT FORMAT EXAMPLE

### FILE: tasks/{FILE_NUMBER}-user-registration.md
# Feature {NEXT_FEATURE_ID}: User Registration

**Feature ID:** F{NEXT_FEATURE_ID}
**Feature Name:** User Registration
**Priority:** P2 - High
**Status:** NOT_STARTED
**Estimated Duration:** 1-2 weeks

## Overview

User registration system with email/password, validation, and database integration.

## Goals

- Allow users to register
- Secure password storage
- Email validation

## Success Criteria

- [ ] All tasks completed
- [ ] Tests passing with 80%+ coverage
- [ ] Documentation complete

## Tasks

### T{NEXT_TASK_ID}: Registration Form UI

**Status:** NOT_STARTED
**Priority:** P2
**Estimated Effort:** 1 day

#### Description

Create registration page with form components.

#### Files to Touch

- `src/components/RegisterForm.tsx` (new)
- `src/pages/register.tsx` (new)

#### Dependencies

- None

#### Success Criteria

- [ ] Form renders correctly
- [ ] Responsive design
- [ ] Accessibility compliant
- [ ] Loading state present

---

### T{NEXT_TASK_ID+1}: Input Validation

**Status:** NOT_STARTED
**Priority:** P2
**Estimated Effort:** 0.5 days

#### Description

Email format and password strength validation.

#### Files to Touch

- `src/utils/validation.ts` (new)

#### Dependencies

- T{NEXT_TASK_ID} (must complete first)

#### Success Criteria

- [ ] Email format validation works
- [ ] Password strength check (min 8 chars, upper/lower, number)
- [ ] User-friendly error messages
- [ ] Real-time validation feedback

---

(Continue with more tasks as needed...)

---

## NOW ANALYZE THIS FEATURE:

{FEATURE_DESCRIPTION}
