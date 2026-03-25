require "application_system_test_case"

class BracketPickerTest < ApplicationSystemTestCase
  setup do
    @user = users(:user)
    set_tournament_state(:pre_tipoff)
    @tournament = Tournament.field_64
    Current.tournament = @tournament
  end

  # ============================================================================
  # DOM Structure Tests - verify the React bracket picker elements are present
  # ============================================================================

  test "new bracket page has tournament component" do
    sign_in_as(@user)
    visit new_bracket_path

    # The React tournament component should be rendered
    assert_selector ".tournament-component"
    assert_selector ".tournament-body"
  end

  test "new bracket page has hidden game_decisions field" do
    sign_in_as(@user)
    visit new_bracket_path

    # Hidden form field should be present with initial value of 0
    decisions_field = find("input[name='bracket[game_decisions]']", visible: false)
    assert_equal "0", decisions_field.value
  end

  test "new bracket page has all 32 first round games" do
    sign_in_as(@user)
    visit new_bracket_path

    # Round 1 has 32 games (matches), each with 2 team slots
    assert_selector ".match.round1", count: 32
  end

  test "new bracket page has team slots for each game" do
    sign_in_as(@user)
    visit new_bracket_path

    # Each game should have two team slots (slot1 and slot2)
    assert_selector ".slot.slot1", minimum: 32
    assert_selector ".slot.slot2", minimum: 32
  end

  test "new bracket page has bracket name field" do
    sign_in_as(@user)
    visit new_bracket_path

    # Name field should be present
    assert_selector "input#bracket_name[name='bracket[name]']"
    # Submit button should be present
    assert_selector "input[type='submit'][value='Create Bracket']"
  end

  # ============================================================================
  # Edit Page Tests - verify existing bracket data loads correctly
  # ============================================================================

  test "edit bracket page loads tournament component" do
    bracket = brackets(:complete_bracket)
    sign_in_as(bracket.user)
    visit edit_bracket_path(bracket)

    # Should have the tournament component
    assert_selector ".tournament-component"
  end

  test "edit bracket page has existing bracket name" do
    bracket = brackets(:complete_bracket)
    sign_in_as(bracket.user)
    visit edit_bracket_path(bracket)

    # Name field should have the existing bracket name
    name_field = find("input#bracket_name[name='bracket[name]']")
    assert_equal bracket.name, name_field.value
  end

  test "edit bracket page has update button" do
    bracket = brackets(:complete_bracket)
    sign_in_as(bracket.user)
    visit edit_bracket_path(bracket)

    # Update button should be present
    assert_selector "input[type='submit'][value='Update Bracket']"
  end

  test "edit bracket page has hidden game_decisions with bracket value" do
    bracket = brackets(:complete_bracket)
    sign_in_as(bracket.user)
    visit edit_bracket_path(bracket)

    # Hidden field should have the bracket's game_decisions
    decisions_field = find("input[name='bracket[game_decisions]']", visible: false)
    assert_equal bracket.game_decisions.to_s, decisions_field.value
  end

  # ============================================================================
  # Team Display Tests - verify teams are rendered correctly
  # ============================================================================

  test "bracket displays team seeds" do
    sign_in_as(@user)
    visit new_bracket_path

    # Look for seed numbers in the bracket display
    # First seeds should show "1"
    assert_selector ".seed", text: "1"

    # Sixteenth seeds should show "16"
    assert_selector ".seed", text: "16"
  end

  test "bracket displays team names" do
    sign_in_as(@user)
    visit new_bracket_path

    # Look for known team names from fixtures
    # These teams should be in the bracket based on the teams.csv file
    assert_text "Auburn"
    assert_text "Duke"
    assert_text "Florida"
    assert_text "Houston"
  end

  test "bracket displays region labels" do
    sign_in_as(@user)
    visit new_bracket_path

    # Region labels should be present
    assert_selector ".region-label", text: "SOUTH"
    assert_selector ".region-label", text: "EAST"
    assert_selector ".region-label", text: "WEST"
    assert_selector ".region-label", text: "MIDWEST"
  end

  test "bracket displays championship section" do
    sign_in_as(@user)
    visit new_bracket_path

    # Championship section should be present
    assert_selector ".champion-label", text: "CHAMPION"
  end

  # ============================================================================
  # Interactive Behavior Tests - verify React handles clicks properly
  # ============================================================================

  test "team slots are clickable elements" do
    sign_in_as(@user)
    visit new_bracket_path

    # Find a team slot and click it
    slot_element = first(".slot.slot1")

    # Can click without error
    slot_element.click

    # Page should still be functional after click
    assert_selector ".tournament-component"
  end

  test "clicking team slot updates hidden field value" do
    sign_in_as(@user)
    visit new_bracket_path

    # Wait for React component to mount
    assert_selector ".tournament-component"

    # Get initial value (should be 0)
    hidden_field = find("input[name='bracket[game_decisions]']", visible: false)
    initial_value = hidden_field.value.to_i
    assert_equal 0, initial_value, "Initial game_decisions should be 0"

    # Click second team (slot2) in a game - this should set a bit
    find(".match.round1.m1.region1 .slot.slot2").click

    # Wait for React to process and re-find the field
    sleep 0.1
    hidden_field = find("input[name='bracket[game_decisions]']", visible: false)
    new_value = hidden_field.value.to_i

    assert new_value != initial_value, "Hidden field should update after pick"
  end

  test "cannot submit incomplete bracket shows error" do
    sign_in_as(@user)
    visit new_bracket_path

    # Wait for React component to mount
    assert_selector ".tournament-component"

    # Fill in the bracket name (required field)
    fill_in "bracket_name", with: "Test Incomplete Bracket"

    # Submit form - Stimulus bracket-form controller intercepts
    click_on "Create Bracket"

    # Should show client-side validation error (bracket not complete)
    assert_text "Bracket is not complete"
    # Should highlight empty picks
    assert_selector ".empty-pick"
  end

  test "submitting a complete bracket creates it successfully" do
    sign_in_as(@user)
    visit new_bracket_path

    assert_selector ".tournament-component"

    # Fill in the bracket name
    fill_in "bracket_name", with: "My New Bracket"

    # Set game_decisions to a BigInt string value via JS, matching what
    # React's gameDecisions.toString() produces when all picks are made
    page.execute_script(
      "document.querySelector('input[name=\"bracket[game_decisions]\"]').value = '11179060176282734750'"
    )

    # Submit form directly (bypasses React's onSubmit validation,
    # tests the Rails controller + model handling of string game_decisions)
    page.execute_script("document.querySelector('form').submit()")

    assert_text "Bracket was successfully created."
  end

  test "changing pick updates the bracket state" do
    sign_in_as(@user)
    visit new_bracket_path

    # Wait for React component to mount
    assert_selector ".tournament-component"

    # Click first team (slot1) in a game
    find(".match.round1.m1.region1 .slot.slot1").click
    sleep 0.1
    hidden_field = find("input[name='bracket[game_decisions]']", visible: false)
    value_after_first = hidden_field.value.to_i

    # Click second team (slot2) in same game - should change the pick
    find(".match.round1.m1.region1 .slot.slot2").click
    sleep 0.1
    hidden_field = find("input[name='bracket[game_decisions]']", visible: false)
    value_after_second = hidden_field.value.to_i

    # Values should be different - pick changed
    assert value_after_first != value_after_second,
           "Changing pick should update the hidden field value"
  end

  # ============================================================================
  # Error Handling Tests - verify validation errors are displayed correctly
  # ============================================================================

  test "server-side duplicate name error is displayed" do
    sign_in_as(@user)
    visit new_bracket_path

    assert_selector ".tournament-component"

    # Use a name that already exists in fixtures
    fill_in "bracket_name", with: "Complete Bracket"

    # Bypass client-side validation by setting game_decisions and mask via JS
    page.execute_script(<<~JS)
      document.querySelector('input[name="bracket[game_decisions]"]').value = '11179060176282734750';
      document.querySelector('[data-bracket-form-target="gameMask"]').value = '18446744073709551614';
    JS
    page.execute_script("document.querySelector('form').submit()")

    # Server re-renders with validation error
    assert_text "has already been taken"
    # Page should still have the tournament component (form was re-rendered)
    assert_selector ".tournament-component"
  end

  test "game_decisions are preserved after server-side validation error" do
    sign_in_as(@user)
    visit new_bracket_path

    assert_selector ".tournament-component"

    game_decisions_value = "11179060176282734750"

    # Set a name that already exists and bypass client-side validation
    fill_in "bracket_name", with: "Complete Bracket"
    page.execute_script(<<~JS)
      document.querySelector('input[name="bracket[game_decisions]"]').value = '#{game_decisions_value}';
      document.querySelector('[data-bracket-form-target="gameMask"]').value = '18446744073709551614';
    JS
    page.execute_script("document.querySelector('form').submit()")

    # After server re-render, the hidden field should retain the submitted value
    assert_selector ".tournament-component"
    decisions_field = find("input[name='bracket[game_decisions]']", visible: false)
    assert_equal game_decisions_value, decisions_field.value,
                 "game_decisions should be preserved after server-side validation error"
  end

  test "server-side error on edit displays validation message" do
    bracket = brackets(:complete_bracket)
    # Create another bracket with a known name to cause a uniqueness conflict
    existing_name = brackets(:one).name
    sign_in_as(bracket.user)
    visit edit_bracket_path(bracket)

    assert_selector ".tournament-component"

    # Change name to conflict with existing bracket
    fill_in "bracket_name", with: existing_name

    # Submit form directly to bypass client-side validation
    page.execute_script("document.querySelector('form').submit()")

    # Server re-renders edit page with validation error
    assert_text "has already been taken"
    assert_selector ".tournament-component"
  end

  test "picks are not reset when bracket name is taken on create" do
    sign_in_as(@user)
    visit new_bracket_path

    assert_selector ".tournament-component"

    # Make a real pick by clicking a team slot
    find(".match.round1.m1.region1 .slot.slot2").click
    sleep 0.1

    # Capture the game_decisions value produced by the real click
    decisions_after_click = find("input[name='bracket[game_decisions]']", visible: false).value
    assert_not_equal "0", decisions_after_click, "Click should have changed game_decisions"

    # Use a name that already exists in fixtures
    fill_in "bracket_name", with: "Complete Bracket"

    # Bypass client-side completeness check and submit
    page.execute_script(<<~JS)
      document.querySelector('[data-bracket-form-target="gameMask"]').value = '18446744073709551614';
    JS
    page.execute_script("document.querySelector('form').submit()")

    # Server re-renders with validation error
    assert_text "has already been taken"

    # The hidden field should retain the pick we made
    preserved_decisions = find("input[name='bracket[game_decisions]']", visible: false).value
    assert_equal decisions_after_click, preserved_decisions,
                 "Picks should be preserved after duplicate name error"

    # The React picker data attributes should reflect preserved picks
    picker = find("[data-controller='bracket-picker']", visible: :all)
    assert_equal decisions_after_click, picker[:"data-bracket-picker-game-decisions-value"],
                 "Picker game_decisions data attribute should reflect preserved picks"

    # The gameMask must be non-zero so React renders slots as selected
    assert_equal Bracket::FULL_BRACKET_MASK.to_s,
                 picker[:"data-bracket-picker-game-mask-value"],
                 "Picker gameMask should be FULL_BRACKET_MASK so picks display as selected"
  end

  test "filled bracket with duplicate name shows error and preserves picks" do
    admin = users(:admin_user)
    sign_in_as(admin)
    visit new_bracket_path

    assert_selector ".tournament-component"

    # Make a pick so game_decisions is nonzero, then fill the rest
    find(".match.round1.m1.region1 .slot.slot2").click
    sleep 0.1
    find("div", text: "Fill all picks", exact_text: true).click
    sleep 0.1

    # Verify bracket is fully filled — no empty picks should exist
    assert_no_selector ".empty-pick"

    # Verify all 63 games have been decided: gameMask should equal COMPLETED_MASK
    hidden_mask = find("input[data-bracket-form-target='gameMask']", visible: false)
    assert_equal Bracket::FULL_BRACKET_MASK.to_s, hidden_mask.value,
                 "gameMask should be FULL_BRACKET_MASK after Fill all picks"

    # Verify a champion is shown
    assert_selector ".champion-box:not(:empty)"

    # Remember the game_decisions value for comparison after error
    decisions_before = find("input[name='bracket[game_decisions]']", visible: false).value
    assert_not_equal "0", decisions_before

    # Use a name that already exists in fixtures
    fill_in "bracket_name", with: "Complete Bracket"

    # Submit — should pass client-side validation (bracket is complete)
    # but fail server-side (duplicate name)
    click_on "Create Bracket"

    # Server re-renders with validation error
    assert_text "has already been taken"

    # Bracket should still be fully filled after re-render
    assert_selector ".tournament-component"
    assert_no_selector ".empty-pick"

    # Champion should still be displayed
    assert_selector ".champion-box:not(:empty)"

    # game_decisions should match what was submitted
    decisions_field = find("input[name='bracket[game_decisions]']", visible: false)
    assert_equal decisions_before, decisions_field.value,
                 "game_decisions should be preserved after duplicate name error"

    picker = find("[data-controller='bracket-picker']", visible: :all)
    assert_equal decisions_before, picker[:"data-bracket-picker-game-decisions-value"],
                 "Picker game_decisions data attribute should match submitted value"
    assert_equal Bracket::FULL_BRACKET_MASK.to_s,
                 picker[:"data-bracket-picker-game-mask-value"],
                 "Picker gameMask should be FULL_BRACKET_MASK after error"
  end

  test "incomplete bracket error does not accumulate on repeated clicks" do
    sign_in_as(@user)
    visit new_bracket_path

    assert_selector ".tournament-component"

    fill_in "bracket_name", with: "Test Bracket"

    # Click submit multiple times
    click_on "Create Bracket"
    assert_text "Bracket is not complete"

    click_on "Create Bracket"

    # Should only have one error toast, not two
    assert_selector "#bracket-form-error", count: 1
  end
end
