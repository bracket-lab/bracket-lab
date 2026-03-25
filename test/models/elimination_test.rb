require "test_helper"

class EliminationTest < ActiveSupport::TestCase
  setup do
    set_tournament_state(:final_four)
    @tournament = Tournament.field_64
    OutcomeRanking.delete_all
  end

  test "creates no outcome_rankings when too many games remain" do
    set_tournament_state(:tipoff)

    Elimination.new.results(Array.new(16) { |i| i * 2 })

    assert_equal 0, OutcomeRanking.count
  end

  test "creates outcome_rankings at final four" do
    Elimination.new.results(@tournament.decision_team_slots.dup)

    assert OutcomeRanking.count > 0
  end

  test "distinct game_decisions match 2^N remaining games" do
    Elimination.new.results(@tournament.decision_team_slots.dup)

    remaining = @tournament.num_games_remaining
    expected_scenarios = 2**remaining
    assert_equal expected_scenarios, OutcomeRanking.distinct.count(:game_decisions)
  end

  test "only creates rankings with rank < 6" do
    Elimination.new.results(@tournament.decision_team_slots.dup)

    OutcomeRanking.find_each do |ranking|
      assert ranking.rank.between?(1, 5),
        "Rank #{ranking.rank} should be between 1 and 5"
    end
  end

  test "tied brackets receive the same rank" do
    Elimination.new.results(@tournament.decision_team_slots.dup)

    perfect = brackets(:perfect)
    clone = brackets(:perfect_clone)

    perfect_ranks = OutcomeRanking.where(bracket_id: perfect.id).pluck(:rank).sort
    clone_ranks = OutcomeRanking.where(bracket_id: clone.id).pluck(:rank).sort

    assert_equal perfect_ranks, clone_ranks
  end

  test "handles nil slot at root" do
    slots = Array.new(16)
    (8..15).each { |i| slots[i] = i * 2 }
    (2..7).each { |i| slots[i] = slots[i * 2] }
    slots[1] = nil

    Elimination.new.results(slots)

    assert OutcomeRanking.count > 0
  end

  test "caches brackets list" do
    elimination = Elimination.new
    first_call = elimination.brackets
    second_call = elimination.brackets

    assert_same first_call, second_call, "Brackets should be cached"
  end
end
