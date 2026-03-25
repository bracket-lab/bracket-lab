require "test_helper"

class OutcomeRankingTest < ActiveSupport::TestCase
  test "belongs to outcome" do
    outcome = Outcome.create!(game_decisions: 42)
    ranking = OutcomeRanking.create!(
      outcome: outcome,
      bracket: brackets(:one),
      rank: 1,
      points: 100
    )
    assert_equal outcome, ranking.outcome
  end

  test "belongs to bracket" do
    outcome = Outcome.create!(game_decisions: 42)
    bracket = brackets(:one)
    ranking = OutcomeRanking.create!(
      outcome: outcome,
      bracket: bracket,
      rank: 1,
      points: 100
    )
    assert_equal bracket, ranking.bracket
  end
end
