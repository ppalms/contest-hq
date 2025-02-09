# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_01_12_143628) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "contest_entries", force: :cascade do |t|
    t.bigint "contest_id", null: false
    t.bigint "user_id", null: false
    t.bigint "large_ensemble_id", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_contest_entries_on_account_id"
    t.index ["contest_id", "large_ensemble_id", "account_id"], name: "index_contest_entries_unique", unique: true
    t.index ["contest_id"], name: "index_contest_entries_on_contest_id"
    t.index ["large_ensemble_id"], name: "index_contest_entries_on_large_ensemble_id"
    t.index ["user_id"], name: "index_contest_entries_on_user_id"
  end

  create_table "contest_managers", id: false, force: :cascade do |t|
    t.bigint "contest_id", null: false
    t.bigint "user_id", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "contest_id", "user_id"], name: "index_contest_managers_unique", unique: true
    t.index ["account_id"], name: "index_contest_managers_on_account_id"
    t.index ["contest_id"], name: "index_contest_managers_on_contest_id"
    t.index ["user_id"], name: "index_contest_managers_on_user_id"
  end

  create_table "contests", force: :cascade do |t|
    t.string "name"
    t.datetime "contest_start"
    t.datetime "contest_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "account_id", null: false
    t.time "start_time"
    t.time "end_time"
    t.index ["account_id"], name: "index_contests_on_account_id"
  end

  create_table "contests_school_classes", id: false, force: :cascade do |t|
    t.bigint "contest_id", null: false
    t.bigint "school_class_id", null: false
    t.bigint "account_id", null: false
    t.index ["account_id", "contest_id", "school_class_id"], name: "index_contests_school_classes_unique", unique: true
    t.index ["account_id"], name: "index_contests_school_classes_on_account_id"
    t.index ["contest_id"], name: "index_contests_school_classes_on_contest_id"
    t.index ["school_class_id"], name: "index_contests_school_classes_on_school_class_id"
  end

  create_table "large_ensemble_conductors", id: false, force: :cascade do |t|
    t.bigint "large_ensemble_id", null: false
    t.bigint "user_id", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_large_ensemble_conductors_on_account_id"
    t.index ["large_ensemble_id", "user_id", "account_id"], name: "index_large_ensemble_conductors_unique", unique: true
    t.index ["large_ensemble_id"], name: "index_large_ensemble_conductors_on_large_ensemble_id"
    t.index ["user_id"], name: "index_large_ensemble_conductors_on_user_id"
  end

  create_table "large_ensembles", force: :cascade do |t|
    t.string "name"
    t.bigint "school_id", null: false
    t.bigint "performance_class_id", null: false
    t.bigint "account_id", null: false
    t.index ["account_id"], name: "index_large_ensembles_on_account_id"
    t.index ["performance_class_id"], name: "index_large_ensembles_on_performance_class_id"
    t.index ["school_id"], name: "index_large_ensembles_on_school_id"
  end

  create_table "music_selections", force: :cascade do |t|
    t.string "title"
    t.string "composer"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "contest_entry_id", null: false
    t.bigint "account_id", null: false
    t.index ["account_id", "contest_entry_id"], name: "index_music_selections_on_account_id_and_contest_entry_id"
    t.index ["account_id"], name: "index_music_selections_on_account_id"
    t.index ["contest_entry_id"], name: "index_music_selections_on_contest_entry_id"
  end

  create_table "performance_classes", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "account_id", null: false
    t.index ["account_id"], name: "index_performance_classes_on_account_id"
  end

  create_table "performance_sequences", force: :cascade do |t|
    t.bigint "schedule_id", null: false
    t.bigint "account_id", null: false
    t.index ["account_id"], name: "index_performance_sequences_on_account_id"
    t.index ["schedule_id"], name: "index_performance_sequences_on_schedule_id"
  end

  create_table "performance_steps", force: :cascade do |t|
    t.text "name", null: false
    t.integer "duration", null: false
    t.integer "ordinal", null: false
    t.bigint "performance_sequence_id", null: false
    t.bigint "room_id", null: false
    t.bigint "account_id", null: false
    t.index ["account_id"], name: "index_performance_steps_on_account_id"
    t.index ["ordinal", "performance_sequence_id"], name: "index_performance_steps_on_ordinal_and_performance_sequence_id", unique: true
    t.index ["performance_sequence_id"], name: "index_performance_steps_on_performance_sequence_id"
    t.index ["room_id"], name: "index_performance_steps_on_room_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "rooms", force: :cascade do |t|
    t.string "room_number", null: false
    t.string "name"
    t.bigint "schedule_id"
    t.bigint "account_id", null: false
    t.index ["account_id"], name: "index_rooms_on_account_id"
    t.index ["room_number", "schedule_id"], name: "index_rooms_on_room_number_and_schedule_id", unique: true
    t.index ["schedule_id"], name: "index_rooms_on_schedule_id"
  end

  create_table "schedule_blocks", force: :cascade do |t|
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.bigint "room_id", null: false
    t.bigint "schedule_day_id", null: false
    t.bigint "account_id", null: false
    t.index ["account_id"], name: "index_schedule_blocks_on_account_id"
    t.index ["room_id"], name: "index_schedule_blocks_on_room_id"
    t.index ["schedule_day_id"], name: "index_schedule_blocks_on_schedule_day_id"
  end

  create_table "schedule_days", force: :cascade do |t|
    t.date "date", null: false
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.bigint "schedule_id", null: false
    t.bigint "account_id", null: false
    t.index ["account_id"], name: "index_schedule_days_on_account_id"
    t.index ["schedule_id"], name: "index_schedule_days_on_schedule_id"
  end

  create_table "schedules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "contest_id", null: false
    t.bigint "account_id", null: false
    t.index ["account_id"], name: "index_schedules_on_account_id"
    t.index ["contest_id"], name: "index_schedules_on_contest_id"
  end

  create_table "school_classes", force: :cascade do |t|
    t.string "name"
    t.integer "ordinal"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "account_id", null: false
    t.index ["account_id", "ordinal"], name: "index_school_classes_on_account_id_and_ordinal", unique: true
    t.index ["account_id"], name: "index_school_classes_on_account_id"
  end

  create_table "school_directors", id: false, force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "user_id", null: false
    t.bigint "account_id", null: false
    t.index ["account_id"], name: "index_school_directors_on_account_id"
    t.index ["school_id", "user_id", "account_id"], name: "index_school_directors_unique", unique: true
    t.index ["school_id"], name: "index_school_directors_on_school_id"
    t.index ["user_id"], name: "index_school_directors_on_user_id"
  end

  create_table "schools", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "school_class_id", null: false
    t.bigint "account_id", null: false
    t.index ["account_id"], name: "index_schools_on_account_id"
    t.index ["school_class_id"], name: "index_schools_on_school_class_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "user_roles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.boolean "verified", default: false, null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "time_zone", default: "UTC", null: false
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["last_name"], name: "index_users_on_last_name"
  end

  add_foreign_key "contest_entries", "accounts"
  add_foreign_key "contest_entries", "contests"
  add_foreign_key "contest_entries", "large_ensembles"
  add_foreign_key "contest_entries", "users"
  add_foreign_key "contest_managers", "accounts"
  add_foreign_key "contest_managers", "contests"
  add_foreign_key "contest_managers", "users"
  add_foreign_key "contests", "accounts"
  add_foreign_key "contests_school_classes", "accounts"
  add_foreign_key "contests_school_classes", "contests"
  add_foreign_key "contests_school_classes", "school_classes"
  add_foreign_key "large_ensemble_conductors", "accounts"
  add_foreign_key "large_ensemble_conductors", "large_ensembles"
  add_foreign_key "large_ensemble_conductors", "users"
  add_foreign_key "large_ensembles", "accounts"
  add_foreign_key "large_ensembles", "performance_classes"
  add_foreign_key "large_ensembles", "schools"
  add_foreign_key "music_selections", "accounts"
  add_foreign_key "music_selections", "contest_entries"
  add_foreign_key "performance_classes", "accounts"
  add_foreign_key "performance_sequences", "accounts"
  add_foreign_key "performance_sequences", "schedules"
  add_foreign_key "performance_steps", "accounts"
  add_foreign_key "performance_steps", "performance_sequences"
  add_foreign_key "performance_steps", "rooms"
  add_foreign_key "rooms", "accounts"
  add_foreign_key "rooms", "schedules"
  add_foreign_key "schedule_blocks", "accounts"
  add_foreign_key "schedule_blocks", "rooms"
  add_foreign_key "schedule_blocks", "schedule_days"
  add_foreign_key "schedule_days", "accounts"
  add_foreign_key "schedule_days", "schedules"
  add_foreign_key "schedules", "accounts"
  add_foreign_key "schedules", "contests"
  add_foreign_key "school_classes", "accounts"
  add_foreign_key "school_directors", "accounts"
  add_foreign_key "school_directors", "schools"
  add_foreign_key "school_directors", "users"
  add_foreign_key "schools", "accounts"
  add_foreign_key "schools", "school_classes"
  add_foreign_key "sessions", "users"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "users", "accounts"
end
