require "test_helper"

class OutcomeRankingTest < ActiveSupport::TestCase
  test "belongs to bracket" do
    ranking = OutcomeRanking.create!(
      game_decisions: 42,
      bracket: brackets(:one),
      rank: 1,
      points: 100
    )
    assert_equal brackets(:one), ranking.bracket
  end

  test "stores game_decisions" do
    ranking = OutcomeRanking.create!(
      game_decisions: 42,
      bracket: brackets(:one),
      rank: 1,
      points: 100
    )
    assert_equal 42, ranking.game_decisions
  end
end
