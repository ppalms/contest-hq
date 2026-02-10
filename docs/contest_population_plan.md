# Contest Population Rake Task - Implementation Plan

## Overview

Create a comprehensive rake task that can populate a contest with realistic test data for both manual testing and setting up demo accounts for trial users.

## Key Requirements

1. **Account Creation**: Prompt user for account name, create if doesn't exist
2. **User Passwords**: All users get `Secret1*3*5*`
3. **Music Selections**: Create actual prescribed music records
4. **Names**: Use predefined lists for schools/ensembles
5. **Rollback**: Full rollback on any failure
6. **Trial Users**: Each gets their own isolated account
7. **Presets**: Skip presets for now (can add later if needed)
8. **Output**: Always show full detailed output

## Files to Create

### 1. `lib/tasks/populate_contest_data.rake`

**Purpose**: Main rake task with user interaction and orchestration

**Interactive Prompts**:
1. Account name (required)
2. Contest name (default: "Demo Contest")
3. Number of entries (default: 15)
4. Number of days (default: 1)
5. Start date (default: 30 days from now)
6. Confirm before proceeding

**Usage**:
```bash
# Interactive mode
bin/rails contest:populate

# Non-interactive mode for automation
bin/rails contest:populate_non_interactive[trial_user_123,"entries:20,days:2"]
```

### 2. `app/services/contest_population_service.rb`

**Purpose**: Core business logic for data generation

**Default Options**:
```ruby
{
  contest_name: "Demo Contest",
  entries: 15,
  days: 1,
  schools: 8,
  ensembles_per_school: 2,
  time_preference_pct: 30,
  start_date: (Date.today + 30.days).to_s,
  start_time: "08:00",
  end_time: "17:00",
  prescribed_music_count: 1,
  custom_music_count: 1
}
```

## Data Generation Phases

### Phase 1: Account & Season Setup
- Find or create account by name
- Create season for current year if doesn't exist
- Set `Current.account` context

### Phase 2: Contest Creation
- Create contest with dates, times, music requirements
- Entry deadline set to 7 days before start

### Phase 3: Contest Infrastructure
- Create 3 rooms: Main Performance Hall, Warm-up Room A, Warm-up Room B
- Create 3 performance phases:
  - Warm Up (20 min) → Warm-up Room A
  - Performance (25 min) → Main Performance Hall
  - Sight Reading (15 min) → Warm-up Room B
- Create schedule

### Phase 4: Schools & Ensembles

**School Names** (predefined list):
- Kennedy High School
- Washington High School
- Lincoln High School
- Roosevelt High School
- Jefferson High School
- Madison High School
- Monroe High School
- Adams High School
- Jackson High School
- Harrison High School
- Wilson High School
- Truman High School
- Eisenhower High School
- Reagan High School
- Carter High School

**Ensemble Types**:
- Wind Ensemble
- Symphonic Orchestra
- Concert Band
- Symphony Band
- String Orchestra
- Philharmonic Orchestra

**School Classes**: 1A, 2A, 3A, 4A, 5A, 6A
**Performance Classes**: A, B, C, D, E

### Phase 5: User Setup

**Directors**:
- One director per school
- Email: `director_N@{account_name}.example.com`
- Password: `Secret1*3*5*`
- Assigned Director role
- Associated with their school

**Manager**:
- Email: `manager@{account_name}.example.com`
- Password: `Secret1*3*5*`
- Assigned Manager role
- Associated with contest

### Phase 6: Contest Entries

- Select random ensembles for entries
- 30% get time preferences:
  - Full range (start + end)
  - After (start only)
  - Before (end only)

### Phase 7: Prescribed Music

**Music Titles & Composers**:
- Symphony No. 5 - Beethoven
- Rhapsody in Blue - Gershwin
- Carnival Overture - Dvořák
- The Planets Suite - Holst
- Appalachian Spring - Copland
- Fanfare for the Common Man - Copland

- Create prescribed music for each school class
- Assign to entries based on school class
- Add custom music selection to each entry

### Phase 8: Schedule Generation

- Generate schedule for each day using `ScheduleGenerationService`
- Place all entries in schedule

## Rollback Strategy

On any error, delete in reverse order:
1. Contest entries
2. Users
3. Ensembles
4. Schools
5. Contest
6. Season (if empty)
7. Account (if empty)

