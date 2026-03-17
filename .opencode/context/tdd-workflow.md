# TDD Workflow & Quality Gate

**Load this context when implementing features or preparing commits.**

## TDD Workflow (Test-Driven Development)

**REQUIRED for all feature work:**

### 1. Check Acceptance Criteria
Before starting any feature implementation:
- **If acceptance criteria provided**: Record in NOTES.md, proceed to step 2
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
- ✅ Run rubocop (style)
- ✅ Run brakeman (security)
- ✅ Run all tests (unit + system)

**If quality gate PASSES**: Proceed to commit
**If quality gate FAILS**: Fix issues and retry (do NOT commit)

## Completion Workflow

```bash
# 1. Prompt for acceptance criteria (if missing)
# User provides criteria → Record in NOTES.md

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
1. **Code style** - Rubocop with rails-omakase config
2. **Security** - Brakeman static analysis
3. **Tests** - All unit and system tests

### Handling Failures

**Linter Violations:**
```
❌ Rubocop: 5 offenses
   - app/models/user.rb:42 - Style/StringLiterals

Action: Fix style issues and re-run quality gate
```

**Test Failures:**
```
❌ Tests: 2 failures
   - UserTest#test_account_scoping (test/models/user_test.rb:27)

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

## Memory Integration

For long feature implementations:
- **NOTES.md**: Record acceptance criteria and architectural decisions
- **TODO.md**: Track TDD phase progress (tests written, implementation, refactoring)
- **PROGRESS.md**: Summarize before context reset
