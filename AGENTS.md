# AGENTS.md - Quick Reference for Coding Agents

**For: Claude Sonnet 4.5 (execution mode)**

## Essential Commands
```bash
bin/rails test                           # Run all unit/integration tests (~36s)
bin/rails test:system                    # Run system tests (~6.5min)
bin/rails test test/models/user_test.rb:27  # Run single test at line 27
bin/rubocop -f github                    # Lint code (required before commit)
bin/brakeman --no-pager                  # Security scan (required)
bin/dev                                  # Start dev server at localhost:3000
```

## System Architecture - Rails 8.1.0 with Ruby 3.3.5
- **Database**: SQLite3 with multi-database setup (primary, cache, queue, cable)
- **Storage**: SQLite files in `storage/` directory
- **Multi-tenancy**: Account-based isolation via `AccountScoped` concern
- **Authentication**: Session-based via authentication-zero gem
- **Background Jobs**: Solid Queue (SQLite-backed)
- **Caching**: Solid Cache (SQLite-backed)

## Code Style & Conventions
- **Linting**: Uses rubocop-rails-omakase configuration (Rails defaults)
- **Classes**: `CamelCase` for models/controllers, `snake_case` for methods/variables
- **Indentation**: 2 spaces, no tabs (enforced by rubocop)
- **Imports**: Use Rails autoloading - avoid explicit requires
- **NO COMMENTS**: Do not add code comments unless explicitly requested

## Context Engineering

Load context files based on your role and task:

| Agent | Task Type | Load File |
|-------|-----------|-----------|
| **build** | Feature work, commits | `.opencode/context/subagent-coordination.md` |
| **build** | Codebase navigation, pattern discovery | `.opencode/context/retrieval-and-tools.md` |
| **build** | Tasks >30 min, multi-session work | `.opencode/context/memory-and-compaction.md` |
| **build** | Rails fixtures, debug commands | `.opencode/context/rails-reference.md` |
| **code-search** | Before starting search | `.opencode/context/retrieval-and-tools.md` |
| **test-runner** | Rails testing reference | `.opencode/context/rails-reference.md` |
| **quality-gate** | Pre-commit validation | `.opencode/context/rails-reference.md` |
| **all subagents** | Output formatting | `.opencode/context/subagent-output-contract.md` |

**When to load**:
- Load relevant files at task start based on table above
- Build agent: Load multiple files for complex tasks

## Critical Patterns
- **Models**: Must include `AccountScoped` for multi-tenant models
- **Controllers**: Use `authenticate` before_action for auth
- **Current Context**: Access via `Current.user`, `Current.account`, `Current.selected_account`
- **Roles**: Check with `user.sys_admin?`, `account_admin?`, `director?`, `manager?`, `judge?`
- **Manager Auth**: Use `user.manages_contest(contest_id)` for contest-specific permissions

## Testing Patterns
```ruby
# Integration tests (controllers/system)
sign_in_as(users(:demo_admin_a))  # Uses fixture, password: "Secret1*3*5*"

# Unit tests (models/services)
set_current_user(users(:demo_admin_a))  # Sets Current context directly

# All tests auto-cleanup Current context in teardown
```

## Execution Mode
- **Execute the plan** provided - don't re-strategize
- **Ask clarifying questions** only about implementation details
- **Request a plan** if none provided for complex work

## Feature Work & Commits

### Relationship to superpowers
The superpowers plugin provides the full development methodology: brainstorming → writing-plans → test-driven-development (RED-GREEN-REFACTOR) → subagent-driven-development → requesting-code-review → finishing-a-development-branch. This AGENTS.md adds project-specific gates on top of that workflow.

### Acceptance Criteria Gate
If no acceptance criteria are provided for a feature, STOP and prompt the user before writing tests:
```
⚠️ No acceptance criteria provided for this feature.

To write effective tests, I need to understand:
1. What specific behavior should this feature implement?
2. What are the success conditions?
3. What edge cases should be handled?

Please provide acceptance criteria or user stories for this feature.
```

### Quality Gate (Required Before Commit)
Invoke `@quality-gate` before any feature commit. Default scope = rubocop + brakeman + unit/integration tests. Request system tests explicitly for UI-affecting changes or pre-PR validation.

**If quality gate PASSES**: Proceed to commit.
**If quality gate FAILS**: Fix issues and retry. Do NOT commit until it passes.
