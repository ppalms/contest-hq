# Development Setup Guide

This guide will help you set up Contest HQ for local development.

## Prerequisites

- Ruby 3.3.5
- Node.js 18+ and Yarn
- SQLite3
- Git

## Initial Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd contest-hq
```

### 2. Install Dependencies

```bash
# Install Ruby gems
bundle install

# Install JavaScript dependencies
yarn install
```

### 3. Setup Database

```bash
# Create and migrate databases
bin/rails db:setup

# This will:
# - Create development and test databases
# - Run migrations
# - Seed initial data
```

### 4. Start the Development Server

```bash
# Start Rails server, CSS, and JS bundlers
bin/dev
```

The application will be available at http://localhost:3000

## Development Workflow

### Running Tests

```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/user_test.rb

# Run specific test by line number
bin/rails test test/models/user_test.rb:27

# Run system tests
bin/rails test:system
```

### Code Quality

```bash
# Run RuboCop linter
bin/rubocop

# Auto-fix issues
bin/rubocop -a

# Run security scanner
bin/brakeman
```

### Database Operations

```bash
# Create a migration
bin/rails generate migration AddFieldToModel field:type

# Run migrations
bin/rails db:migrate

# Rollback last migration
bin/rails db:rollback

# Reset database (drop, create, migrate, seed)
bin/rails db:reset
```

### Console Access

```bash
# Rails console
bin/rails console

# Database console
bin/rails dbconsole
```

## Project Structure

```
contest-hq/
├── app/
│   ├── controllers/     # Request handlers
│   ├── models/          # ActiveRecord models
│   ├── views/           # ERB templates
│   ├── jobs/            # Background jobs (Solid Queue)
│   ├── services/        # Business logic services
│   └── javascript/      # Stimulus controllers
├── config/
│   ├── deploy.yml       # Kamal deployment config
│   ├── database.yml     # Database configuration
│   └── routes.rb        # Application routes
├── db/
│   ├── migrate/         # Database migrations
│   └── seeds.rb         # Seed data
├── test/
│   ├── controllers/     # Controller tests
│   ├── models/          # Model tests
│   ├── services/        # Service tests
│   └── system/          # System/integration tests
└── docs/                # Documentation
```

## Common Tasks

### Creating a New Feature

1. Create a feature branch:
   ```bash
   git checkout -b feature/my-feature
   ```

2. Generate necessary files:
   ```bash
   # Generate model
   bin/rails generate model MyModel field:type

   # Generate controller
   bin/rails generate controller MyController action1 action2
   ```

3. Write tests first (TDD approach)

4. Implement the feature

5. Run tests and linters:
   ```bash
   bin/rails test
   bin/rubocop
   ```

6. Commit and push:
   ```bash
   git add .
   git commit -m "Add my feature"
   git push origin feature/my-feature
   ```

### Debugging

```ruby
# Add breakpoint in code
debugger

# Or use binding.pry (if pry is installed)
binding.pry
```

Then run your code and interact with the debugger in the terminal.

### Viewing Logs

```bash
# Development log
tail -f log/development.log

# Test log
tail -f log/test.log
```

## Environment Variables

Create a `.env` file in the project root for local development:

```bash
# Example .env file
RAILS_ENV=development
DATABASE_URL=sqlite3:storage/development.sqlite3
```

**Note:** Never commit `.env` files to git. They are in `.gitignore`.

## Troubleshooting

### Database Issues

```bash
# Reset database
bin/rails db:reset

# Check database status
bin/rails db:version
```

### Asset Issues

```bash
# Clear asset cache
bin/rails assets:clobber

# Precompile assets
bin/rails assets:precompile
```

### Dependency Issues

```bash
# Update gems
bundle update

# Update JavaScript packages
yarn upgrade
```

## Getting Help

- Check the [Troubleshooting Guide](TROUBLESHOOTING.md)
- Review existing [GitHub Issues](../../issues)
- Ask in [GitHub Discussions](../../discussions)

## Next Steps

- Read the [Testing Guide](../test/README.md)
- Review [Contributing Guidelines](../CONTRIBUTING.md)
- Explore the [Monitoring Guide](MONITORING.md)
