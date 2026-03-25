require "test_helper"

class OutcomeTest < ActiveSupport::TestCase
  test "enforces unique game_decisions" do
    Outcome.create!(game_decisions: 42)
    assert_raises(ActiveRecord::RecordNotUnique) do
      Outcome.create!(game_decisions: 42)
    end
  end

  test "cascade deletes outcome_rankings on raw SQL delete" do
    outcome = Outcome.create!(game_decisions: 42)
    OutcomeRanking.create!(
      outcome: outcome,
      bracket: brackets(:one),
      rank: 1,
      points: 100
    )

    assert_equal 1, OutcomeRanking.where(outcome_id: outcome.id).count

    # Raw SQL delete to simulate the pruning query — Rails callbacks won't fire
    Outcome.where(id: outcome.id).delete_all

    assert_equal 0, OutcomeRanking.where(outcome_id: outcome.id).count
  end
end
