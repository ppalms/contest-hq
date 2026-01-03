# Context Monitoring & Compaction

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
