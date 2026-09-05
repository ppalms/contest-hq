# Memory & Context Compaction

For tasks spanning >30 minutes or multiple sessions.

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

## Token Estimation
- **Code**: ~4 chars/token
- **Prose**: ~5 chars/token
- **Large files**: >500 lines ≈ 2K tokens each

## Compaction Strategy
- **Threshold**: Summarize when approaching 150K tokens
- **Priority preservation**: System prompt, recent files, memory files, active task
- **Discard candidates**: Old tool results, resolved issues, redundant file reads
- **Process**: Create PROGRESS.md → continue with summary → read TODO.md, NOTES.md, PROGRESS.md

## Monitoring Guidelines
- Track approximate token usage throughout session
- Proactively compact before hitting limits
- Keep working set focused and relevant

## Design capture
The plan agent's output (user story, glossary, acceptance scenarios) carries design decisions. Prefer promoting those to a design doc over ad-hoc NOTES.md entries.
