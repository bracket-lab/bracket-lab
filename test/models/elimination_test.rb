require "test_helper"

class EliminationTest < ActiveSupport::TestCase
  setup do
    @elimination = Elimination.new
    set_tournament_state(:final_four)
    @tournament = Tournament.field_64
  end

  test "collects no outcomes when too many games remain" do
    set_tournament_state(:tipoff)

    @elimination.results(Array.new(16) { |i| i * 2 })

    assert_empty @elimination.outcomes
  end

  test "collects outcomes at final four" do
    @elimination.results(@tournament.decision_team_slots.dup)

    assert @elimination.outcomes.any?
  end

  test "outcomes are OutcomeRanking instances" do
    @elimination.results(@tournament.decision_team_slots.dup)

    @elimination.outcomes.each do |outcome|
      assert_kind_of OutcomeRanking, outcome
    end
  end

  test "distinct outcomes match 2^N remaining games" do
    @elimination.results(@tournament.decision_team_slots.dup)

    remaining = @tournament.num_games_remaining
    expected_scenarios = 2**remaining
    distinct_decisions = @elimination.outcomes.map(&:game_decisions).uniq.size
    assert_equal expected_scenarios, distinct_decisions
  end

  test "only collects rankings with rank < 6" do
    @elimination.results(@tournament.decision_team_slots.dup)

    @elimination.outcomes.each do |outcome|
      assert outcome.rank.between?(1, 5),
        "Rank #{outcome.rank} should be between 1 and 5"
    end
  end

  test "tied brackets receive the same rank" do
    @elimination.results(@tournament.decision_team_slots.dup)

    perfect = brackets(:perfect)
    clone = brackets(:perfect_clone)

    perfect_ranks = @elimination.outcomes.select { |o| o.bracket_id == perfect.id }.map(&:rank)
    clone_ranks = @elimination.outcomes.select { |o| o.bracket_id == clone.id }.map(&:rank)

    assert_equal perfect_ranks.sort, clone_ranks.sort
  end

  test "handles nil slot at root" do
    slots = Array.new(16)
    (8..15).each { |i| slots[i] = i * 2 }
    (2..7).each { |i| slots[i] = slots[i * 2] }
    slots[1] = nil

    @elimination.results(slots)

    assert @elimination.outcomes.any?
  end

  test "caches brackets list" do
    elimination = Elimination.new
    first_call = elimination.brackets
    second_call = elimination.brackets

    assert_same first_call, second_call, "Brackets should be cached"
  end
end
