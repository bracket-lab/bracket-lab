require "test_helper"

class BracketTest < ActiveSupport::TestCase
    test "bigint overflow on game_decisions" do
      valid_decisions = 11179060176282734750 # number larger than max i64 but smaller than u64
      bracket = Bracket.new(name: "Bracket", game_decisions: valid_decisions, user: users(:user))

      assert bracket.valid?, "Valid bracket had errors on validation: #{bracket.errors.full_messages}"
      assert bracket.save, "Valid bracket had errors on save: #{bracket.errors}"
    end


  test "handles game_decisions within signed 64-bit range" do
    bracket = Bracket.new(
      name: "Test Bracket",
      user: users(:user),
      game_decisions: 1_000_000
    )

    assert bracket.valid?
    assert_equal 1_000_000, bracket.game_decisions

    bracket.save!
    bracket.reload

    assert_equal 1_000_000, bracket.game_decisions
  end

  test "handles game_decisions beyond signed 64-bit range" do
    large_value = 11179060176282734750 # number larger than max i64 but smaller than u64


    bracket = Bracket.new(
      name: "Large Value Bracket",
      user: users(:user),
      game_decisions: large_value
    )

    bracket.save!
    bracket.reload

    assert_equal large_value, bracket.game_decisions
  end

  test "accepts game_decisions as a string (from form params)" do
    # HTML forms always submit values as strings. The game_decisions setter
    # must handle string input from BigInt.toString() in the React component.
    string_value = "11179060176282734750"

    bracket = Bracket.new(
      name: "String Value Bracket",
      user: users(:user),
      game_decisions: string_value
    )

    assert bracket.valid?, "Bracket with string game_decisions should be valid: #{bracket.errors.full_messages}"
    bracket.save!
    bracket.reload

    assert_equal 11179060176282734750, bracket.game_decisions
  end

  test "tree returns a TournamentTree for the bracket" do
    bracket = brackets(:complete_bracket)
    set_tournament_state(:pre_tipoff)
    Current.tournament = Tournament.field_64

    tree = bracket.tree

    assert_instance_of TournamentTree, tree
    assert_equal Current.tournament, tree.tournament
  end
end
