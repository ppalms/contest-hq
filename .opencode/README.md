# OpenCode Configuration

This directory contains the OpenCode agent configuration for the Contest HQ project.

## Structure

```
.opencode/
├── README.md           # This file
└── prompts/
    ├── code-search.md  # Code search subagent prompt
    ├── test-runner.md  # Test execution subagent prompt
    └── linter.md       # Code quality subagent prompt
```

## Agent Configuration

The project uses multiple specialized agents configured in `opencode.json`:

### Primary Agents

#### **Plan Agent** (Claude Opus 4)
- **Role**: Architectural planning and strategic decisions
- **Instructions**: Uses `PLANNING.md` for guidance
- **When to use**: Switch to Plan mode (Tab key) when you want strategic advice
- **Model**: `anthropic/claude-opus-4-20250514`

#### **Build Agent** (Claude Sonnet 4.5)
- **Role**: Code execution and implementation
- **Instructions**: Uses `AGENTS.md` for execution patterns
- **When to use**: Default mode for making code changes
- **Model**: Default (typically Sonnet 4.5)

### Subagents (Haiku for Speed)

#### **code-search**
- **Role**: Find code patterns, files, examples
- **Model**: `anthropic/claude-3-5-haiku-20241022`
- **Invocation**: Automatically used by Build agent for searches
- **Permissions**: Read-only (no edits)

#### **test-runner**
- **Role**: Execute tests and report results
- **Model**: `anthropic/claude-3-5-haiku-20241022`
- **Invocation**: Automatically used when running tests
- **Permissions**: Read-only (no edits)

#### **linter**
- **Role**: Run rubocop and brakeman checks
- **Model**: `anthropic/claude-3-5-haiku-20241022`
- **Invocation**: Automatically used before commits
- **Permissions**: Read-only (no edits)

## How It Works

### Automatic Invocation
The Build agent (primary) automatically invokes subagents based on their descriptions:

1. **Code Search**: When you ask to find patterns or examples
2. **Test Runner**: When you ask to run or validate tests
3. **Linter**: When validating code quality or before commits

Example:
```
User: "Find how authentication is handled in controllers"
→ Build agent invokes code-search subagent

User: "Run the tests to make sure this works"
→ Build agent invokes test-runner subagent

User: "Check if this code passes linting"
→ Build agent invokes linter subagent
```

### Cost Optimization
- **Haiku for subagents**: Faster and cheaper for focused tasks
- **Sonnet for building**: Better at complex code changes
- **Opus for planning**: Best at architectural decisions

Typical cost savings: ~60-70% compared to using Sonnet for all tasks

## Instruction Files

### Global Instructions
- `AGENTS.md` - Execution patterns for Build agent (and subagents for context)

### Agent-Specific Instructions
- `PLANNING.md` - Strategic guidance for Plan agent only
- `.opencode/prompts/*.md` - Specialized prompts for each subagent

## Customization

### Adding New Subagents
Edit `opencode.json` to add new specialized agents:

```json
{
  "agent": {
    "my-agent": {
      "mode": "subagent",
      "model": "anthropic/claude-3-5-haiku-20241022",
      "description": "When to use this agent",
      "instructions": ["AGENTS.md"],
      "prompt": ".opencode/prompts/my-agent.md",
      "permission": {
        "edit": "deny",
        "bash": "allow"
      }
    }
  }
}
```

### Modifying Subagent Prompts
Edit the markdown files in `.opencode/prompts/` to customize behavior.

### Changing Models
Edit the `model` field in `opencode.json` for any agent to use a different model.

## Tips

1. **Use Plan mode** for complex features - switch with Tab key
2. **Let subagents work** - they're faster and cheaper for specific tasks
3. **Review PLANNING.md** when adding features to follow patterns
4. **Check AGENTS.md** for execution commands and testing patterns

## Troubleshooting

### Subagent not being invoked
- Check the `description` field is clear about when to use it
- Verify the agent has `"mode": "subagent"` in config

### Permission errors
- Subagents can't edit files by design (permissions: edit=deny)
- Only Build agent should make code changes

### Model not found
- Verify model name matches OpenCode's provider format
- Check API keys are configured: `opencode auth login`
