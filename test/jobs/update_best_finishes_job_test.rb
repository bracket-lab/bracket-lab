require "test_helper"

class UpdateBestFinishesJobTest < ActiveJob::TestCase
  setup do
    set_tournament_state(:final_four)
    @tournament = Tournament.field_64
    OutcomeRanking.delete_all
  end

  test "does nothing when start_eliminating? is false" do
    set_tournament_state(:some_games) # 10 games played, 53 remaining
    UpdateBestFinishesJob.perform_now

    assert_equal 0, OutcomeRanking.count
  end

  test "populates outcome_rankings on first run" do
    UpdateBestFinishesJob.perform_now

    remaining = @tournament.num_games_remaining
    expected_scenarios = 2**remaining
    distinct_outcomes = OutcomeRanking.distinct.count(:game_decisions)
    assert_equal expected_scenarios, distinct_outcomes
    assert OutcomeRanking.count > 0
  end

  test "sets outcomes_calculated after populate" do
    assert_not @tournament.outcomes_calculated?

    UpdateBestFinishesJob.perform_now

    assert @tournament.reload.outcomes_calculated?
  end

  test "best_finish derivable from outcome_rankings after populate" do
    UpdateBestFinishesJob.perform_now

    best_finishes = OutcomeRanking.group(:bracket_id).minimum(:rank)

    Bracket.find_each do |bracket|
      expected = best_finishes[bracket.id] || 6
      assert expected.between?(1, 6),
        "Bracket #{bracket.id}: best_finish=#{expected} should be between 1 and 6"
    end
  end

  test "prunes outcome_rankings on subsequent run" do
    UpdateBestFinishesJob.perform_now
    initial_count = OutcomeRanking.count

    # Slot 2 is the first Final Four game (unplayed after :final_four state)
    @tournament.update_game!(2, 0)
    UpdateBestFinishesJob.perform_now

    assert OutcomeRanking.count < initial_count,
      "Should decrease (was #{initial_count}, now #{OutcomeRanking.count})"
  end

  test "touches a surviving row after prune so cache invalidates" do
    UpdateBestFinishesJob.perform_now
    max_before = OutcomeRanking.maximum(:updated_at)

    travel 1.second do
      @tournament.update_game!(2, 0)
      UpdateBestFinishesJob.perform_now
    end

    max_after = OutcomeRanking.maximum(:updated_at)
    assert max_after > max_before,
      "OutcomeRanking.maximum(:updated_at) should advance after prune"
  end

  test "leaves outcomes_calculated true after prune" do
    UpdateBestFinishesJob.perform_now
    assert @tournament.reload.outcomes_calculated?

    @tournament.update_game!(2, 0)
    UpdateBestFinishesJob.perform_now

    assert @tournament.reload.outcomes_calculated?
  end

  test "idempotent — running twice without game changes" do
    UpdateBestFinishesJob.perform_now
    count_after_first = OutcomeRanking.count

    UpdateBestFinishesJob.perform_now
    assert_equal count_after_first, OutcomeRanking.count
  end

  test "mid-scale — correct at 256 outcomes" do
    # 55 games played = 8 remaining = 256 outcomes
    tournament = Tournament.field_64
    tournament.update!(game_decisions: 0, game_mask: 0)
    result = Scenarios::Generators::TournamentGenerator.new(55, seed: Minitest.seed).call
    result.apply_to(tournament)
    OutcomeRanking.delete_all

    UpdateBestFinishesJob.perform_now

    assert_equal 256, OutcomeRanking.distinct.count(:game_decisions)

    best_finishes = OutcomeRanking.group(:bracket_id).minimum(:rank)

    Bracket.find_each do |bracket|
      expected = best_finishes[bracket.id] || 6
      assert expected.between?(1, 6),
        "Mid-scale — Bracket #{bracket.id}: best_finish=#{expected}"
    end
  end
end
