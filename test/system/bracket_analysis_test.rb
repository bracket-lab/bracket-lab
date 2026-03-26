require "application_system_test_case"

class BracketAnalysisTest < ApplicationSystemTestCase
  setup do
    @user = users(:user)
    set_tournament_state(:final_four)
    @tournament = Tournament.field_64
    OutcomeRanking.delete_all
    UpdateBestFinishesJob.perform_now
    Current.tournament = @tournament
  end

  test "analysis page shows finish distribution" do
    bracket = brackets(:one)
    sign_in_as(@user)
    visit bracket_analysis_path(bracket)

    assert_text "Analysis"
    assert_text "scenarios remaining"
    assert_selector "canvas"
    assert_text "1st"
    assert_text "6th+"
  end

  test "analysis page shows game impact cards" do
    bracket = brackets(:one)
    sign_in_as(@user)
    visit bracket_analysis_path(bracket)

    assert_text "If"
    assert_text "wins"
  end

  test "bracket show page links to analysis" do
    bracket = brackets(:one)
    sign_in_as(@user)
    visit bracket_path(bracket)

    assert_link "Analysis"
    click_link "Analysis"

    assert_text "Analysis"
    assert_text "scenarios remaining"
  end

  test "analysis page redirects when not eliminating" do
    set_tournament_state(:some_games)
    Tournament.field_64.update!(outcomes_calculated: false)
    bracket = brackets(:one)
    sign_in_as(@user)
    visit bracket_analysis_path(bracket)

    assert_no_text "scenarios remaining"
  end
end
