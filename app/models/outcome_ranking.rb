class OutcomeRanking < ApplicationRecord
  include ShiftedBitwiseColumns
  shifted_bitwise_columns :game_decisions

  belongs_to :bracket
end
