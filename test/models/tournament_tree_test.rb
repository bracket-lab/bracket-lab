require "test_helper"

class TournamentTreeTest < ActiveSupport::TestCase
  setup do
    @tournament = Tournament.field_64
    @tree = TournamentTree.new(@tournament)
  end

  test "initialization with tournament" do
    assert_equal @tournament, @tree.tournament
    assert_equal @tournament.num_rounds, @tree.depth
    assert_instance_of Game, @tree.championship
  end

  test "initialization with depth" do
    tree = TournamentTree.new(6)
    assert_equal 6, tree.depth
    assert_instance_of Game, tree.championship
  end

  test "game_slots_for" do
    assert_equal [ 1 ], @tree.game_slots_for(6)  # Championship
    assert_equal [ 2, 3 ], @tree.game_slots_for(5)  # Final Four
    assert_equal [ 4, 5, 6, 7 ], @tree.game_slots_for(4)  # Elite Eight
  end

  test "round_for" do
    round = @tree.round_for(6)  # Championship
    assert_equal 1, round.size
    assert_instance_of Game, round.first

    round = @tree.round_for(5)  # Final Four
    assert_equal 2, round.size
    assert round.all? { |game| game.is_a?(Game) }
  end

  test "complete? and incomplete?" do
    assert @tree.incomplete?
    refute @tree.complete?

    # Set all games to have decisions
    (1...@tree.size).each do |position|
      @tree.update_game(position, 0)
    end

    assert @tree.complete?
    refute @tree.incomplete?
  end

  test "marshalling" do
    # Set some game decisions
    @tree.update_game(1, 0)
    @tree.update_game(2, 1)
    @tree.update_game(3, 0)

    marshalled = @tree.marshal
    unmarshalled = TournamentTree.unmarshal(@tournament, marshalled.decisions, marshalled.mask)

    assert_equal @tree, unmarshalled
  end
end
