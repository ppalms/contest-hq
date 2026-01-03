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
| **build** | Codebase navigation, pattern discovery | `.opencode/context/retrieval-strategy.md` |
| **build** | Tool selection, file operations | `.opencode/context/tool-efficiency.md` |
| **build** | Tasks >30 min, multi-session work | `.opencode/context/long-horizon-tasks.md` |
| **build** | Context >100K tokens, compaction | `.opencode/context/context-monitoring.md` |
| **build** | Delegating to subagents | `.opencode/context/subagent-coordination.md` |
| **build** | Rails fixtures, debug commands | `.opencode/context/rails-reference.md` |
| **code-search** | Before starting search | `.opencode/context/retrieval-strategy.md` |
| **test-runner** | Rails testing reference | `.opencode/context/rails-reference.md` |
| **linter** | Rails code style reference | `.opencode/context/rails-reference.md` |
| **all subagents** | Output formatting | `.opencode/context/subagent-coordination.md` |

**When to load**:
- Load relevant files at task start based on table above
- Build agent: Load multiple files for complex tasks
- Subagents: Automatically loaded via frontmatter `instructions`

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

## Completion Workflow
```bash
# 1. Validate (all must pass)
bin/rubocop -f github && bin/brakeman --no-pager && bin/rails test && bin/rails test:system

# 2. Branch and commit
git checkout -b feature/brief-description
git add .
git commit -m "Clear description of changes"
git push -u origin feature/brief-description

# 3. Create PR with summary:
# - What changed and why
# - Files modified
# - Validation results (rubocop, brakeman, tests)
# - Manual testing performed
```
