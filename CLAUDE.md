# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Essential Commands

### Setup and Development
```bash
# Initial setup - run Ruby 3.3.5 first!
bin/setup

# Start development server with Tailwind CSS watcher
bin/dev
# Runs on http://localhost:3000
```

### Testing
```bash
# Run all tests (unit + integration)
bin/rails test

# Run system tests (end-to-end browser tests)
bin/rails test:system

# Prepare test database
bin/rails db:test:prepare

# Full CI-like test run
bin/rails db:test:prepare test test:system
```

### Linting and Security
```bash
# Code style linting
bin/rubocop -f github

# Security vulnerability scanning
bin/brakeman --no-pager

# JavaScript dependency audit
bin/importmap audit
```

### Database Operations
```bash
# Create and migrate database
bin/rails db:prepare

# Reset database (destroys data)
bin/rails db:reset

# Run migrations only
bin/rails db:migrate

# Seed database
bin/rails db:seed
```

### Production Commands
```bash
# Precompile assets
RAILS_ENV=production bundle exec bin/rails assets:precompile

# Production server
bin/rails s -e production

# View production logs (requires kamal)
kamal app logs -g <request_id>
```

## Project Architecture

### Core Technology Stack
- **Ruby 3.3.5** (strict requirement - check with `ruby --version`)
- **Rails 8.0.2** with modern conventions
- **SQLite3** embedded database
- **Tailwind CSS** for styling
- **Authentication-zero** gem for user auth
- **Solid Queue** for background jobs
- **Solid Cache** for caching
- **Solid Cable** for Action Cable
- **Pagy** for pagination
- **Kamal** for deployment

### Application Structure
This is a multi-tenant contest management system with the following key domain models:

- **Account/User System**: Multi-tenant architecture with account switching for sysadmins
- **Contest Management**: Contests, entries, music selections, performance phases
- **Organization Hierarchy**: Schools → School Classes → Large Ensembles
- **Scheduling System**: Schedule days, blocks, rooms for contest timing
- **Role-Based Access**: SysAdmin, AccountAdmin, Director, Judge roles

### Key Model Relationships
```
Account (tenant) → Users → User Roles
Contest → Contest Entries → Music Selections
School → School Classes → Large Ensembles → Contest Entries
Contest → Performance Phases → Schedules → Schedule Blocks
```

### Authentication & Authorization
- Uses authentication-zero gem with session-based auth
- Multi-tenant with account switching capability for sysadmins
- Role-based permissions (SysAdmin, AccountAdmin, Director, Judge)
- Test helpers: `sign_in_as(user)` for integration, `set_current_user(user)` for unit tests

### Key Configuration Files
- **Database**: `config/database.yml` - SQLite3 with multi-database configuration
- **Routes**: Nested resources for contests → entries → selections
- **Deployment**: `config/deploy.yml` - Kamal configuration for DigitalOcean
- **Background Jobs**: `config/queue.yml` - Solid Queue configuration
- **Caching**: `config/cache.yml` - Solid Cache configuration

### Directory Structure Highlights
```
app/controllers/
├── contests/           # Nested contest management
│   ├── managers_controller.rb
│   ├── performance_phases_controller.rb
│   └── rooms_controller.rb
├── identity/           # Authentication controllers
├── organizations/      # School/class management
└── [other controllers]

app/models/
├── contest.rb          # Main contest model
├── contest_entry.rb    # Individual contest entries
├── user.rb            # User with account associations
├── account.rb          # Multi-tenant account model
└── [other models]
```

## Critical Requirements

### Ruby Version Management
**ALWAYS ensure Ruby 3.3.5** - Gemfile has strict version requirement.
- Check: `ruby --version`
- Install via mise: `mise install` (uses `.mise.toml`)
- Or use rbenv/rvm/asdf to install Ruby 3.3.5

### Database Requirements
- SQLite3 databases are stored in the `storage/` directory
- No external database server required
- Multi-database setup for primary, cache, queue, and cable databases

### Testing Environment
- **41 test files** covering models, controllers, system tests
- System tests use headless Chrome (1400x1400 screen)
- Test password for fixtures: "Secret1*3*5*"
- Failed screenshots saved to `tmp/screenshots`
- SQLite test database automatically created

### Time Estimates
- Initial setup: 2-5 minutes (no Docker required)
- Bundle install: ~40 seconds
- Full test suite: ~7 minutes (36s unit + 6.5min system)
- Development server start: ~2 seconds

## Development Workflow

### Before Making Changes
1. Ensure Ruby 3.3.5: `ruby --version`
2. Install dependencies: `bundle install`
3. Run baseline tests: `bin/rails test`

### After Making Changes
1. **Always run linting**: `bin/rubocop`
2. **Always run tests**: `bin/rails test` and `bin/rails test:system`
3. **Always run security scans**: `bin/brakeman` and `bin/importmap audit`
4. Test in development: `bin/dev` and verify functionality

### Validation Requirements
**MANUAL VALIDATION REQUIRED**: Test actual functionality, not just startup.

Essential scenarios:
1. **Login Flow**: Create user, log in, perform actions
2. **Contest Management**: Create contest, add entries, test scheduling
3. **User Roles**: Test different role permissions
4. **Database Operations**: Verify migrations and seeding

## Known Issues and TODOs
The codebase contains several TODO comments indicating areas under development:
- User/contest association improvements needed in multiple controllers
- Schedule controller has TODO items around time handling and user scoping
- Schedule summary route needs to be moved to schedules folder
- One system test marked as "TODO: fix"

## CI Pipeline
GitHub Actions runs 4 jobs:
1. **scan_ruby**: `bin/brakeman --no-pager`
2. **scan_js**: `bin/importmap audit`
3. **lint**: `bin/rubocop -f github`
4. **test**: Full test suite with SQLite (no external services required)

## Deployment
- Uses Kamal for containerized deployment to DigitalOcean
- SQLite databases stored in persistent Docker volumes
- AWS S3 for file storage (production)
- AWS SES for email (production)
- Encrypted credentials in `config/credentials/`
- Kamal secrets in `.kamal/secrets` (excluded from git)