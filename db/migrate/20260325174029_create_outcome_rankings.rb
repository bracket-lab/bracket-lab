class CreateOutcomeRankings < ActiveRecord::Migration[8.1]
  def change
    create_table :outcome_rankings do |t|
      t.bigint :game_decisions, null: false
      t.references :bracket, null: false, foreign_key: true
      t.integer :rank, null: false
      t.integer :points, null: false
      t.index :game_decisions
      t.index [ :bracket_id, :rank ]
      t.timestamps
    end

    add_column :tournaments, :outcomes_calculated, :boolean, default: false, null: false
  end
end
