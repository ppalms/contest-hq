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

## TDD Workflow (Test-Driven Development)

**REQUIRED for all feature work:**

### 1. Check Acceptance Criteria
Before starting any feature implementation:
- **If acceptance criteria provided**: Proceed to step 2
- **If NO acceptance criteria**: STOP and prompt user with:
  ```
  ⚠️ No acceptance criteria provided for this feature.
  
  To write effective tests, I need to understand:
  1. What specific behavior should this feature implement?
  2. What are the success conditions?
  3. What edge cases should be handled?
  
  Please provide acceptance criteria or user stories for this feature.
  ```

### 2. Write Tests First (Red Phase)
- Write failing tests based on acceptance criteria
- Cover happy path, edge cases, and error conditions
- Use appropriate test helpers:
  - Integration tests: `sign_in_as(users(:fixture_name))`
  - Unit tests: `set_current_user(users(:fixture_name))`
- Run tests to confirm they fail: `bin/rails test path/to/test.rb`

### 3. Implement Feature (Green Phase)
- Write minimal code to make tests pass
- Follow Rails conventions and multi-tenancy patterns
- Run tests frequently to verify progress

### 4. Refactor (Refactor Phase)
- Clean up implementation
- Ensure code follows style guidelines
- Run tests to ensure refactoring didn't break functionality

### 5. Quality Gate (Required Before Commit)
**CRITICAL**: Invoke quality-gate agent before ANY commit:
```
@quality-gate
```

The quality gate will:
- ✅ Check for uncommitted changes
- ✅ Run rubocop (style)
- ✅ Run brakeman (security)
- ✅ Run rails_best_practices (code quality)
- ✅ Run all tests (unit + system)

**If quality gate PASSES**: Proceed to commit
**If quality gate FAILS**: Fix issues and retry (do NOT commit)

## Completion Workflow

```bash
# 1. Prompt for acceptance criteria (if missing)
# User provides criteria

# 2. Write tests (TDD - should fail initially)
# Create test files following patterns in test/

# 3. Implement feature
# Write code to make tests pass

# 4. Invoke quality gate (REQUIRED)
@quality-gate

# 5. If quality gate PASSES:
git checkout -b feature/brief-description
git add .
git commit -m "Clear description of changes"
git push -u origin feature/brief-description

# 6. If quality gate FAILS:
# - Review failure report
# - Fix issues (linter violations, test failures, etc.)
# - Re-run quality gate
# - Do NOT commit until quality gate passes

# 7. Create PR with summary:
# - What changed and why
# - Acceptance criteria met
# - Files modified
# - Quality gate validation results
```

## Quality Gate Integration

The quality-gate agent is a **mandatory checkpoint** before commits:

### When to Invoke
- After feature implementation complete
- Before any `git commit` command
- After fixing issues from previous quality gate run

### What It Checks
1. **Uncommitted changes** - Ensures clean working directory
2. **Code style** - Rubocop with rails-omakase config
3. **Security** - Brakeman static analysis
4. **Best practices** - Rails best practices analyzer
5. **Tests** - All unit and system tests

### Handling Failures

**Linter Violations:**
```
❌ Rubocop: 5 offenses
   - app/models/user.rb:42 - Style/StringLiterals
   - app/controllers/contests_controller.rb:15 - Layout/LineLength

Action: Fix style issues and re-run quality gate
```

**Test Failures:**
```
❌ Tests: 2 failures
   - UserTest#test_account_scoping (test/models/user_test.rb:27)
   - ContestsControllerTest#test_manager_access (test/controllers/contests_controller_test.rb:45)

Action: Fix failing tests and re-run quality gate
```

**Security Warnings:**
```
❌ Brakeman: 1 high-confidence warning
   - SQL Injection (app/models/contest.rb:89)

Action: Fix security issue immediately and re-run quality gate
```

### Never Skip Quality Gate
- No `--no-verify` or force commits
- All checks must pass before commit
- Maintains code quality and prevents regressions
