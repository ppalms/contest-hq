# Subagent Coordination

## Available Subagents
- **@code-search**: Deep codebase exploration, pattern discovery
- **@test-runner**: Execute tests, parse results, identify failures
- **@linter**: Run rubocop/brakeman, report code quality issues

## Delegation Guidelines
- **Complex searches** (multiple rounds): @code-search
- **Test execution and analysis**: @test-runner
- **Code quality validation** (required before commits): @linter
- **Parallel invocation**: Launch multiple subagents for independent tasks

## Output Constraints (for subagents)
- **Token budget**: Return 1,000-2,000 token summary maximum
- **Focus**: Include only essential findings, not raw output
- **Format**: Use file:line references over full code snippets
- **Prioritize**: Actionable insights over comprehensive data dumps
