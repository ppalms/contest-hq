# Contest HQ Documentation

Welcome to the Contest HQ documentation. This guide will help you understand, develop, and maintain the application.

## 📚 Documentation Structure

### For Developers
- **[Development Setup](DEVELOPMENT.md)** - Get started with local development
- **[Testing Guide](../test/README.md)** - Running and writing tests
- **[Contributing Guidelines](../CONTRIBUTING.md)** - How to contribute to the project

### For Operations
- **[Monitoring Guide](MONITORING.md)** - Grafana, Prometheus, and metrics
- **[Troubleshooting](TROUBLESHOOTING.md)** - Common issues and solutions
- **[Quick Reference](QUICK-REFERENCE.md)** - Common commands and procedures

## 🔒 Private Documentation

Sensitive infrastructure and disaster recovery documentation is maintained separately in 1Password Secure Notes:

- **Disaster Recovery (Complete)** - Full step-by-step recovery guide
- **Disaster Recovery (Quick Start)** - Emergency quick reference
- **Server Architecture** - Infrastructure topology and specifications
- **Deployment Guide** - Production deployment procedures

**Access:** Contact the repository owner for 1Password vault access.

## 🏗️ Architecture Overview

Contest HQ is a Rails 8.1 application deployed using Kamal to a cloud server. Key components:

- **Application:** Rails 8.1 with Hotwire (Turbo + Stimulus)
- **Database:** SQLite3 (multi-database: primary, cache, queue, cable)
- **Background Jobs:** Solid Queue (SQLite-backed)
- **Caching:** Solid Cache (SQLite-backed)
- **Deployment:** Kamal 2.x
- **Monitoring:** Prometheus + Grafana (Kamal accessories)
- **Metrics:** Yabeda (Rails + Puma metrics)

## 🚀 Quick Start

### Local Development

```bash
# Clone the repository
git clone <repository-url>
cd contest-hq

# Install dependencies
bundle install

# Setup database
bin/rails db:setup

# Start the server
bin/dev
```

Visit http://localhost:3000

### Running Tests

```bash
# Run all tests
bin/rails test

# Run system tests
bin/rails test:system

# Run specific test
bin/rails test test/models/user_test.rb
```

## 📊 Monitoring

Production monitoring is available at:
- **Grafana:** https://metrics.contesthq.app
- **Metrics Endpoint:** `/metrics` (internal only)

See [MONITORING.md](MONITORING.md) for setup and usage details.

## 🆘 Getting Help

- **Issues:** Check existing issues or create a new one
- **Discussions:** Use GitHub Discussions for questions
- **Emergency:** Refer to disaster recovery docs in 1Password

## 📝 License

[Your License Here]
