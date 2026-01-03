# Tool Efficiency Guidelines

## Tool Selection Heuristics
- **Known paths**: Use Read directly (`app/models/user.rb`)
- **Pattern matching**: Use Glob for file discovery (`**/*_test.rb`)
- **Content search**: Use Grep for code patterns (`include AccountScoped`)
- **Complex searches**: Delegate to @code-search subagent
- **Large files**: Read specific line ranges or use Bash head/tail
- **Parallel operations**: Read multiple files in single message
- **Avoid Bash for file ops**: Prefer Read/Glob/Grep over cat/find/grep

## Efficiency Patterns
- Search before read (Glob/Grep → Read)
- Batch related operations in parallel
- Use most specific tool available
