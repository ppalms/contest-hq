# Quality Check Commands

Canonical commands for code quality and test execution. Referenced by @linter, @quality-gate, @test-runner.

## Commands
- `bin/rubocop -f github` — style check
- `bin/brakeman --no-pager` — security scan
- `bin/rails test` — unit/integration tests
- `bin/rails test:system` — system tests (only when explicitly requested)

## Pass/Fail Semantics
- Rubocop: 0 offenses required
- Brakeman: 0 high-confidence warnings required
- Tests: 0 failures, 0 errors required
