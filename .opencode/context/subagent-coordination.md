# Subagent Coordination

## Available Subagents
- **@code-search**: Deep codebase exploration, pattern discovery
- **@test-runner**: Execute tests, parse results, identify failures
- **@linter**: Run rubocop/brakeman, report code quality issues
- **@quality-gate**: Pre-commit quality gate (rubocop + brakeman + tests)

## Delegation Guidelines
- **Complex searches** (multiple rounds): @code-search
- **Test execution and analysis**: @test-runner
- **Code quality validation** (required before commits): @linter
- **Pre-commit gate** (all checks at once): @quality-gate
- **Parallel invocation**: Launch multiple subagents for independent tasks

## Note on superpowers
Parallel coordination patterns are also covered by superpowers `dispatching-parallel-agents` and `subagent-driven-development` skills. This file provides the project-specific subagent roster.
