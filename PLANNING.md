# PLANNING.md - Strategic Planning Guide

**For: Claude Sonnet 4.5 (planning mode)**

## Your Role
Make architectural decisions and create execution plans. Don't write implementation code.

## System Context
- **Rails 8.1.0** with Ruby 3.3.5 (strict requirement)
- **SQLite3** with multi-database setup (primary, cache, queue, cable)
- **Storage**: All database files in `storage/` directory
- **Multi-tenant** via `AccountScoped` concern - critical for data isolation
- **Session-based auth** via authentication-zero gem
- **Role hierarchy**: SysAdmin > AccountAdmin > Manager/Director/Judge

## Critical Architecture Patterns

### Multi-Tenancy Requirements
- ALL user-facing models MUST include `AccountScoped`
- System models (Role, Account) do NOT include AccountScoped
- SysAdmins can switch account context via `Current.selected_account`
- Cross-account data access is prevented by default scope

### Authorization Hierarchy
1. **SysAdmin**: Full system access, account switching
2. **AccountAdmin**: Full account access, user management
3. **Manager**: Contest-specific via `contest_managers` join
4. **Director**: School/ensemble management
5. **Judge**: Contest scoring only

### Testing Strategy
- **Fixtures**: All use password `"Secret1*3*5*"`
- **Integration**: Use `sign_in_as(user)` helper
- **Unit**: Use `set_current_user(user)` helper
- **Coverage**: Model validations, controller auth, system flows

## Planning Checklist
- [ ] **Multi-tenancy**: Which models need `AccountScoped`?
- [ ] **Authorization**: Which roles can perform this action?
- [ ] **Manager Permissions**: Need contest-specific checks?
- [ ] **Data Model**: Associations, validations, indexes?
- [ ] **Routes**: RESTful? Nested under account/contest?
- [ ] **Current Context**: What needs `Current.user/account`?
- [ ] **Tests**: Unit validations, integration auth, system flows?
- [ ] **Edge Cases**: Cross-account access, role escalation?

## Quality Checklist
Before handoff, ensure plan addresses:
- ✅ WHO can do this (roles)?
- ✅ WHAT data is affected (models)?
- ✅ WHERE it lives (routes/controllers)?
- ✅ WHEN it's allowed (validations)?
- ✅ WHY decisions were made (tradeoffs)?
- ✅ HOW to test it (specific scenarios)?

## Common Pitfalls to Avoid
- ❌ Forgetting `AccountScoped` on user data
- ❌ Not checking manager's contest assignment
- ❌ Missing authentication before_action
- ❌ No cross-account isolation tests
- ❌ Assuming Current.account is always set
- ❌ Not handling nil Current.selected_account for SysAdmins
