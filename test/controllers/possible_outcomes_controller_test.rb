require "test_helper"

class PossibleOutcomesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:user)
  end

  test "redirects when too many games remaining" do
    set_tournament_state(:some_games)
    get possible_outcomes_url
    assert_redirected_to root_path
  end

  test "renders index when final four with outcomes calculated" do
    set_tournament_state(:final_four)
    OutcomeRanking.populate

    get possible_outcomes_url
    assert_response :success
  end

  test "displays correct number of outcomes" do
    set_tournament_state(:final_four)
    OutcomeRanking.populate
    tournament = Tournament.field_64
    expected_outcomes = 2**tournament.num_games_remaining

    get possible_outcomes_url
    assert_response :success
    assert_select "h2", count: expected_outcomes
  end

  test "each outcome shows ranked brackets" do
    set_tournament_state(:final_four)
    OutcomeRanking.populate

    get possible_outcomes_url
    assert_response :success
    assert_select ".list-row"
  end
end
