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

ActiveRecord::Schema[8.1].define(version: 2025_03_11_000001) do
  create_table "brackets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "game_decisions", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["name"], name: "index_brackets_on_name", unique: true
    t.index ["user_id"], name: "index_brackets_on_user_id"
  end

  create_table "invites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "created_by_id", null: false
    t.string "email_address", null: false
    t.datetime "expires_at", null: false
    t.string "full_name", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.index ["created_by_id"], name: "index_invites_on_created_by_id"
    t.index ["email_address"], name: "index_invites_on_email_address"
    t.index ["token"], name: "index_invites_on_token", unique: true
  end

  create_table "possible_results", force: :cascade do |t|
    t.integer "best_finish", default: 1, null: false
    t.integer "bracket_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bracket_id"], name: "index_possible_results_on_bracket_id", unique: true
    t.index ["updated_at"], name: "index_possible_results_on_updated_at"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "region", null: false
    t.integer "seed", null: false
    t.integer "starting_slot", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_teams_on_name", unique: true
    t.index ["region", "seed"], name: "index_teams_on_region_and_seed", unique: true
    t.index ["region"], name: "index_teams_on_region"
    t.index ["starting_slot"], name: "index_teams_on_starting_slot", unique: true
  end

  create_table "tournaments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "game_decisions", default: 0, null: false
    t.bigint "game_mask", default: 0, null: false
    t.integer "state", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "full_name", null: false
    t.string "password_digest", null: false
    t.integer "payment_credits", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["admin"], name: "index_users_on_admin"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "brackets", "users"
  add_foreign_key "invites", "users", column: "created_by_id"
  add_foreign_key "possible_results", "brackets"
  add_foreign_key "sessions", "users"
end
