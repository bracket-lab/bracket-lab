class InitialSchema < ActiveRecord::Migration[8.1]
  def change
    create_table "users" do |t|
      t.boolean "admin", default: false, null: false
      t.string "email_address", null: false
      t.string "full_name", null: false
      t.string "password_digest", null: false
      t.integer "payment_credits", default: 0, null: false
      t.timestamps
      t.index [ "admin" ]
      t.index [ "email_address" ], unique: true
    end

    create_table "sessions" do |t|
      t.references "user", null: false, foreign_key: true
      t.string "ip_address"
      t.string "user_agent"
      t.timestamps
    end

    create_table "tournaments" do |t|
      t.bigint "game_decisions", default: 0, null: false
      t.bigint "game_mask", default: 0, null: false
      t.integer "state", default: 0, null: false
      t.timestamps
    end

    create_table "teams" do |t|
      t.string "name", null: false
      t.integer "region", null: false
      t.integer "seed", null: false
      t.integer "starting_slot", null: false
      t.timestamps
      t.index [ "name" ], unique: true
      t.index [ "region", "seed" ], unique: true
      t.index [ "region" ]
      t.index [ "starting_slot" ], unique: true
    end

    create_table "invites" do |t|
      t.references "created_by", null: false, foreign_key: { to_table: :users }
      t.string "email_address", null: false
      t.datetime "expires_at", null: false
      t.string "full_name", null: false
      t.string "token", null: false
      t.datetime "used_at"
      t.timestamps
      t.index [ "email_address" ]
      t.index [ "token" ], unique: true
    end

    create_table "brackets" do |t|
      t.bigint "game_decisions", null: false
      t.string "name", null: false
      t.references "user", null: false, foreign_key: true
      t.timestamps
      t.index [ "name" ], unique: true
    end

    create_table "possible_results" do |t|
      t.integer "best_finish", default: 1, null: false
      t.references "bracket", null: false, index: { unique: true }
      t.timestamps
      t.index [ "updated_at" ]
    end

    add_foreign_key "possible_results", "brackets"
  end
end
