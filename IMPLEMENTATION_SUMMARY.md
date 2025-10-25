# School Class Restriction Implementation Summary

## Problem Statement
Directors could register for contests with ensembles from schools whose class didn't match the contest restrictions. For example, a director from Kennedy High School (1A) could register for "2A, 3A State Orchestra" which should only allow 2A and 3A schools.

## Solution Architecture

### 1. Model Layer (Defense in Depth - Backend)
**File:** `app/models/contest_entry.rb`

```ruby
validate :school_class_eligible_for_contest

def school_class_eligible_for_contest
  return unless large_ensemble && contest
  return if contest.school_classes.empty?  # No restrictions = all allowed

  school_class = large_ensemble.school.school_class
  unless contest.school_classes.include?(school_class)
    errors.add(:large_ensemble, "is from a #{school_class.name} school, 
                but this contest is restricted to #{contest.school_classes.pluck(:name).join(', ')} schools")
  end
end
```

**Why:** Provides backend validation that cannot be bypassed even if someone tries to submit directly via API or console.

### 2. Controller Layer (User Experience)
**File:** `app/controllers/contest_entries_controller.rb`

#### New Helper Method:
```ruby
def eligible_ensembles_for_contest(ensembles, contest)
  return ensembles if contest.school_classes.empty?  # No restrictions
  
  eligible_school_class_ids = contest.school_classes.pluck(:id)
  ensembles.joins(school: :school_class)
    .where(schools: { school_class_id: eligible_school_class_ids })
end
```

#### Updated `new` Action:
```ruby
def new
  # ... existing code ...
  
  @eligible_ensembles = eligible_ensembles_for_contest(current_user.conducted_ensembles, @contest)
  
  if @eligible_ensembles.empty?
    redirect_to @contest, 
      alert: "None of your ensembles are eligible for this contest. 
              This contest is restricted to #{@contest.school_classes.pluck(:name).join(', ')} schools."
    return
  end
  
  # ... rest of code ...
end
```

**Why:** Prevents users from even seeing ineligible ensembles, providing clear feedback immediately.

### 3. View Layer (UI Updates)
**File:** `app/views/contest_entries/_form.html.erb`

**Before:**
```erb
<%= form.select :large_ensemble_id,
            current_user.conducted_ensembles.all.map { |t| [t.name, t.id] },
            ... %>
```

**After:**
```erb
<%= form.select :large_ensemble_id,
            @eligible_ensembles.map { |t| [t.name, t.id] },
            ... %>
```

**Why:** Only shows ensembles that are actually eligible for the contest.

## Data Flow

```
User clicks "Register" on Contest
         ↓
Controller checks if user has ANY ensembles
         ↓
Controller filters ensembles by school class eligibility
         ↓
    ┌────────────────────┐
    │ Any eligible?      │
    └────────────────────┘
         ↓           ↓
        NO          YES
         ↓           ↓
    Redirect    Show Form
    with alert  with only eligible
                ensembles
                     ↓
                User submits
                     ↓
              Model validates
                     ↓
              ┌──────────────┐
              │ School class │
              │  matches?    │
              └──────────────┘
                  ↓      ↓
                YES     NO
                  ↓      ↓
               Save   Show error
```

## Test Coverage

### Model Tests (3 tests)
1. **Ineligible School:** Validates that 1A ensemble fails for 2A/3A contest
2. **Eligible School:** Validates that 2A ensemble succeeds for 2A/3A contest  
3. **No Restrictions:** Validates that any school works for unrestricted contest

### Controller Tests (2 tests)
1. **Redirect on No Eligible:** Ensures user is redirected with helpful message
2. **Show Form on Eligible:** Ensures form displays when user has eligible ensembles

## Database Schema Context

```
Contest
  ├─ has_many :contests_school_classes
  └─ has_many :school_classes, through: :contests_school_classes

LargeEnsemble
  ├─ belongs_to :school
  └─ school.belongs_to :school_class

ContestEntry
  ├─ belongs_to :contest
  └─ belongs_to :large_ensemble
```

The validation checks:
```ruby
contest.school_classes.include?(large_ensemble.school.school_class)
```

## User Experience Examples

### Scenario 1: Ineligible User
```
User: fred@demo.org (Kennedy High School - 1A)
Contest: "2A, 3A State Orchestra" (restricted to 2A, 3A)
Result: Redirected with message:
  "None of your ensembles are eligible for this contest. 
   This contest is restricted to 2-A, 3-A schools."
```

### Scenario 2: Eligible User
```
User: angua@demo.org (Washington High School - 2A)
Contest: "2A, 3A State Orchestra" (restricted to 2A, 3A)
Result: Form displays with dropdown showing only 2A/3A ensembles
```

### Scenario 3: Unrestricted Contest
```
User: fred@demo.org (Kennedy High School - 1A)
Contest: "District Orchestra" (no restrictions)
Result: Form displays with all user's ensembles
```

## Files Changed

1. **app/models/contest_entry.rb**
   - Added `school_class_eligible_for_contest` validation

2. **app/controllers/contest_entries_controller.rb**
   - Added `eligible_ensembles_for_contest` helper
   - Updated `new` action to filter and redirect
   - Updated `create` action to set `@eligible_ensembles` on error

3. **app/views/contest_entries/_form.html.erb**
   - Changed to use `@eligible_ensembles` instead of all ensembles

4. **test/models/contest_entry_test.rb**
   - Added 3 test cases for validation

5. **test/controllers/contest_entries_controller_test.rb**
   - Added 2 test cases for filtering

6. **test/fixtures/large_ensembles.yml**
   - Added demo_school_b_ensemble_a

7. **test/fixtures/large_ensemble_conductors.yml**
   - Added conductor association for demo_school_b_ensemble_a

## Edge Cases Handled

1. ✅ **No Contest Restrictions:** All ensembles allowed
2. ✅ **Empty Eligible List:** Clear redirect with helpful message
3. ✅ **Multiple Eligible Ensembles:** All shown in dropdown
4. ✅ **Form Re-rendering:** On validation error, eligible ensembles still available
5. ✅ **API/Direct Submission:** Backend validation catches bypass attempts
6. ✅ **Existing Duplicate Check:** Still works alongside new validation

## Security Considerations

- **Defense in Depth:** Both controller filtering AND model validation
- **No Bypass:** Backend validation ensures API calls are also validated
- **Clear Feedback:** Users understand why they can't register
- **Data Integrity:** Ensures contest_entries table only contains valid combinations
