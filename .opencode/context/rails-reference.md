# Rails Reference

## Fixtures Reference
- **Accounts**: `:demo`, `:customer`, `:ossaa`, `:contesthq`
- **Users**: `:sys_admin_a`, `:demo_admin_a`, `:demo_director_a`, `:demo_manager_a`
- **Roles**: `SysAdmin`, `AccountAdmin`, `Director`, `Manager`, `Judge`
- **Password**: All fixtures use `"Secret1*3*5*"`

## Quick Debug Commands
```bash
bin/rails console                        # Interactive Ruby console
bin/rails db:migrate:status              # Check migration status
bin/rails routes | grep contest          # Find contest routes
tail -f log/development.log              # Watch dev logs
```
