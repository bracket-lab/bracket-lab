require "application_system_test_case"

class TournamentDisplayTest < ApplicationSystemTestCase
  setup do
    @user = users(:user)
  end

  test "game_results page renders tournament without React" do
    set_tournament_state(:tipoff)

    sign_in_as(@user)
    visit game_results_path

    # Tournament structure should be present
    assert_selector ".tournament-component"
    assert_selector ".tournament-body"
    assert_selector ".rounds-banner"

    # Region labels should be visible
    assert_selector ".region-label", text: "SOUTH"

    # Championship section
    assert_selector ".champion-label", text: "CHAMPION"
  end

  test "bracket show page renders with pick styling classes available" do
    set_tournament_state(:pre_tipoff)

    bracket = brackets(:complete_bracket)
    sign_in_as(bracket.user)
    visit bracket_path(bracket)

    # Tournament structure should be present
    assert_selector ".tournament-component"
    assert_selector ".tournament-body"

    # Slots should be rendered
    assert_selector ".slot"
  end

  test "bracket new page still uses React (interactive)" do
    set_tournament_state(:pre_tipoff)

    sign_in_as(@user)
    visit new_bracket_path

    # React-specific behavior: clicking should work
    assert_selector ".tournament-component"

    # Hidden form field present (React form integration)
    assert_selector "input[name='bracket[game_decisions]']", visible: false
  end

  test "bracket show page renders slots with seed and team name" do
    bracket = brackets(:complete_bracket)
    sign_in_as(bracket.user)
    visit bracket_path(bracket)

    # Verify slots contain team data
    assert_selector ".slot .seed"
    assert_selector ".slot", text: /\d+\s+\w+/  # seed followed by team name
  end

  test "game_results page does not use React component" do
    set_tournament_state(:tipoff)

    sign_in_as(@user)
    visit game_results_path

    # ERB rendering should not have React data attributes
    assert_no_selector "[data-react-class='Tournament']"
  end

  test "championship section renders with champion-box" do
    bracket = brackets(:complete_bracket)
    sign_in_as(bracket.user)
    visit bracket_path(bracket)

    assert_selector ".championship"
    assert_selector ".champion-box"
    assert_selector ".champion-label", text: "CHAMPION"
  end
end
