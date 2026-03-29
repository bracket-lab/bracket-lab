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

  test "round-trips game_decisions through left-shift/right-shift" do
    ranking = OutcomeRanking.create!(
      game_decisions: 42,
      bracket: brackets(:one),
      rank: 1,
      points: 100
    )
    ranking.reload
    assert_equal 42, ranking.game_decisions
  end

  class PopulateTest < ActiveSupport::TestCase
    setup do
      set_tournament_state(:final_four)
      @tournament = Tournament.field_64
      OutcomeRanking.delete_all
    end

    test "cleans up and resets flag when not eliminating" do
      OutcomeRanking.populate(@tournament)
      assert OutcomeRanking.count > 0
      assert @tournament.reload.outcomes_calculated?

      set_tournament_state(:some_games)
      @tournament.reload
      OutcomeRanking.populate(@tournament)

      assert_equal 0, OutcomeRanking.count
      assert_not @tournament.reload.outcomes_calculated?
    end

    test "populates outcome_rankings when eliminating" do
      OutcomeRanking.populate(@tournament)

      remaining = @tournament.num_games_remaining
      expected_scenarios = 2**remaining
      assert_equal expected_scenarios, OutcomeRanking.distinct.count(:game_decisions)
      assert OutcomeRanking.count > 0
    end

    test "sets outcomes_calculated after populate" do
      assert_not @tournament.outcomes_calculated?

      OutcomeRanking.populate(@tournament)

      assert @tournament.reload.outcomes_calculated?
    end

    test "best finish derivable from outcome_rankings" do
      OutcomeRanking.populate(@tournament)

      best_finishes = OutcomeRanking.group(:bracket_id).minimum(:rank)

      Bracket.find_each do |bracket|
        expected = best_finishes[bracket.id] || 6
        assert expected.between?(1, 6),
          "Bracket #{bracket.id}: best_finish=#{expected} should be between 1 and 6"
      end
    end

    test "prunes stale outcomes on subsequent run" do
      OutcomeRanking.populate(@tournament)
      initial_count = OutcomeRanking.count

      @tournament.update_game!(2, 0)
      OutcomeRanking.populate(@tournament.reload)

      assert OutcomeRanking.count < initial_count,
        "Should decrease (was #{initial_count}, now #{OutcomeRanking.count})"
    end

    test "advances updated_at after prune so caches invalidate" do
      OutcomeRanking.populate(@tournament)
      max_before = OutcomeRanking.maximum(:updated_at)

      travel 1.second do
        @tournament.update_game!(2, 0)
        OutcomeRanking.populate(@tournament.reload)
      end

      max_after = OutcomeRanking.maximum(:updated_at)
      assert max_after > max_before,
        "OutcomeRanking.maximum(:updated_at) should advance after prune"
    end

    test "leaves outcomes_calculated true after prune" do
      OutcomeRanking.populate(@tournament)
      assert @tournament.reload.outcomes_calculated?

      @tournament.update_game!(2, 0)
      OutcomeRanking.populate(@tournament.reload)

      assert @tournament.reload.outcomes_calculated?
    end

    test "idempotent — running twice without game changes" do
      OutcomeRanking.populate(@tournament)
      count_after_first = OutcomeRanking.count

      OutcomeRanking.populate(@tournament)
      assert_equal count_after_first, OutcomeRanking.count
    end

    test "tied brackets receive the same rank" do
      OutcomeRanking.populate(@tournament)

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

      OutcomeRanking.delete_all
      # Build a tournament-like state where slot 1 is the only undecided game
      OutcomeRanking.send(:leaf_nodes, slots) do |t_decision_team_slots|
        OutcomeRanking.send(:process_leaf, t_decision_team_slots, Bracket.all)
      end

      assert OutcomeRanking.count > 0
    end

    test "mid-scale — correct at 256 outcomes" do
      tournament = Tournament.field_64
      tournament.update!(game_decisions: 0, game_mask: 0)
      result = Scenarios::Generators::TournamentGenerator.new(55, seed: Minitest.seed).call
      result.apply_to(tournament)
      OutcomeRanking.delete_all

      OutcomeRanking.populate(tournament)

      assert_equal 256, OutcomeRanking.distinct.count(:game_decisions)

      best_finishes = OutcomeRanking.group(:bracket_id).minimum(:rank)

      Bracket.find_each do |bracket|
        expected = best_finishes[bracket.id] || 6
        assert expected.between?(1, 6),
          "Mid-scale — Bracket #{bracket.id}: best_finish=#{expected}"
      end
    end
  end
end
