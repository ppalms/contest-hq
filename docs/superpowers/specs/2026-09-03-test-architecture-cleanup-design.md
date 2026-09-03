# Test Architecture Cleanup

## Problem

The test suite has accumulated fragility that blocks feature development:

1. **Three inconsistent auth helpers** (`sign_in_as`, `set_current_user`, `log_in_as`) that each handle `Current.account` differently
2. **`Current.account` is thread-local** — system tests need manual `Current.account =` in every setup block because `log_in_as` only sets it server-side
3. **No factories** — 18 YAML fixture files with 124 hand-authored records, requiring manual cross-account data management
4. **Hardcoded `"Secret1*3*5*"` password** in 15+ files
5. **Massive setup boilerplate** — Room/PerformancePhase creation repeated ~15 times
6. **Dead code** — unused `flaky_test` method, empty `integration/` and `helpers/` directories

## Goals

- Adding a new `AccountScoped` model should be routine: create factory, write tests, done
- System tests should never manually set `Current.account` — auth helpers handle it
- One password constant, not 15+ hardcoded strings
- Delete all fixture YAML files

## Approach: Bottom-Up Migration

Incremental migration, file-by-file, from foundation (factories + helpers) outward.

---

## Phase 1: Foundation (no existing test changes)

### 1a. Install FactoryBot

Add to Gemfile `:test` group. Create `test/factories/` directory.

### 1b. Add `TEST_PASSWORD` constant

In `test/test_helper.rb`:
```ruby
TEST_PASSWORD = "Secret1*3*5*"
```
Reference it everywhere instead of the hardcoded string.

### 1c. Create factories

24 factory files in `test/factories/`. Key design decisions:

- **Auto-set account:** Every AccountScoped factory defaults `account { Current.effective_account }`. Cross-account tests pass explicit `account:`.
- **Role traits on User factory:** `:sys_admin`, `:account_admin`, `:director`, `:manager`, `:judge` traits create the role assignment in `after(:create)`.
- **Dependent creation:** `ContestManager` factory ensures user has Manager role. `ContestEntry` factory links contest to school_classes. `MusicSelection` factory creates matching prescribed_music.
- **LargeEnsemble callback:** `after(:create)` callback calls `Current.user` — factory sets `Current.user` before create.

Factory dependency graph:
```
Account
  -> Season, SchoolClass, PerformanceClass, User (+ Role via trait)
    -> School, Session, PrescribedMusic
      -> Contest, LargeEnsemble
        -> Room, PerformancePhase, Schedule, SchoolDirector, ContestManager
          -> ContestEntry, ScheduleDay
            -> MusicSelection, ScheduleBlock
```

### 1d. Update auth helpers

`set_current_user` (model tests) — already sets `Current.account`, no change needed.

`sign_in_as` (integration/controller tests) — add `Current.account = user.account` after the HTTP POST + session assignment.

`log_in_as` (system tests) — add `Current.account = user.account` after the browser flow completes, so the test thread has the correct context.

### 1e. Remove dead code

- Delete `self.flaky_test` from `application_system_test_case.rb`
- Delete empty `test/integration/.keep` and `test/helpers/.keep`

---

## Phase 2: Migrate model tests

10 files in `test/models/`. Replace fixture references with factories. Delete fixture records as they become unused.

Priority order (fastest first):
1. `account_scoped_test.rb` — core behavior, must be correct
2. `current_test.rb` — Current attributes
3. `user_test.rb` — most factory usage
4. `season_test.rb`, `school_class_test.rb` — simple models
5. `contest_test.rb`, `large_ensemble_test.rb` — complex validations
6. `music_selection_test.rb`, `schedule_test.rb`, `prescribed_music_test.rb` — deep dependency chains

---

## Phase 3: Migrate controller tests

16 files in `test/controllers/`. These already use `sign_in_as` — mostly factory adoption.

Key changes:
- Replace `fixtures(:users, :demo_admin_a)` with `create(:user, :account_admin, account: demo_account)`
- Replace `Current.account = accounts(:demo)` in setup blocks with factory-provided account context
- Tests that access cross-account data use `Model.unscoped` (already do) plus explicit factory creation

---

## Phase 4: Migrate system tests

20 files in `test/system/`. Hardest phase.

Key changes:
- **Remove all manual `Current.account =` lines** from setup blocks — `log_in_as` now handles it
- Replace fixture references with factories
- Replace `set_current_user(@user)` + manual record creation with factory calls
- `ScheduleTestHelper` methods updated to use factories

Example migration:
```ruby
# BEFORE
setup do
  @manager = users(:demo_manager_a)
  @contest = contests(:demo_contest_a)
  Current.account = @contest.account
  @schedule = @contest.schedules.first
  log_in_as(@manager)
  @entry1 = contest_entries(:contest_a_school_a_ensemble_a)
end

# AFTER
setup do
  @account = create(:account, name: "Demo")
  @contest = create(:contest, account: @account)
  @schedule = create(:schedule, contest: @contest, account: @account)
  @manager = create(:user, :manager, account: @account)
  @entry1 = create(:contest_entry, contest: @contest, user: @manager, account: @account)
  log_in_as(@manager)
end
```

---

## Phase 5: Cleanup

- Delete all 18 fixture YAML files
- Remove `fixtures :all` from `test_helper.rb`
- Delete `test/fixtures/` directory
- Verify `bin/rails test` passes with 0 failures
- Verify `bin/rails test:system` passes
- Update `AGENTS.md` if fixture references remain

---

## Files Touched

| Phase | Files Modified | Files Created | Files Deleted |
|-------|---------------|---------------|---------------|
| 1 | `Gemfile`, `test_helper.rb`, `application_system_test_case.rb` | 24 factory files, `TEST_PASSWORD` | 2 `.keep` files, `flaky_test` |
| 2 | 10 model test files | — | Fixture records (incremental) |
| 3 | 16 controller test files | — | Fixture records (incremental) |
| 4 | 20 system test files | — | Fixture records (incremental) |
| 5 | `test_helper.rb` | — | 18 fixture YAML files, `test/fixtures/` dir |

## Verification

After each phase:
1. `bin/rails test` — unit/integration/controller tests
2. `bin/rails test:system` — system tests (after phase 4)
3. `bin/rubocop -f github` — lint
4. `bin/brakeman --no-pager` — security scan
