# frozen_string_literal: true

require "test_helper"

class TournamentStateTest < ActiveSupport::TestCase
  test "set_tournament_state(:pre_selection) sets pre_selection" do
    set_tournament_state(:pre_selection)
    tournament = Tournament.field_64

    assert tournament.pre_selection?
    assert_equal 0, tournament.num_games_played
  end

  test "set_tournament_state(:pre_tipoff) sets not_started" do
    set_tournament_state(:pre_tipoff)
    tournament = Tournament.field_64

    assert tournament.not_started?
    assert_equal 0, tournament.num_games_played
  end

  test "set_tournament_state(:tipoff) sets in_progress with no games" do
    set_tournament_state(:tipoff)
    tournament = Tournament.field_64

    assert tournament.in_progress?
    assert_equal 0, tournament.num_games_played
  end

  test "set_tournament_state(:some_games) produces 10 games" do
    set_tournament_state(:some_games)
    tournament = Tournament.field_64

    assert tournament.in_progress?
    assert_equal 10, tournament.num_games_played
  end

  test "set_tournament_state(:first_weekend) produces 48 games" do
    set_tournament_state(:first_weekend)
    tournament = Tournament.field_64

    assert tournament.in_progress?
    assert_equal 48, tournament.num_games_played
  end

  test "set_tournament_state(:mid_tournament) produces 50 games with gap slots" do
    set_tournament_state(:mid_tournament)
    tournament = Tournament.field_64

    assert tournament.in_progress?
    assert_equal 50, tournament.num_games_played
  end

  test "set_tournament_state(:final_four) produces 60 games" do
    set_tournament_state(:final_four)
    tournament = Tournament.field_64

    assert tournament.in_progress?
    assert_equal 60, tournament.num_games_played
  end

  test "set_tournament_state(:completed) produces 63 games and completed state" do
    set_tournament_state(:completed)
    tournament = Tournament.field_64

    assert tournament.completed?
    assert_equal 63, tournament.num_games_played
  end

  test "results are deterministic for same Minitest.seed" do
    set_tournament_state(:some_games)
    decisions1 = Tournament.field_64.game_decisions

    # Reset and re-apply — same seed should yield same result
    Tournament.field_64.update!(game_decisions: 0, game_mask: 0)
    set_tournament_state(:some_games)
    decisions2 = Tournament.field_64.game_decisions

    assert_equal decisions1, decisions2
  end
end
