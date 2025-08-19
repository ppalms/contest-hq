# Copilot Instructions for Contest HQ

## Repository Overview

Contest HQ is a Ruby on Rails application for managing band and orchestra contests. The application handles contest scheduling, participant management, scoring, and contest administration.

**Tech Stack:**
- Ruby 3.3.5 (strict requirement)
- Rails 8.0.2
- PostgreSQL database
- Tailwind CSS for styling
- Docker for database and deployment
- Authentication via authentication-zero gem
- Background jobs with Solid Queue
- Caching with Solid Cache
- File storage via AWS S3 (production)
- Email via AWS SES (production)

**Repository Size:** ~150 files, standard Rails MVC structure with modern Rails 8 conventions. Contains 41 test files covering models, controllers, and system tests.

## Critical Setup Requirements

### Ruby Version Management
**ALWAYS ensure Ruby 3.3.5** - the Gemfile has a strict Ruby version requirement. Any version mismatch will prevent `bundle install` from succeeding.

- Check Ruby version: `ruby --version`
- The repository includes `.mise.toml` with Ruby 3.3.5 specification
- If mise is available: `mise install` will install the correct Ruby version
- Alternative: Use rbenv, rvm, or asdf to install Ruby 3.3.5

### Environment Setup Sequence

**Prerequisites:**
1. Ruby 3.3.5 installed and active
2. Docker and Docker Compose available
3. Git repository cloned

**Complete Setup (recommended order):**
```bash
# 1. Install dependencies
bundle install
# NEVER CANCEL: Takes ~40 seconds to complete. Set timeout to 120+ seconds.

# 2. Start database (required before db commands)
docker compose up -d db --wait
# NEVER CANCEL: Takes ~6 seconds with --wait. Set timeout to 60+ seconds.

# 3. Run full setup script
bin/setup
# NEVER CANCEL: Takes ~10 seconds total. Set timeout to 60+ seconds.
```

**Alternative Manual Setup:**
```bash
# If bin/setup fails, run these steps manually:
bundle install
POSTGRES_USER=dev_user POSTGRES_PASSWORD=dev_password POSTGRES_DB=contest_hq_development docker compose up -d db --wait
bin/rails db:prepare
bin/rails log:clear tmp:clear
```

### Common Setup Issues & Solutions

**Ruby Version Mismatch:**
- Error: "Your Ruby version is X.X.X, but your Gemfile specified 3.3.5"
- Solution: Install and activate Ruby 3.3.5 using a version manager

**Bundler Version Mismatch:**
- Error: "Bundler X.X.X is running, but your lockfile was generated with X.X.X"
- Solution: `gem install bundler -v '2.5.22'` (or use bin/bundle script)

**SSL Certificate Errors (Docker builds):**
- Error: "Could not verify the SSL certificate for https://rubygems.org/"
- Solution: This is a known Docker environment issue - may require certificate updates or alternative gem source

**Database Connection Errors:**
- Ensure PostgreSQL Docker container is running: `docker compose ps`
- Check environment variables: POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB
- Restart database: `docker compose restart db`

## Build, Test, and Validation Commands

### Development Server
```bash
# Start development server with Tailwind CSS watcher
bin/dev
# Runs on http://localhost:3000
# Includes: rails server + tailwindcss:watch
# NEVER CANCEL: Takes ~2 seconds to start, wait for "Listening on" message
```

### Testing Commands
```bash
# Run all tests (unit + integration)
bin/rails test
# NEVER CANCEL: Takes ~36 seconds to complete. Set timeout to 120+ seconds.

# Run system tests (end-to-end with browser)
bin/rails test:system
# NEVER CANCEL: Takes ~6.5 minutes to complete. Set timeout to 600+ seconds.

# Prepare test database
bin/rails db:test:prepare
# Takes ~1.5 seconds

# Full CI-like test run
bin/rails db:test:prepare test test:system
# NEVER CANCEL: Takes ~7 minutes total. Set timeout to 900+ seconds.
```

