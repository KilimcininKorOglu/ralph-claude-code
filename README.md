# Ralph for Claude Code

Autonomous AI development loop system for Windows PowerShell. Supports multiple AI CLIs (Claude, Droid, Aider) with task-driven development, automatic branching, and intelligent resume.

## Documentation

| Document                                   | Description                       |
|--------------------------------------------|-----------------------------------|
| [Installation Guide](docs/installation.md) | Step-by-step installation         |
| [User Guide](docs/USER-GUIDE.md)           | Complete usage documentation      |
| [Example Usage](docs/example-usage.md)     | Step-by-step walkthrough with PRD |
| [Sample PRD](docs/sample-prd.md)           | E-commerce platform example PRD   |

## Features

### AI Integration

- **Multi-AI CLI Support** - Works with Claude, Droid, and Aider CLIs
- **Auto-Detection** - Automatically finds available AI CLI (priority: claude > droid > aider)
- **Provider Selection** - Override with `-AI` flag for all commands

### Task Management

- **PRD Parser (`ralph-prd`)** - Converts PRD documents to structured task files
- **Feature Add (`ralph-add`)** - Add single features inline or from file
- **Incremental Updates** - Re-run PRD parser without losing progress
- **ID Continuity** - Feature and Task IDs auto-increment across all files

### Task Mode Execution

- **Automatic Branching** - Creates feature branches (e.g., `feature/F001-authentication`)
- **Automatic Commits** - Commits on task completion with conventional format
- **Autonomous Mode** - Runs all tasks/features without pausing
- **Dependency Tracking** - Respects task dependencies before execution

### Status and Filtering

- **ASCII Status Tables** - Beautiful table display with `ralph -TaskStatus`
- **Live Monitor** - Real-time dashboard with `ralph-monitor`
- **Status Filtering** - Filter by COMPLETED, IN_PROGRESS, NOT_STARTED, BLOCKED
- **Feature/Priority Filtering** - Filter by Feature ID or Priority level

### Resume and Recovery

- **Automatic Resume** - Detects interrupted runs, resumes from checkpoint
- **Branch Restoration** - Switches to correct feature branch on resume
- **Progress History** - Tracks task completion with timestamps

### Safety and Control

- **Circuit Breaker** - Detects stagnation (no-progress loops)
- **Rate Limiting** - Configurable API calls per hour
- **Max Errors Threshold** - Stops after N consecutive errors

## Requirements

- **PowerShell 7+** (not Windows PowerShell 5.1)
- **Git**
- **One of:** Claude CLI, Droid CLI, or Aider

## Quick Start

```powershell
# Install Ralph
git clone https://github.com/frankbria/ralph-claude-code.git
cd ralph-claude-code
.\install.ps1

# Create a new project
ralph-setup my-project
cd my-project

# Create PRD and parse to tasks
ralph-prd docs/PRD.md

# Start Task Mode
ralph -TaskMode -AutoBranch -AutoCommit
```

## Commands

| Command                                   | Description                |
|-------------------------------------------|----------------------------|
| `ralph-setup <name>`                      | Create new project         |
| `ralph-prd <file>`                        | Parse PRD to task files    |
| `ralph-add "feature"`                     | Add single feature         |
| `ralph -TaskMode -AutoBranch -AutoCommit` | Run with full automation   |
| `ralph -TaskMode -Autonomous`             | Run without pausing        |
| `ralph -TaskStatus`                       | Show task progress table   |
| `ralph-monitor`                           | Live monitoring dashboard  |

## Supported AI Providers

| Provider | Command  | Priority |
|----------|----------|----------|
| Claude   | `claude` | 1        |
| Droid    | `droid`  | 2        |
| Aider    | `aider`  | 3        |

```powershell
# Specify provider
ralph -TaskMode -AI droid -AutoBranch -AutoCommit
ralph-prd docs/PRD.md -AI claude
ralph-add "feature" -AI aider
```

## Project Structure

```
my-project/
├── PROMPT.md           # AI instructions (auto-managed)
├── tasks/              # Task files
│   ├── 001-feature.md  # Feature with tasks
│   ├── 002-feature.md
│   ├── tasks-status.md # Status tracker
│   └── run-state.md    # Resume checkpoint
├── src/                # Source code
├── docs/               # Documentation
└── logs/               # Execution logs
```

## Task Mode Workflow

```
PRD.md -> ralph-prd -> tasks/*.md -> ralph -TaskMode -> Implementation
```

### Task File Format

```markdown
# Feature 1: User Authentication

**Feature ID:** F001
**Status:** NOT_STARTED

### T001: Database Schema

**Status:** NOT_STARTED
**Priority:** P1

#### Description
Create users table.

#### Success Criteria
- [ ] Migration runs
- [ ] Rollback works
```

### Branch Strategy

```
main
  └── feature/F001-authentication
        ├── feat(T001): Database Schema completed
        ├── feat(T002): Auth API completed
        └── feat(T003): Tests completed
```

## Circuit Breaker

Prevents runaway execution:

| State     | Meaning                          |
|-----------|----------------------------------|
| CLOSED    | Normal operation                 |
| HALF_OPEN | Monitoring (2 no-progress loops) |
| OPEN      | Halted (3+ no-progress loops)    |

Reset with: `ralph -ResetCircuit`

## Testing

```powershell
Import-Module Pester -Force
Invoke-Pester -Path tests/unit/
```

## Uninstall

```powershell
.\install.ps1 -Uninstall
```

## License

MIT License - See [LICENSE](LICENSE)
