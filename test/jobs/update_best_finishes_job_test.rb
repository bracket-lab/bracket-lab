require "test_helper"

class UpdateBestFinishesJobTest < ActiveJob::TestCase
  setup do
    set_tournament_state(:final_four)
    @tournament = Tournament.field_64
    Outcome.delete_all
  end

  test "does nothing when start_eliminating? is false" do
    set_tournament_state(:some_games) # 10 games played, 53 remaining
    UpdateBestFinishesJob.perform_now

    assert_equal 0, Outcome.count
  end

  test "populates outcomes on first run" do
    UpdateBestFinishesJob.perform_now

    remaining = @tournament.num_games_remaining
    assert_equal 2**remaining, Outcome.count
    assert OutcomeRanking.count > 0
  end

  test "sets outcomes_calculated after populate" do
    assert_not @tournament.outcomes_calculated?

    UpdateBestFinishesJob.perform_now

    assert @tournament.reload.outcomes_calculated?
  end

  test "derives PossibleResult after populate" do
    UpdateBestFinishesJob.perform_now

    Bracket.find_each do |bracket|
      pr = PossibleResult.find_by(bracket_id: bracket.id)
      assert pr.present?, "PossibleResult should exist for bracket #{bracket.id}"
      assert pr.best_finish.between?(1, 6)
    end
  end

  test "PossibleResult matches fresh Elimination computation" do
    UpdateBestFinishesJob.perform_now

    fresh = Elimination.new
    fresh.results(@tournament.decision_team_slots.dup)

    Bracket.find_each do |bracket|
      pr = PossibleResult.find_by(bracket_id: bracket.id)
      expected = fresh.acc[bracket.id]
      assert_equal expected, pr.best_finish,
        "Bracket #{bracket.id}: PossibleResult=#{pr.best_finish}, expected=#{expected}"
    end
  end

  test "prunes outcomes on subsequent run" do
    UpdateBestFinishesJob.perform_now
    initial_count = Outcome.count

    # Slot 2 is the first Final Four game (unplayed after :final_four state)
    @tournament.update_game!(2, 0)
    UpdateBestFinishesJob.perform_now

    assert Outcome.count < initial_count,
      "Should decrease (was #{initial_count}, now #{Outcome.count})"
  end

  test "cascade deletes rankings on prune" do
    UpdateBestFinishesJob.perform_now
    initial_ranking_count = OutcomeRanking.count

    @tournament.update_game!(2, 0)
    UpdateBestFinishesJob.perform_now

    assert OutcomeRanking.count < initial_ranking_count,
      "Rankings should decrease after prune"
  end

  test "PossibleResult correct after prune" do
    UpdateBestFinishesJob.perform_now

    @tournament.update_game!(2, 0)
    UpdateBestFinishesJob.perform_now

    fresh = Elimination.new
    fresh.results(@tournament.reload.decision_team_slots.dup)

    Bracket.find_each do |bracket|
      pr = PossibleResult.find_by(bracket_id: bracket.id)
      expected = fresh.acc[bracket.id]
      assert_equal expected, pr.best_finish,
        "After prune — Bracket #{bracket.id}: PossibleResult=#{pr.best_finish}, expected=#{expected}"
    end
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
    count_after_first = Outcome.count

    UpdateBestFinishesJob.perform_now
    assert_equal count_after_first, Outcome.count
  end

  test "mid-scale — correct at 256 outcomes" do
    # 55 games played = 8 remaining = 256 outcomes
    # Unplayed slots: [1, 2, 3, 4, 5, 6, 7, 15]
    tournament = Tournament.field_64
    tournament.update!(game_decisions: 0, game_mask: 0)
    result = Scenarios::Generators::TournamentGenerator.new(55, seed: Minitest.seed).call
    result.apply_to(tournament)
    Outcome.delete_all

    UpdateBestFinishesJob.perform_now

    assert_equal 256, Outcome.count

    fresh = Elimination.new
    fresh.results(tournament.reload.decision_team_slots.dup)

    Bracket.find_each do |bracket|
      pr = PossibleResult.find_by(bracket_id: bracket.id)
      expected = fresh.acc[bracket.id]
      assert_equal expected, pr.best_finish,
        "Mid-scale — Bracket #{bracket.id}: PossibleResult=#{pr.best_finish}, expected=#{expected}"
    end
  end
end