**Test Environment Notes:**
- **Test Suite:** 41 test files covering models, controllers, and system tests
- **Authentication:** Tests use `sign_in_as(user)` for integration tests and `set_current_user(user)` for unit tests
- **Fixtures:** All fixtures loaded automatically; test password is "Secret1*3*5*"
- **Parallel Testing:** Uses `:number_of_processors` workers for speed
- **System Tests:** Use Capybara with headless Chrome (1400x1400 screen size)
- **Failed Screenshots:** System test failures save screenshots to `tmp/screenshots`
- **Database Requirement:** Tests require PostgreSQL running (use Docker)
- **CI Environment:** Sets `DATABASE_URL=postgres://postgres:postgres@localhost:5432`

### Linting and Security Scanning
```bash
# Code style linting (uses rails-omakase configuration)
bin/rubocop -f github
# Takes ~3 seconds

# Security vulnerability scanning for Ruby
bin/brakeman --no-pager
# Takes ~5 seconds

# JavaScript dependency security audit
bin/importmap audit
# Takes ~0.6 seconds
```

### Database Operations
```bash
# Create and migrate database
bin/rails db:prepare
# Takes ~1.5 seconds

# Reset database (danger: destroys data)
bin/rails db:reset
# Takes ~2-3 seconds

# Run migrations only
bin/rails db:migrate
# Takes ~1 second for typical migrations

# Seed database
bin/rails db:seed
# Time varies based on seed data size
```

### Production Commands
```bash
# Precompile assets for production
RAILS_ENV=production bundle exec bin/rails assets:precompile
# NEVER CANCEL: Takes ~1.2 seconds. Requires SECRET_KEY_BASE_DUMMY=1 for testing.

# Run production server
bin/rails s -e production
# Requires proper credentials setup in production

# View production logs (requires kamal setup)
kamal app logs -g <request ID>
```

## Project Architecture and Layout

### Directory Structure
```
app/
├── controllers/     # MVC controllers, including nested contest management
├── models/         # ActiveRecord models with user/contest associations  
├── views/          # ERB templates with Tailwind CSS classes
├── helpers/        # View helpers
├── jobs/           # Background jobs (Solid Queue)
├── mailers/        # Email templates
├── services/       # Business logic services
└── javascript/     # Stimulus controllers and importmap assets

config/
├── application.rb   # Rails application configuration
├── database.yml    # PostgreSQL configuration with environment variables
├── routes.rb       # URL routing (includes schedule_summary route)
├── deploy.yml      # Kamal deployment configuration
└── environments/   # Environment-specific configurations

test/
├── controllers/    # Controller tests
├── models/         # Model tests  
├── system/         # System tests with Capybara
├── fixtures/       # Test data fixtures
└── test_helper.rb  # Test configuration

bin/
├── setup          # Comprehensive development setup script
├── dev            # Development server with Foreman
├── rubocop        # Linting command
├── brakeman       # Security scanning
└── rails          # Rails CLI
```

### Key Configuration Files
- **Database:** `config/database.yml` - uses environment variables for connection
- **Linting:** `.rubocop.yml` - inherits from rubocop-rails-omakase
- **Styling:** Uses Tailwind CSS via tailwindcss-rails gem
- **Background Jobs:** `config/queue.yml` - Solid Queue configuration
- **Caching:** `config/cache.yml` - Solid Cache configuration
- **Deployment:** `config/deploy.yml` - Kamal configuration for DigitalOcean

### GitHub Actions CI Pipeline
The repository includes a comprehensive CI pipeline (`.github/workflows/ci.yml`) with four jobs:

1. **scan_ruby:** Runs `bin/brakeman --no-pager` for security scanning
2. **scan_js:** Runs `bin/importmap audit` for JavaScript dependency security
3. **lint:** Runs `bin/rubocop -f github` for code style checking
4. **test:** Runs full test suite with PostgreSQL service

