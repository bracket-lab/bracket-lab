class OutcomeRanking < ApplicationRecord
  belongs_to :bracket

  def game_decisions
    value = super
    return 0 if value.nil?
    value << 1
  end

  def game_decisions=(value)
    self[:game_decisions] = (Integer(value) >> 1) & Bracket::MAX_INT64
  end
end
