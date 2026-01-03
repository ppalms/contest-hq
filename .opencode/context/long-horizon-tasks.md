# Long-Horizon Task Management

For tasks spanning >30 minutes or multiple sessions:

## Memory Files (create in project root)
- **TODO.md**: Track task status (pending/in_progress/completed/blocked)
- **NOTES.md**: Record architectural decisions, patterns discovered, blockers
- **PROGRESS.md**: Summarize work before context reset

## Memory Strategy
- **Update TODO.md**: After each task completion
- **Record in NOTES.md**: Immediately when making decisions
- **Create PROGRESS.md**: Before context reset (>150K tokens)
- **Read at startup**: Check for existing memory files to restore context
- **Preserve**: Decisions, unresolved issues, dependencies, test results
- **Discard**: Old tool outputs, resolved discussions, redundant file reads

## Context Reset Process
1. Create PROGRESS.md with summary of completed work
2. Note current state and next steps
3. Continue with fresh context
4. Read TODO.md, NOTES.md, PROGRESS.md to restore state
