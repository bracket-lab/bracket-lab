class UniqueOutcomeBracket < ActiveRecord::Migration[8.1]
  def change
    add_index :outcome_rankings, [ :game_decisions, :bracket_id ], unique: true
  end
end
