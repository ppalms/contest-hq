# Subagent Output Contract

All subagents must follow these output constraints.

## Token Budget
- Return 1,000-2,000 token summary maximum
- Include only essential findings, not raw tool output

## Format
- Use file:line references over full code snippets
- Prioritize actionable insights over comprehensive data dumps
- Start response with PASSED or FAILED as the first word (where applicable)

## Do NOT
- Make code changes or edits
- Run tasks outside your defined role
