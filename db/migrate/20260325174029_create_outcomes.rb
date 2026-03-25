class CreateOutcomes < ActiveRecord::Migration[8.1]
  def change
    create_table :outcomes do |t|
      t.bigint :game_decisions, null: false
      t.index :game_decisions, unique: true
    end

    create_table :outcome_rankings do |t|
      t.references :outcome, null: false, foreign_key: { on_delete: :cascade }
      t.references :bracket, null: false, foreign_key: true
      t.integer :rank, null: false
      t.integer :points, null: false
      t.index [ :bracket_id, :rank ]
    end

    add_column :tournaments, :outcomes_calculated, :boolean, default: false, null: false
  end
end