**CI Requirements:**
- PostgreSQL service must be running
- Environment variables: `RAILS_ENV=test`, `CI=true`, `DATABASE_URL`
- System dependencies: `google-chrome-stable`, `libjemalloc2`, `libvips`, `postgresql-client`

### Known Issues and TODOs
The codebase contains several TODO comments indicating areas under development:
- User/contest association improvements needed in multiple controllers
- Schedule controller has TODO items around time handling and user scoping
- One system test marked as "TODO: fix"
- Schedule summary route needs to be moved to schedules folder

### Dependencies and Integrations
**Authentication:** Uses authentication-zero gem - provides user registration, login, password reset
**Pagination:** Uses pagy gem for efficient pagination
**File Storage:** AWS S3 integration via Active Storage (production)
**Email:** AWS SES integration via Action Mailer (production)
**Deployment:** Kamal for containerized deployment to DigitalOcean
**Database:** PostgreSQL with multi-database configuration (main, cache, queue, cable)
**Credentials:** Uses Rails encrypted credentials (`config/credentials.yml.enc` and `config/credentials/production.yml.enc`)
**Secrets:** Kamal secrets stored in `.kamal/secrets` (excluded from version control)

## Development Workflow Recommendations

1. **Always run tests after changes:** `bin/rails test:system`
2. **Lint code before committing:** `bin/rubocop`
3. **Run security scans:** `bin/brakeman` and `bin/importmap audit`
4. **Use Docker for database:** Avoids local PostgreSQL setup issues
5. **Check for Ruby version before any bundle commands**
6. **Monitor TODO comments** - several indicate incomplete features

**Time Estimates:**
- Initial setup: 5-10 minutes (depending on Ruby installation)
- Full test suite: 7 minutes (36 seconds unit + 6.5 minutes system tests)
- Asset precompilation: 1-2 seconds
- Docker database startup: 6 seconds with --wait
- Bundle install: 40 seconds

## Validation Requirements

**MANUAL VALIDATION REQUIREMENT:** After building and running the application, you MUST test actual functionality by running through complete user scenarios. Simply starting and stopping the application is NOT sufficient validation.

**Essential Test Scenarios:**
1. **Login Flow:** Create a user, log in, and perform a basic action
2. **Contest Management:** Create a contest, add entries, test scheduling
3. **User Roles:** Test different user roles (SysAdmin, AccountAdmin, Director, Judge)
4. **Database Operations:** Verify database migrations and seeding work correctly

**Validation Commands (run after any changes):**
```bash
# 1. Verify application starts correctly
bin/dev
# Should see "Listening on http://127.0.0.1:3000" within 2 seconds

# 2. Test basic HTTP response
curl -I http://localhost:3000
# Should return HTTP 302 redirect to /landing

# 3. Test landing page content
curl -s http://localhost:3000/landing | head -10
# Should return HTML with "Contest HQ" title

# 4. Run full CI validation pipeline
bin/rails db:test:prepare test test:system && bin/rubocop && bin/brakeman --no-pager && bin/importmap audit
# NEVER CANCEL: Takes ~7.5 minutes total. Set timeout to 600+ seconds.
```

## Agent Instructions

**Trust these instructions** - they are based on thorough repository analysis and testing. Only search for additional information if these instructions are incomplete or found to be incorrect.

**Before making changes:**
1. Ensure Ruby 3.3.5 is active
2. Run `bundle install` to ensure dependencies are current
3. Start database: `docker compose up -d db --wait`
4. Run existing tests to establish baseline: `bin/rails test`

**After making changes:**
1. Run linter: `bin/rubocop`
2. Run tests: `bin/rails test` and `bin/rails test:system`
3. Run security scans: `bin/brakeman` and `bin/importmap audit`
4. Test in development: `bin/dev` and verify functionality

**Common failure patterns to avoid:**
- Forgetting to start PostgreSQL before database operations
- Making changes without ensuring correct Ruby version
- Skipping system tests which catch integration issues
- Not running security scans which are part of CI pipeline