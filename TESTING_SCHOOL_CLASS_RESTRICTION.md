# Testing Guide: School Class Restriction for Contest Entries

## Overview
This guide outlines how to manually test the school class restriction feature that prevents directors from registering ensembles from ineligible schools for a contest.

## Test Scenario from Issue

**Issue Description:** Director can register for a contest that is restricted to 2A and 3A with a large ensemble from a 1A school.

**Expected Behavior:** Directors should NOT be able to select or register ensembles from schools that don't match the contest's school class restrictions.

## Test Data Setup

### Users:
- **fred@demo.org** (demo_director_c) - Director at Kennedy High School (1A school)
- **carrot@demo.org** (demo_director_a) - Director with ensembles at Kennedy High School (1A school)
- **angua@demo.org** (demo_director_b) - Director with ensembles at Washington High School (2A school)

### Schools:
- **Kennedy High School** (demo_school_a) - 1A school
- **Washington High School** (demo_school_b) - 2A school
- **Memorial High School** (demo_school_c) - 2A school

### Contests:
- **District Orchestra** (demo_contest_a) - No restrictions (1A eligible)
- **Regional Orchestra** (demo_contest_b) - Restricted to 1A and 2A
- **2A, 3A State Orchestra** (demo_contest_c) - Restricted to 2A and 3A only

## Manual Test Cases

### Test Case 1: Ineligible School (Issue Scenario)
**Steps:**
1. Log in as `fred@demo.org` or `carrot@demo.org` (Password: `Secret1*3*5*`)
2. If no large ensembles exist, create one for Kennedy High School (1A)
3. Navigate to "2A, 3A State Orchestra" contest
4. Click "Register" button

**Expected Result:**
- User is redirected back to the contest page
- Alert message displays: "None of your ensembles are eligible for this contest. This contest is restricted to 2-A, 3-A schools."
- User cannot proceed with registration

### Test Case 2: Eligible School
**Steps:**
1. Log in as `angua@demo.org` (Password: `Secret1*3*5*`)
2. Ensure there is a large ensemble for Washington High School (2A)
3. Navigate to "2A, 3A State Orchestra" contest
4. Click "Register" button

**Expected Result:**
- Registration form displays successfully
- Dropdown shows only ensembles from 2A or 3A schools
- User can complete registration successfully

### Test Case 3: Unrestricted Contest
**Steps:**
1. Log in as `fred@demo.org` or `carrot@demo.org`
2. Navigate to "District Orchestra" contest (no restrictions)
3. Click "Register" button

**Expected Result:**
- Registration form displays successfully
- All user's ensembles appear in dropdown (including 1A school ensembles)
- User can complete registration successfully

### Test Case 4: Backend Validation
**Steps:**
1. Attempt to create a contest entry directly via API/console with an ineligible ensemble
2. Example: Try to register Kennedy High School (1A) ensemble for "2A, 3A State Orchestra"

**Expected Result:**
- Save fails with validation error
- Error message: "is from a 1-A school, but this contest is restricted to 2-A, 3-A schools"

## Database Verification

### Check Contest School Class Restrictions:
```ruby
Contest.find_by(name: "2A, 3A State Orchestra").school_classes.pluck(:name)
# Should return: ["2-A", "3-A"]
```

### Check School Classifications:
```ruby
School.find_by(name: "Kennedy High School").school_class.name
# Should return: "1-A"

School.find_by(name: "Washington High School").school_class.name
# Should return: "2-A"
```

### Verify Large Ensemble School Class:
```ruby
ensemble = LargeEnsemble.joins(:school).where(schools: { name: "Kennedy High School" }).first
ensemble.school.school_class.name
# Should return: "1-A"
```

## Automated Tests

Run the test suite to verify all validations:

```bash
# Run all tests
bin/rails test

# Run specific test files
bin/rails test test/models/contest_entry_test.rb
bin/rails test test/controllers/contest_entries_controller_test.rb
```

### Key Test Cases:
1. **Model Validation Tests:**
   - `test "should validate school class eligibility for contest"`
   - `test "should allow contest entry when school class matches contest restriction"`
   - `test "should allow all schools when contest has no restrictions"`

2. **Controller Tests:**
   - `test "should redirect when no ensembles are eligible for restricted contest"`
   - `test "should show new contest entry form when user has eligible ensembles for restricted contest"`

## Implementation Details

### Files Modified:
- `app/models/contest_entry.rb` - Added validation
- `app/controllers/contest_entries_controller.rb` - Added filtering logic
- `app/views/contest_entries/_form.html.erb` - Updated to use filtered ensembles
- Test files and fixtures

### Key Methods:
- `ContestEntry#school_class_eligible_for_contest` - Validation method
- `ContestEntriesController#eligible_ensembles_for_contest` - Filtering helper

## Edge Cases Covered

1. **No Restrictions:** When a contest has no school class restrictions, all ensembles are eligible
2. **Multiple Ensembles:** Directors with ensembles from multiple schools see only eligible ones
3. **No Eligible Ensembles:** Clear error message when user has no eligible ensembles
4. **Duplicate Check:** Existing duplicate registration check still works
5. **Form Re-rendering:** When validation fails, form properly displays eligible ensembles

## Notes

- The validation runs at both the controller level (UI filtering) and model level (backend validation)
- This provides defense in depth - even if someone bypasses the UI, the model validation will catch it
- Error messages are user-friendly and explain which school classes are allowed
- The implementation respects the existing association structure (Contest -> school_classes through join table)
