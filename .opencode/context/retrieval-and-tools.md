# Context Retrieval & Tool Efficiency

## Progressive Disclosure
1. **Start broad**: Use Glob to find files (`**/*_controller.rb`)
2. **Search content**: Use Grep to find patterns (`AccountScoped`)
3. **Read selectively**: Read only promising files
4. **Targeted inspection**: For large files (>500 lines), read specific line ranges

## Just-in-Time Loading
- **Avoid preemptive reads**: Don't read files "just in case"
- **Use metadata**: Folder structure and naming provide signals
- **Batch parallel reads**: Read multiple known files in single message
- **Delegate complex searches**: Use @code-search for multi-round investigations
- **Don't re-read**: Track what's already in context

## Tool Selection Heuristics
- **Known paths**: Use Read directly (`app/models/user.rb`)
- **Pattern matching**: Use Glob for file discovery (`**/*_test.rb`)
- **Content search**: Use Grep for code patterns (`include AccountScoped`)
- **Complex searches**: Delegate to @code-search subagent
- **Large files**: Read specific line ranges or use Bash head/tail
- **Parallel operations**: Read multiple files in single message
- **Avoid Bash for file ops**: Prefer Read/Glob/Grep over cat/find/grep

## Navigation Efficiency
- File paths are lightweight identifiers - use them
- Read file metadata (size, modified date) before full read
- Use head/tail for initial assessment of large files
