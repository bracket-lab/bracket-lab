class RemovePossibleResults < ActiveRecord::Migration[8.1]
  def change
    drop_table :possible_results do |t|
      t.integer "best_finish", default: 1, null: false
      t.integer "bracket_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index [ "bracket_id" ], name: "index_possible_results_on_bracket_id", unique: true
      t.index [ "updated_at" ], name: "index_possible_results_on_updated_at"
    end
  end
end
