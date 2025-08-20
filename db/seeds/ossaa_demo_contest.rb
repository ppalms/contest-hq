# OSSAA Demo Contest Entries Seed Script
# Run with: rails runner db/seeds/ossaa_demo_contest.rb
#
# This script generates demo contest entries with preferred times stored in UTC.

puts "🎼 Seeding OSSAA Demo Contest Entries..."

ossaa_account = Account.find_or_create_by(name: "OSSAA") do |account|
  puts "  📋 Creating OSSAA account..."
end

ossaa_season = Season.find_or_create_by(name: "2025", account: ossaa_account) do |season|
  season.archived = false
  puts "  📅 Creating OSSAA 2025 season..."
end

contest_start_date = Date.current + 7.weeks
until contest_start_date.friday?
  contest_start_date += 1.day
end
contest_end_date = contest_start_date + 1.day # Saturday

entry_deadline = contest_start_date - 3.weeks

puts "  📅 Contest dates: #{contest_start_date.strftime('%A, %B %d')} - #{contest_end_date.strftime('%A, %B %d, %Y')}"
puts "  📅 Entry deadline: #{entry_deadline.strftime('%A, %B %d, %Y')}"

demo_contest = Contest.find_or_create_by(
  name: "2025 OSSAA Demo State Orchestra Contest",
  account: ossaa_account
) do |contest|
  contest.season = ossaa_season
  contest.contest_start = contest_start_date.beginning_of_day + 8.hours # 8:00 AM start
  contest.contest_end = contest_end_date.end_of_day - 1.hour # 11:00 PM end
  contest.entry_deadline = entry_deadline.end_of_day
  puts "  🏆 Creating demo contest..."
end

school_classes = SchoolClass.where(account: ossaa_account)
school_classes.each do |school_class|
  csc = ContestsSchoolClass.find_or_create_by(
    contest: demo_contest,
    school_class: school_class,
    account: ossaa_account  # Add this line
  )
  unless csc.persisted?
    puts "❌ Error linking #{school_class.name}: #{csc.errors.full_messages.join(', ')}"
  end
end
puts "  📚 Linked to #{school_classes.count} school classes"

schools_6a = School.joins(:school_class).where(account: ossaa_account, school_classes: { name: "6A" }).limit(15)
schools_5a = School.joins(:school_class).where(account: ossaa_account, school_classes: { name: "5A" }).limit(12)
schools_4a = School.joins(:school_class).where(account: ossaa_account, school_classes: { name: "4A" }).limit(12)
schools_3a = School.joins(:school_class).where(account: ossaa_account, school_classes: { name: "3A" }).limit(12)
schools_2a = School.joins(:school_class).where(account: ossaa_account, school_classes: { name: "2A" }).limit(9)

performance_classes = {
  "Symphony Orchestra" => PerformanceClass.find_by(name: "First", account: ossaa_account),
  "Chamber Orchestra" => PerformanceClass.find_by(name: "Second", account: ossaa_account),
  "String Orchestra" => PerformanceClass.find_by(name: "Third", account: ossaa_account),
  "Concert Orchestra" => PerformanceClass.find_by(name: "Fourth", account: ossaa_account)
}

demo_entries_data = []

# Helper to generate preferred start times with realistic distribution
# Returns Time objects in UTC that represent local contest times
def generate_preferred_time(index)
  case index % 10
  when 0..6 # 70% mid-morning (9:00-11:00 AM local time)
    time_strings = [ "09:00", "09:30", "10:00", "10:30" ]
  when 7..8 # 20% late morning (10:30 AM-12:00 PM local time)
    time_strings = [ "10:30", "11:00", "11:30" ]
  else # 10% early morning or afternoon (local time)
    time_strings = [ "08:30", "13:00", "14:00" ]
  end

  time_string = time_strings.sample
  central_tz = ActiveSupport::TimeZone.new('America/Chicago')
  local_time = central_tz.parse("2000-01-01 #{time_string}:00")

  local_time.utc
end

