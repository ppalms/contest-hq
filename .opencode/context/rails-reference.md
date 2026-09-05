# Rails Reference

## System Architecture
- **Stack**: Rails on Ruby 3.3.5 (exact versions in Gemfile.lock)
- **Database**: SQLite3 with multi-database setup (primary, cache, queue, cable)
- **Storage**: SQLite files in `storage/` directory
- **Multi-tenancy**: Account-based isolation via `AccountScoped` concern
- **Authentication**: Session-based via authentication-zero gem
- **Background Jobs**: Solid Queue (SQLite-backed)
- **Caching**: Solid Cache (SQLite-backed)

## Test Data (FactoryBot)
- **Accounts**: `create(:account, name: "Demo")`
- **Users**: `create(:user, :sys_admin)`, `create(:user, :account_admin, account: @account)`
- **Role traits**: `:sys_admin`, `:account_admin`, `:director`, `:manager`, `:judge`
- **Password**: `TEST_PASSWORD = "Secret1*3*5*"` (defined in test/test_helper.rb)
- Factories default `account` to `Current.effective_account`; pass `account:` explicitly for cross-account data

## Quick Debug Commands
```bash
bin/rails console                        # Interactive Ruby console
bin/rails db:migrate:status              # Check migration status
bin/rails routes | grep contest          # Find contest routes
tail -f log/development.log              # Watch dev logs
```