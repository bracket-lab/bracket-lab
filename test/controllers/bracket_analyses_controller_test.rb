require "test_helper"

class BracketAnalysesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user)
    @bracket = brackets(:one)
  end

  test "redirects to sign in when not authenticated" do
    set_tournament_state(:final_four)
    tournament = Tournament.field_64
    tournament.update!(outcomes_calculated: true)
    get bracket_analysis_url(@bracket)
    assert_response :redirect
  end

  test "redirects to bracket when display_eliminations is false" do
    sign_in_as @user
    set_tournament_state(:some_games)
    get bracket_analysis_url(@bracket)
    assert_redirected_to bracket_path(@bracket)
  end

  test "shows analysis page when display_eliminations is true" do
    sign_in_as @user
    set_tournament_state(:final_four)
    tournament = Tournament.field_64
    tournament.update!(outcomes_calculated: true)
    OutcomeRanking.delete_all
    UpdateBestFinishesJob.perform_now
    get bracket_analysis_url(@bracket)
    assert_response :success
  end

  test "any authenticated user can view any bracket analysis" do
    other_user = users(:john)
    sign_in_as other_user
    set_tournament_state(:final_four)
    tournament = Tournament.field_64
    tournament.update!(outcomes_calculated: true)
    OutcomeRanking.delete_all
    UpdateBestFinishesJob.perform_now
    get bracket_analysis_url(@bracket)
    assert_response :success
  end

  test "renders successfully even for eliminated bracket" do
    sign_in_as @user
    set_tournament_state(:final_four)
    tournament = Tournament.field_64
    tournament.update!(outcomes_calculated: true)
    OutcomeRanking.delete_all
    UpdateBestFinishesJob.perform_now
    get bracket_analysis_url(@bracket)
    assert_response :success
  end
end