oklahoma_director_names = [
  [ "Sarah", "Johnson" ], [ "Michael", "Williams" ], [ "Jennifer", "Brown" ],
  [ "David", "Davis" ], [ "Lisa", "Miller" ], [ "Robert", "Wilson" ],
  [ "Mary", "Moore" ], [ "James", "Taylor" ], [ "Patricia", "Anderson" ],
  [ "John", "Thomas" ], [ "Linda", "Jackson" ], [ "William", "White" ],
  [ "Barbara", "Harris" ], [ "Richard", "Martin" ], [ "Susan", "Thompson" ],
  [ "Joseph", "Garcia" ], [ "Jessica", "Martinez" ], [ "Thomas", "Robinson" ],
  [ "Nancy", "Clark" ], [ "Christopher", "Rodriguez" ], [ "Karen", "Lewis" ],
  [ "Daniel", "Lee" ], [ "Betty", "Walker" ], [ "Matthew", "Hall" ],
  [ "Helen", "Allen" ], [ "Mark", "Young" ], [ "Donna", "Hernandez" ],
  [ "Steven", "King" ], [ "Carol", "Wright" ], [ "Paul", "Lopez" ],
  [ "Ruth", "Hill" ], [ "Andrew", "Scott" ], [ "Sharon", "Green" ],
  [ "Joshua", "Adams" ], [ "Michelle", "Baker" ], [ "Kenneth", "Gonzalez" ],
  [ "Sarah", "Nelson" ], [ "Kevin", "Carter" ], [ "Deborah", "Mitchell" ],
  [ "Brian", "Perez" ], [ "Dorothy", "Roberts" ], [ "George", "Turner" ],
  [ "Emily", "Phillips" ], [ "Ronald", "Campbell" ], [ "Kimberly", "Parker" ],
  [ "Anthony", "Evans" ], [ "Lisa", "Edwards" ], [ "Edward", "Collins" ],
  [ "Nancy", "Stewart" ], [ "Ryan", "Sanchez" ], [ "Sandra", "Morris" ],
  [ "Jason", "Reed" ], [ "Ashley", "Cook" ], [ "Jeffrey", "Bailey" ],
  [ "Amanda", "Rivera" ], [ "Jacob", "Cooper" ], [ "Stephanie", "Richardson" ],
  [ "Gary", "Cox" ], [ "Cynthia", "Howard" ], [ "Nicholas", "Ward" ],
  [ "Amy", "Torres" ], [ "Jonathan", "Peterson" ]
]

classical_repertoire = [
  { title: "Symphony No. 40 in G minor", composer: "Wolfgang Amadeus Mozart" },
  { title: "Symphony No. 5 in C minor", composer: "Ludwig van Beethoven" },
  { title: "Symphony No. 9 'From the New World'", composer: "Antonin Dvorak" },
  { title: "Romeo and Juliet Overture", composer: "Pyotr Ilyich Tchaikovsky" },
  { title: "Eine kleine Nachtmusik", composer: "Wolfgang Amadeus Mozart" },
  { title: "Finlandia", composer: "Jean Sibelius" },
  { title: "The Moldau", composer: "Bedrich Smetana" },
  { title: "Capriccio Italien", composer: "Pyotr Ilyich Tchaikovsky" },
  { title: "Egmont Overture", composer: "Ludwig van Beethoven" },
  { title: "Hebrides Overture", composer: "Felix Mendelssohn" },
  { title: "Serenade for Strings", composer: "Antonin Dvorak" },
  { title: "Simple Symphony", composer: "Benjamin Britten" },
  { title: "Holberg Suite", composer: "Edvard Grieg" },
  { title: "St. Paul's Suite", composer: "Gustav Holst" },
  { title: "Capriol Suite", composer: "Peter Warlock" },
  { title: "Fantasia on Greensleeves", composer: "Ralph Vaughan Williams" },
  { title: "Romanian Folk Dances", composer: "Bela Bartok" },
  { title: "Elegy for Dunkirk", composer: "John Rutter" },
  { title: "Adagio for Strings", composer: "Samuel Barber" },
  { title: "Variations on a Theme by Frank Bridge", composer: "Benjamin Britten" },
  { title: "Firebird Suite", composer: "Igor Stravinsky" },
  { title: "Peter and the Wolf", composer: "Sergei Prokofiev" },
  { title: "Young Person's Guide to the Orchestra", composer: "Benjamin Britten" },
  { title: "Scheherazade", composer: "Nikolai Rimsky-Korsakov" },
  { title: "William Tell Overture", composer: "Gioachino Rossini" },
  { title: "1812 Overture", composer: "Pyotr Ilyich Tchaikovsky" },
  { title: "Carnival of the Animals", composer: "Camille Saint-Saens" },
  { title: "Peer Gynt Suite", composer: "Edvard Grieg" },
  { title: "Water Music Suite", composer: "George Frideric Handel" },
  { title: "Brandenburg Concerto No. 3", composer: "Johann Sebastian Bach" }
]

entry_index = 0

[
  { schools: schools_6a, count: 15 },
  { schools: schools_5a, count: 12 },
  { schools: schools_4a, count: 12 },
  { schools: schools_3a, count: 12 },
  { schools: schools_2a, count: 9 }
].each do |group|
  group[:schools].first(group[:count]).each do |school|
    director_name = oklahoma_director_names[entry_index]
    ensemble_type = [ "Symphony Orchestra", "Chamber Orchestra", "String Orchestra", "Concert Orchestra" ].sample

    demo_entries_data << {
      school: school,
      ensemble_name: ensemble_type,
      performance_class: performance_classes[ensemble_type],
      director_first_name: director_name[0],
      director_last_name: director_name[1],
      director_email: "#{director_name[0].downcase}.#{director_name[1].downcase}@#{school.name.downcase.gsub(/[^a-z]/, '')}ps.org",
      preferred_time_start: generate_preferred_time(entry_index),
      preferred_time_end: nil, # Contest manager will set duration
      music_selections: classical_repertoire.sample(3)
    }

    entry_index += 1
  end
