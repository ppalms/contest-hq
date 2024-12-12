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

ActiveRecord::Schema[8.0].define(version: 2024_12_11_035949) do
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
    t.bigint "large_group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contest_id"], name: "index_contest_entries_on_contest_id"
    t.index ["large_group_id"], name: "index_contest_entries_on_large_group_id"
    t.index ["user_id"], name: "index_contest_entries_on_user_id"
  end

  create_table "contests", force: :cascade do |t|
    t.string "name"
    t.datetime "contest_start"
    t.datetime "contest_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "account_id", null: false
    t.index ["account_id"], name: "index_contests_on_account_id"
  end

  create_table "large_group_classes", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "account_id", null: false
    t.index ["account_id"], name: "index_large_group_classes_on_account_id"
  end

  create_table "large_group_conductors", id: false, force: :cascade do |t|
    t.bigint "large_group_id", null: false
    t.bigint "user_id", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_large_group_conductors_on_account_id"
    t.index ["large_group_id", "account_id"], name: "idx_on_large_group_id_account_id_a81d344964"
    t.index ["large_group_id", "user_id", "account_id"], name: "idx_on_large_group_id_user_id_account_id_d73e3c1e6a", unique: true
    t.index ["user_id", "account_id"], name: "index_large_group_conductors_on_user_id_and_account_id"
  end

  create_table "large_groups", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id", null: false
    t.bigint "large_group_class_id", null: false
    t.bigint "account_id", null: false
    t.index ["account_id"], name: "index_large_groups_on_account_id"
    t.index ["large_group_class_id"], name: "index_large_groups_on_large_group_class_id"
    t.index ["organization_id"], name: "index_large_groups_on_organization_id"
  end

  create_table "org_memberships", id: false, force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "user_id", null: false
    t.bigint "account_id", null: false
    t.index ["account_id"], name: "index_org_memberships_on_account_id"
    t.index ["organization_id", "user_id", "account_id"], name: "idx_on_organization_id_user_id_account_id_c9f9014116", unique: true
    t.index ["organization_id"], name: "index_org_memberships_on_organization_id"
    t.index ["user_id"], name: "index_org_memberships_on_user_id"
  end

  create_table "organization_types", force: :cascade do |t|
    t.string "name"
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_organization_types_on_account_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.bigint "organization_type_id", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_organizations_on_account_id"
    t.index ["organization_type_id"], name: "index_organizations_on_organization_type_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
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

  add_foreign_key "contest_entries", "contests"
  add_foreign_key "contest_entries", "large_groups"
  add_foreign_key "contest_entries", "users"
  add_foreign_key "contests", "accounts"
  add_foreign_key "large_group_classes", "accounts"
  add_foreign_key "large_group_conductors", "accounts"
  add_foreign_key "large_group_conductors", "large_groups"
  add_foreign_key "large_group_conductors", "users"
  add_foreign_key "large_groups", "accounts"
  add_foreign_key "large_groups", "large_group_classes"
  add_foreign_key "large_groups", "organizations"
  add_foreign_key "org_memberships", "accounts"
  add_foreign_key "org_memberships", "organizations"
  add_foreign_key "org_memberships", "users"
  add_foreign_key "organization_types", "accounts"
  add_foreign_key "organizations", "accounts"
  add_foreign_key "organizations", "organization_types"
  add_foreign_key "sessions", "users"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "users", "accounts"
end
