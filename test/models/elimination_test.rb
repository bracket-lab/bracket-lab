require "test_helper"

class EliminationTest < ActiveSupport::TestCase
  setup do
    @elimination = Elimination.new
    set_tournament_state(:final_four)
    @tournament = Tournament.field_64
  end

  test "initializes with all brackets at rank 6" do
    bracket = brackets(:one)
    assert_equal 6, @elimination.acc[bracket.id]
  end

  test "calculates rankings for small tournament subset" do
    # Use only a small subset of the tournament tree (16 teams instead of 64)
    slots = Array.new(16)
    (8..15).each { |i| slots[i] = i * 2 } # Fill leaf nodes
    (1..7).each { |i| slots[i] = slots[i * 2] } # Fill internal nodes

    @elimination.results(slots)

    # Verify rankings are assigned
    assert @elimination.acc.values.all? { |rank| rank.between?(1, 6) }
    assert @elimination.acc.values.include?(1) # Someone must be first
  end

  test "handles recursive calculation for incomplete tournament" do
    # Test with just 4 games remaining
    slots = Array.new(16)
    (8..15).each { |i| slots[i] = i * 2 } # Fill leaf nodes
    (5..7).each { |i| slots[i] = slots[i * 2] } # Fill most internal nodes
    (1..4).each { |i| slots[i] = nil } # Leave 4 games undecided

    @elimination.results(slots)

    # Rankings should still be valid
    assert @elimination.acc.values.all? { |rank| rank.between?(1, 6) }
  end

  test "maintains best rank achieved" do
    # Test with minimal tournament size
    slots = Array.new(16)
    (8..15).each { |i| slots[i] = i * 2 }
    (1..7).each { |i| slots[i] = slots[i * 2] }

    @elimination.results(slots)
    first_ranks = @elimination.acc.dup

    # Change championship winner
    slots[1] = slots[3]
    @elimination.results(slots)

    # Each bracket should keep its best rank
    @elimination.acc.each do |bracket_id, rank|
      assert rank <= first_ranks[bracket_id],
             "Rank should not get worse (was #{first_ranks[bracket_id]}, now #{rank})"
    end
  end

  test "stops at rank 5" do
    # Use minimal tournament size
    slots = Array.new(16)
    (8..15).each { |i| slots[i] = i * 2 }
    (1..7).each { |i| slots[i] = slots[i * 2] }

    @elimination.results(slots)

    assert @elimination.acc.values.all? { |rank| rank <= 6 }
  end

  test "does not calculate rankings when too many games remain" do
    set_tournament_state(:tipoff)
    slots = Array.new(16) { |i| i * 2 }

    @elimination.results(slots)

    assert @elimination.acc.values.all? { |rank| rank == 6 }
  end

  test "handles nil slot at root" do
    # Use minimal tournament size
    slots = Array.new(16)
    (8..15).each { |i| slots[i] = i * 2 }
    (2..7).each { |i| slots[i] = slots[i * 2] }
    slots[1] = nil

    @elimination.results(slots)

    assert @elimination.acc.values.all? { |rank| rank.between?(1, 6) }
  end

  test "handles tied rankings" do
    bracket1 = brackets(:perfect)
    bracket2 = brackets(:perfect_clone)

    # Use minimal tournament size
    slots = Array.new(16)
    (8..15).each { |i| slots[i] = i * 2 }
    (1..7).each { |i| slots[i] = slots[i * 2] }

    @elimination.results(slots)

    assert_equal @elimination.acc[bracket1.id], @elimination.acc[bracket2.id]
  end

  test "caches brackets list" do
    elimination = Elimination.new
    first_call = elimination.brackets
    second_call = elimination.brackets

    assert_same first_call, second_call, "Brackets should be cached"
  end

  test "collects outcomes" do
    @elimination.results(@tournament.decision_team_slots.dup)

    assert @elimination.outcomes.any?, "Should collect outcomes"
  end

  test "outcome count matches 2^N remaining games" do
    @elimination.results(@tournament.decision_team_slots.dup)

    remaining = @tournament.num_games_remaining
    expected_count = 2**remaining
    assert_equal expected_count, @elimination.outcomes.size
  end

  test "collects unique game_decisions per outcome" do
    @elimination.results(@tournament.decision_team_slots.dup)

    decisions = @elimination.outcomes.map { |o| o[:game_decisions] }
    assert_equal decisions.size, decisions.uniq.size
  end

  test "only collects rankings with rank < 6" do
    @elimination.results(@tournament.decision_team_slots.dup)

    @elimination.outcomes.each do |outcome|
      outcome[:rankings].each do |ranking|
        assert ranking[:rank].between?(1, 5),
          "Rank #{ranking[:rank]} should be between 1 and 5"
      end
    end
  end

  test "outcome rankings match accumulator best_finish" do
    @elimination.results(@tournament.decision_team_slots.dup)

    # Derive best_finish from collected outcomes
    derived = {}
    @elimination.outcomes.each do |outcome|
      outcome[:rankings].each do |r|
        derived[r[:bracket_id]] = [ r[:rank], derived[r[:bracket_id]] || 6 ].min
      end
    end

    @elimination.acc.each do |bracket_id, best_finish|
      derived_finish = derived[bracket_id] || 6
      assert_equal best_finish, derived_finish,
        "Bracket #{bracket_id}: acc=#{best_finish}, derived=#{derived_finish}"
    end
  end
end
