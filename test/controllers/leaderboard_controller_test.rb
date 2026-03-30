require "test_helper"

class LeaderboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:user)
  end

  test "redirects to brackets when tournament has not started" do
    set_tournament_state(:pre_tipoff)
    get leaderboard_url
    assert_redirected_to brackets_path
  end

  test "renders leaderboard when tournament is in progress" do
    set_tournament_state(:some_games)
    get leaderboard_url
    assert_response :success
  end

  test "renders leaderboard when outcomes are calculated" do
    set_tournament_state(:final_four)
    OutcomeRanking.populate
    get leaderboard_url
    assert_response :success
  end
end