## Output Format

```
================================================================================
CONTEST DATA POPULATION
================================================================================

Account name: trial_user_123
Contest name [Demo Contest]: Spring Music Festival
Number of entries [15]: 20
Number of schedule days [1]: 2
Start date [2026-03-15] (YYYY-MM-DD): 2026-04-01

Configuration:
  Account: trial_user_123
  Contest: Spring Music Festival
  Entries: 20
  Days: 2
  Schools: 8
  Start: Tue Apr 01, 2026

Proceed? (y/n): y

[1/8] Setting up account and season...
  ✓ Account: trial_user_123 (ID: 45)
  ✓ Season: 2026 Season (ID: 12)

[2/8] Creating contest...
  ✓ Contest: Spring Music Festival (ID: 89)
  ✓ Start: Tue Apr 01, 2026  8:00 AM
  ✓ End: Wed Apr 02, 2026  5:00 PM

[3/8] Setting up contest infrastructure...
  ✓ Room: Main Performance Hall
  ✓ Room: Warm-up Room A
  ✓ Room: Warm-up Room B
  ✓ Phase: Warm Up (20 min) → Warm-up Room A
  ✓ Phase: Performance (25 min) → Main Performance Hall
  ✓ Phase: Sight Reading (15 min) → Warm-up Room B
  ✓ Schedule created

[4/8] Creating schools and ensembles...
  ✓ Created 8 schools
  ✓ Created 16 ensembles

[5/8] Setting up users...
  ✓ Created 8 director users
  ✓ Created 1 manager user

[6/8] Creating contest entries...
  ✓ Created 20 entries
  ✓ 6 entries with time preferences (30%)

[7/8] Creating prescribed music and selections...
  ✓ Added music selections to all entries

[8/8] Generating schedule...
  ✓ Day 1: Tue Apr 01, 2026 (08:00 - 17:00)
  ✓ Day 2: Wed Apr 02, 2026 (08:00 - 17:00)
  ✓ Scheduled 20 entries (60 blocks)

================================================================================
SUCCESS! Contest data populated.
================================================================================

Contest Details:
  Name: Spring Music Festival
  ID: 89
  URL: http://localhost:3000/contests/89

Manager Login:
  Email: manager@trial-user-123.example.com
  Password: Secret1*3*5*

Director Logins:
  director_1@trial-user-123.example.com (Kennedy High School)
  director_2@trial-user-123.example.com (Washington High School)
  director_3@trial-user-123.example.com (Lincoln High School)
  ... (5 more)

Schedule:
  URL: http://localhost:3000/schedules/89
  Days: 2
  Entries: 20
  Total Blocks: 60

Quick Start:
  1. Start server: bin/dev
  2. Visit: http://localhost:3000
  3. Sign in as: manager@trial-user-123.example.com
  4. Password: Secret1*3*5*
  5. Navigate to: Spring Music Festival → Schedule
  6. Test rescheduling entries!

================================================================================
```

## Implementation Checklist

- [ ] Create `lib/tasks/populate_contest_data.rake`
- [ ] Create `app/services/contest_population_service.rb`
- [ ] Add helper methods for logging and formatting
- [ ] Implement interactive prompts with defaults
- [ ] Implement non-interactive mode for automation
- [ ] Add comprehensive error handling
- [ ] Implement full rollback on failure
- [ ] Test with various configurations
- [ ] Update AGENTS.md documentation
- [ ] Test end-to-end reschedule flow with generated data

## Estimated Implementation Time

- **Service Object**: 2 hours
- **Rake Task**: 1 hour
- **Testing & Refinement**: 1 hour
- **Documentation**: 30 minutes

**Total**: ~4.5 hours

## Documentation Updates

Add to `AGENTS.md`:

```markdown
## Populating Contest Data for Testing

To quickly set up a contest with test data for manual testing:

```bash
bin/rails contest:populate
```

This will:
- Create a new account (or use existing)
- Create a complete contest with schools, ensembles, and entries
- Generate a schedule
- Provide login credentials for testing

For trial user accounts:
```bash
bin/rails contest:populate_non_interactive[trial_user_email]
```

This creates an isolated account with demo data for the trial user.
```
