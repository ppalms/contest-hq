# AGENTS.md - Quick Reference for Coding Agents

## Essential Commands
```bash
bin/rails test                           # Run all unit/integration tests (~36s)
bin/rails test:system                    # Run system tests (~6.5min)
bin/rails test test/models/user_test.rb:27  # Run single test at line 27
bin/rubocop -f github                    # Lint code (required before commit)
bin/brakeman --no-pager                  # Security scan (required)
bin/dev                                  # Start dev server at localhost:3000
```

## Code Style - Rails 8.0.2 with Ruby 3.3.5
- **Linting**: Uses rubocop-rails-omakase configuration (Rails defaults)
- **Classes**: `CamelCase` for models/controllers, `snake_case` for methods/variables
- **Indentation**: 2 spaces, no tabs (enforced by rubocop)
- **Imports**: Use Rails autoloading - avoid explicit requires
- **Helpers**: Use `before_action`, `helper_method`, Rails conventions
- **Models**: Include `AccountScoped` for multi-tenant models
- **Auth**: Use `authenticate` before_action, `current_user` helper
- **Tests**: `sign_in_as(user)` for integration, `set_current_user(user)` for unit
- **Error Handling**: Use Rails rescue_from, redirect_to with flash messages
- **NO COMMENTS**: Do not add code comments unless explicitly requested