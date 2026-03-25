class FlattenOutcomeRankings < ActiveRecord::Migration[8.1]
  def change
    add_column :outcome_rankings, :game_decisions, :bigint

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE outcome_rankings
          SET game_decisions = (
            SELECT outcomes.game_decisions
            FROM outcomes
            WHERE outcomes.id = outcome_rankings.outcome_id
          )
        SQL

        change_column_null :outcome_rankings, :game_decisions, false
      end
    end

    remove_reference :outcome_rankings, :outcome, foreign_key: { on_delete: :cascade }
    add_index :outcome_rankings, :game_decisions

    drop_table :outcomes do |t|
      t.bigint :game_decisions, null: false
      t.index :game_decisions, unique: true
    end
  end
end
