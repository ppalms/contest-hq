# Prescribed Music Seed Script
# Run with: rails runner db/seeds/prescribed_music.rb

puts "🎵 Seeding Prescribed Music..."

ossaa_account = Account.find_by(name: "OSSAA")

if ossaa_account.nil?
  puts "  ⚠️  OSSAA account not found. Run ossaa_demo_contest.rb first."
  exit
end

Current.account = ossaa_account

season_2025 = Season.find_by(name: "2025", account: ossaa_account)

if season_2025.nil?
  puts "  ⚠️  2025 season not found. Creating..."
  season_2025 = Season.create!(name: "2025", archived: false, account: ossaa_account)
end

school_classes = SchoolClass.where(account: ossaa_account).order(:ordinal)

if school_classes.empty?
  puts "  ⚠️  No school classes found. Run ossaa_schools.rb first."
  Current.reset
  exit
end

prescribed_music_data = {
  "6A" => [
    { title: "Symphony No. 5 in C Minor", composer: "Ludwig van Beethoven" },
    { title: "The Planets - Mars", composer: "Gustav Holst" },
    { title: "Rhapsody in Blue", composer: "George Gershwin" },
    { title: "Scheherazade", composer: "Nikolai Rimsky-Korsakov" },
    { title: "Pictures at an Exhibition", composer: "Modest Mussorgsky" }
  ],
  "5A" => [
    { title: "Symphony No. 40 in G Minor", composer: "Wolfgang Amadeus Mozart" },
    { title: "The Moldau", composer: "Bedřich Smetana" },
    { title: "Finlandia", composer: "Jean Sibelius" },
    { title: "Danse Macabre", composer: "Camille Saint-Saëns" },
    { title: "Carnival Overture", composer: "Antonín Dvořák" }
  ],
  "4A" => [
    { title: "Eine Kleine Nachtmusik", composer: "Wolfgang Amadeus Mozart" },
    { title: "Simple Symphony", composer: "Benjamin Britten" },
    { title: "Capriol Suite", composer: "Peter Warlock" },
    { title: "Holberg Suite", composer: "Edvard Grieg" },
    { title: "St. Paul's Suite", composer: "Gustav Holst" }
  ],
  "3A" => [
    { title: "Canon in D", composer: "Johann Pachelbel" },
    { title: "Air on the G String", composer: "Johann Sebastian Bach" },
    { title: "Serenade for Strings", composer: "Pyotr Ilyich Tchaikovsky" },
    { title: "Simple Gifts", composer: "Traditional/arr. Various" },
    { title: "Greensleeves", composer: "Traditional/arr. Vaughan Williams" }
  ],
  "2A" => [
    { title: "Minuet in G", composer: "Johann Sebastian Bach" },
    { title: "Ode to Joy", composer: "Ludwig van Beethoven" },
    { title: "Theme from Symphony No. 9", composer: "Antonín Dvořák" },
    { title: "Jesu, Joy of Man's Desiring", composer: "Johann Sebastian Bach" },
    { title: "Bourrée", composer: "George Frideric Handel" }
  ]
}

created_count = 0

prescribed_music_data.each do |class_name, music_list|
  school_class = school_classes.find_by(name: class_name)

  next unless school_class

  puts "  📚 Adding prescribed music for #{class_name}..."

  music_list.each do |music_data|
    prescribed_music = PrescribedMusic.find_or_create_by(
      title: music_data[:title],
      composer: music_data[:composer],
      season: season_2025,
      school_class: school_class,
      account: ossaa_account
    )

    if prescribed_music.persisted?
      created_count += 1
      puts "    ✓ #{music_data[:title]} - #{music_data[:composer]}"
    else
      puts "    ✗ Failed to create: #{music_data[:title]}"
    end
  end
end

Current.reset

puts "✅ Seeded #{created_count} prescribed music entries for OSSAA 2025 season"
