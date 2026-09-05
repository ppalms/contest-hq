# AGENTS.md - Quick Reference for Coding Agents

## Essential Commands
```bash
bin/rails test                           # Run all unit/integration tests
bin/rails test:system                    # Run system tests
bin/rails test test/models/user_test.rb:27  # Run single test defined at line 27
bin/rubocop -f github                    # Lint code (required before commit)
bin/brakeman --no-pager                  # Security scan (required)
bin/dev                                  # Start dev server at localhost:3000
```

## Code Style & Conventions
- **Linting**: Uses rubocop-rails-omakase configuration (Rails defaults)
- **Classes**: `CamelCase` for models/controllers, `snake_case` for methods/variables
- **Indentation**: 2 spaces, no tabs (enforced by rubocop)
- **Imports**: Use Rails autoloading - avoid explicit requires
- **NO COMMENTS**: Do not add code comments unless explicitly requested

## Critical Patterns
- **Models**: Must include `AccountScoped` for multi-tenant models
- **Controllers**: Use `authenticate` before_action for auth
- **Current Context**: Access via `Current.user`, `Current.account`, `Current.selected_account`
- **Roles**: Check with `user.sys_admin?`, `account_admin?`, `director?`, `manager?`, `judge?`
- **Manager Auth**: Use `user.manages_contest(contest_id)` for contest-specific permissions

## Testing Patterns
```ruby
# Integration tests (controllers)
sign_in_as(create(:user, :account_admin))  # HTTP login; uses TEST_PASSWORD

# System tests
log_in_as(create(:user, :director))        # Browser login; sets Current context

# Unit tests (models/services)
set_current_user(create(:user, :account_admin))  # Sets Current directly

# All tests auto-cleanup Current context in teardown
```

## Context Files

Role-specific guidance lives in `.opencode/context/` (`retrieval-and-tools.md`, `rails-reference.md`, `subagent-output-contract.md`, etc.) and is loaded into every agent automatically via the `instructions` array in `opencode.jsonc`. Read one when its topic applies to your task.

## Feature Work & Commits

Feature work starts with the backlog item. The plan agent (see PLANNING.md) turns it into a user story, domain glossary, and acceptance scenarios before implementation. Build implements scenario-first.

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

A pre-commit hook in `.githooks/pre-commit` (wired via `bin/setup`) enforces rubocop + brakeman for both humans and agents.

## Known Issues

- **`bin/setup` provisions PostgreSQL via Docker Compose** (`docker compose up -d db --wait`), but the actual stack is SQLite3 multi-database (primary, cache, queue, cable) — see `config/database.yml` and `rails-reference.md`. The PostgreSQL step is a leftover and wastes setup time / requires Docker for no reason. Fix: remove the docker step and the `puts "\n== Starting PostgreSQL with Docker =="` block from `bin/setup`.

- **Quality gate below does not run system tests by default** — system tests are slow and CI covers them separately. If a change touches UI flows, invoke `@quality-gate` with an explicit request for `test:system`.
