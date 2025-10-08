# PLANNING.md - Strategic Planning Guide

**For: Claude Opus 4.1 (planning mode)**

## Your Role
Make architectural decisions and create execution plans. Don't write implementation code.

## System Context
- **Rails 8.0.2** with Ruby 3.3.5 (strict requirement)
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

## Handoff Template

```markdown
## PLAN: [Feature Name]

**Goal**: [1 sentence what and why]

**Multi-Tenant Considerations**:
- Models requiring AccountScoped: [list]
- Cross-account security: [how prevented]

**Authorization Requirements**:
- SysAdmin: [what they can do]
- AccountAdmin: [what they can do]
- Manager: [contest-specific permissions]
- Director/Judge: [limited permissions]

**Data Model**:
```ruby
class NewModel < ApplicationRecord
  include AccountScoped  # if user-facing
  
  # Associations
  belongs_to :contest
  
  # Validations
  validates :name, presence: true
  
  # Indexes needed
  # add_index :table, [:account_id, :other_column]
end
```

**Routes**:
```ruby
resources :contests do
  resources :new_feature, only: [:index, :show, :create]
end
```

**Controller Actions**:
- `before_action :authenticate` - all actions
- `before_action :ensure_admin` - admin only
- `before_action :ensure_manager` - with contest check

**Tests Required**:
1. **Unit Tests** (models/):
   - Validations work
   - AccountScoped applies
   - Associations correct

2. **Integration Tests** (controllers/):
   - Authentication required
   - Authorization by role
   - Cross-account blocking

3. **System Tests** (if UI flow):
   - Complete user journey
   - Error handling

**Manual Validation Steps**:
1. As Director: [expected behavior]
2. As Manager: [can only manage assigned contests]
3. As SysAdmin: [can switch accounts and see everything]
4. Cross-account: [verify data isolation]

**Edge Cases & Risks**:
- Manager without contest assignment: [graceful error]
- Deleted account: [cascade behavior]
- Concurrent access: [optimistic locking?]
```

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

## Example: Good vs Bad Planning

### ❌ Bad Plan
"Add judge scoring - create Rating model with scores"

### ✅ Good Plan
"Add judge scoring for contest entries:

**Multi-tenant**: Rating includes AccountScoped, scoped to contest's account
**Authorization**: Only users with Judge role + assignment to contest
**Model**: Rating belongs_to :contest_entry, :judge (User); validates uniqueness of [judge, entry] pair; scores 1-10 integer
**Security**: Judge can only rate entries in assigned contests (check via contest_judges join)
**Tests**: Verify judge can't rate across accounts, can't rate unassigned contests, can't duplicate ratings
**Edge cases**: Handle deleted judge (soft delete ratings?), contest cancellation (preserve ratings for audit)"
```