end

created_count = 0
updated_count = 0
skipped_count = 0

demo_entries_data.each_with_index do |entry_data, index|
  begin
    director = User.find_or_initialize_by(
      email: entry_data[:director_email],
      account: ossaa_account
    )

    if director.new_record?
      director.assign_attributes(
        first_name: entry_data[:director_first_name],
        last_name: entry_data[:director_last_name],
        password: "Secret1*3*5*",
        verified: true,
        time_zone: "America/Chicago"
      )
      director.save!
    end

    large_ensemble = LargeEnsemble.find_or_initialize_by(
      name: entry_data[:ensemble_name],
      school: entry_data[:school],
      account: ossaa_account
    )

    if large_ensemble.new_record?
      large_ensemble.performance_class = entry_data[:performance_class]

      # Temporarily set Current.session for the after_create callback
      temp_session = Session.create(user: director)
      begin
        Current.session = temp_session
        large_ensemble.save!
      ensure
        Current.reset
        temp_session.destroy
      end
    else
      LargeEnsembleConductor.find_or_create_by(
        large_ensemble: large_ensemble,
        user: director
      )
    end

    contest_entry = ContestEntry.find_or_initialize_by(
      contest: demo_contest,
      large_ensemble: large_ensemble,
      account: ossaa_account
    )

    if contest_entry.new_record?
      contest_entry.assign_attributes(
        user: director,
        preferred_time_start: entry_data[:preferred_time_start],
        preferred_time_end: entry_data[:preferred_time_end]
      )
      contest_entry.save!
      created_count += 1
      print "+"
    else
      time_changed = false
      new_preferred_time = entry_data[:preferred_time_start]

      if contest_entry.preferred_time_start.nil? ||
         contest_entry.preferred_time_start.utc.strftime("%H:%M") != new_preferred_time.utc.strftime("%H:%M")
        contest_entry.preferred_time_start = new_preferred_time
        time_changed = true
      end

      if time_changed
        contest_entry.save!
        updated_count += 1
        print "u"
      else
        skipped_count += 1
        print "."
      end
    end

    entry_data[:music_selections].each do |music_data|
      MusicSelection.find_or_create_by(
        contest_entry: contest_entry,
        title: music_data[:title],
        composer: music_data[:composer],
        account: ossaa_account
      )
    end

    # Progress indicator every 10 entries
    if (index + 1) % 10 == 0
      puts " (#{index + 1}/#{demo_entries_data.count})"
    end

  rescue => e
    puts "\n❌ Error creating entry for #{entry_data[:school].name}: #{e.message}"
    next
  end
end

puts "\n\n🎉 OSSAA Demo Contest seeding completed!"
puts "   📊 Summary:"
puts "   - Contest: #{demo_contest.name} ✓"
puts "   - Contest Dates: #{demo_contest.contest_start.strftime('%B %d')} - #{demo_contest.contest_end.strftime('%B %d, %Y')} ✓"
puts "   - Entry Deadline: #{demo_contest.entry_deadline.strftime('%B %d, %Y')} ✓"
puts "   - School Classes Linked: #{school_classes.count} ✓"
puts "   - Contest Entries Created: #{created_count}"
puts "   - Contest Entries Updated: #{updated_count}"
puts "   - Contest Entries Skipped (already current): #{skipped_count}"
puts "   - Total Entries Processed: #{demo_entries_data.count}"
puts "\n   📈 Progress Legend:"
puts "   + = Created, u = Updated, . = Skipped (every 10 entries)"

puts "\n   🔍 Verification:"
actual_entry_count = ContestEntry.where(contest: demo_contest).count
puts "   - Total contest entries in demo contest: #{actual_entry_count}"

# Show preferred time distribution
time_distribution = ContestEntry.where(contest: demo_contest)
  .where.not(preferred_time_start: nil)
  .group("preferred_time_start::text")
  .count
  .transform_keys { |key| Time.parse(key).strftime("%H:%M") }
  .sort

puts "\n   ⏰ Preferred Time Distribution (stored as UTC):"
time_distribution.each do |time, count|
  next if time.nil?
  percentage = (count.to_f / actual_entry_count * 100).round(1)
  puts "   - #{time}: #{count} entries (#{percentage}%)"
end

total_music_selections = MusicSelection.joins(:contest_entry).where(contest_entries: { contest: demo_contest }).count
puts "   - Total music selections: #{total_music_selections}"

puts "\n✨ Demo contest ready for scheduling workflow demonstration!"
