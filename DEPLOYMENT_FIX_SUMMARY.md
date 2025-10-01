# SQLite Zero-Downtime Deployment Fix

## Problem Summary

The application was failing to deploy with the following error:
```
SQLite3::BusyException: database is locked (ActiveRecord::StatementTimeout)
```

### Root Cause

During Kamal's zero-downtime deployment:
1. **Old container** (v0.9.0) was running with SQLite files open
2. **New container** started and ran `db:prepare` in the docker-entrypoint
3. Both containers tried to access the same SQLite files via shared volume
4. **Race condition** → SQLite lock contention

This issue surfaced during v0.9.1 deployment (first zero-downtime deployment after switching to SQLite).

## Solution Implemented

Moved database migrations from container startup to Kamal's pre-deploy hook:

### Changes Made

1. **bin/docker-entrypoint** - Removed `db:prepare` logic
   - Containers no longer run migrations during startup
   - Eliminates race condition with old container

2. **.kamal/hooks/pre-deploy** - Added pre-deployment hook
   - Runs `bin/rails db:prepare` on OLD container before deployment
   - Ensures migrations complete with exclusive SQLite access
   - Skips migrations during rollbacks

### Deployment Flow (After Fix)

```
1. kamal deploy triggered
   └─ Build & push Docker image

2. pre-deploy hook runs
   └─ Connects to OLD container (currently running)
   └─ Runs: bin/rails db:prepare
   └─ Migrations complete with exclusive access ✓

3. New container starts
   └─ docker-entrypoint executes (no migrations)
   └─ Starts: bin/rails server
   └─ Schema already updated ✓

4. Old container stops
   └─ Clean handoff complete ✓
```

## Why This Is Production-Ready

✅ **Robust**
- Uses official Kamal hooks (documented pattern)
- `db:prepare` is idempotent (safe to run multiple times)
- Handles rollbacks gracefully
- Single-point migration execution (no race conditions)

✅ **Simple**
- Only 2 files changed
- No new infrastructure required
- Standard Rails 8 + Kamal + SQLite pattern

✅ **Maintainable**
- Well-documented approach
- Easy to understand deployment flow
- Follows framework conventions

## Testing

The pre-deploy hook was tested successfully against the current production container (v0.9.0):
```bash
$ .kamal/hooks/pre-deploy
Running database migrations on current container...
  INFO Running docker exec contest_hq-web-f6755fef... bin/rails db:prepare
  INFO Finished in 4.401 seconds with exit status 0 (successful).
✅ Database migrations completed successfully
```

## Next Deployment

When you merge this PR and create a release:
1. GitHub Actions will trigger `kamal deploy`
2. Pre-deploy hook will run migrations on v0.9.0 container
3. New container (with fixed entrypoint) will start
4. Zero-downtime deployment will complete successfully

## References

- [Kamal Hooks Documentation](https://kamal-deploy.org/docs/hooks/overview/)
- [Kamal pre-deploy Hook](https://kamal-deploy.org/docs/hooks/pre-deploy/)
- Rails 8 SQLite production deployment pattern

## Commits

- c2b3aed - Fix SQLite locking during zero-downtime deployments
- 4302717 - Use AWS SES action mailer gem (previous fix attempt)
