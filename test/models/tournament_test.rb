require "test_helper"

class TournamentTest < ActiveSupport::TestCase
  def setup
    Tournament.delete_all # Ensure we start fresh
    @tournament = Tournament.field_64
    @tip_off = Tournament::TIP_OFF
  end

  test "field_64 ensures singleton" do
    tournament2 = Tournament.field_64
    assert_equal @tournament.id, tournament2.id
    assert_equal 1, Tournament.count
  end

  test "state transitions maintain singleton" do
    @tournament.set_teams!
    assert @tournament.not_started?
    assert_equal 1, Tournament.count

    @tournament.start!
    assert @tournament.in_progress?
    assert_equal 1, Tournament.count

    @tournament.completed!
    assert @tournament.completed?
    assert_equal 1, Tournament.count
  end

  test "selection sunday calculation" do
    sunday = @tip_off.beginning_of_week(:sunday)
    expected = sunday.change(hour: 22, min: 0, sec: 0)
    assert_equal expected, @tournament.selection_sunday
  end

  test "selection in progress" do
    travel_to(@tournament.selection_sunday + 1.hour) do
      assert @tournament.selection_in_progress?
    end

    travel_to(@tournament.selection_sunday - 1.hour) do
      refute @tournament.selection_in_progress?
    end
  end

  test "tournament status checks" do
    @tournament.set_teams! # Need to set teams first
    assert @tournament.set?
    refute @tournament.started?
    refute @tournament.finished?

    @tournament.update!(game_mask: (2**63 - 1) << 1)
    assert @tournament.finished?
  end

  test "derived game counts" do
    assert_equal 63, @tournament.num_games # 2^6 - 1 for 6 rounds
    assert_equal 0, @tournament.num_games_played
    assert_equal 63, @tournament.num_games_remaining
  end

  test "championship game slot" do
    expected_game = @tournament.tree.at(1)
    assert_equal expected_game.slot, @tournament.championship.slot
  end

  test "round_for calculations" do
    exp_games = [ 1, 8, 5, 4, 6, 3, 7, 2 ].map do |seed|
      Team.where(region: 2).find_by!(seed:).first_game
    end

    assert_equal exp_games.map(&:slot), @tournament.round_for(1, 2).map(&:slot)
  end

  test "round_for games in semi-final games" do
    exp = [ @tournament.championship.game_one.slot, @tournament.championship.game_two.slot ]
    assert_equal exp, @tournament.round_for(5).map(&:slot)
  end

  test "round_for final game" do
    assert_equal [ @tournament.championship.slot ], @tournament.round_for(6).map(&:slot)
  end

  test "round_for other rounds" do
    (2..4).each do |round|
      exp_games = @tournament.round_for(round - 1, 3).map(&:next_game).uniq
      assert_equal exp_games.map(&:slot), @tournament.round_for(round, 3).map(&:slot)
    end
  end

  test "list of all games in the tournament" do
    games = @tournament.games

    assert_equal @tournament.num_games, games.size
    assert_equal (1..@tournament.num_games).to_a, games.map(&:slot)
    assert_equal 1, games.map(&:tree).uniq.size
  end

  test "updating_a_game maintains tree consistency" do
    team = Team.first
    game = team.first_game

    @tournament.update_game!(game.slot, 0)
    assert_equal 1, @tournament.num_games_played
    assert_equal team, @tournament.tree.at(game.slot).team

    @tournament.update_game(game.parent.slot, 1)
    assert_equal 2, @tournament.num_games_played

    @tournament.reload
    assert_equal 1, @tournament.num_games_played
  end

  test "clearing_a_game maintains tree consistency" do
    team = Team.first
    game = team.first_game
    parent_game = game.parent

    @tournament.update_game!(game.slot, 0)
    @tournament.update_game!(parent_game.slot, 1)
    assert_equal 2, @tournament.num_games_played

    @tournament.clear_game(game.slot)
    assert_equal 0, @tournament.num_games_played
    assert_nil @tournament.tree.at(game.slot).team
    assert_nil @tournament.tree.at(parent_game.slot).team
  end

  test "round name date pairs" do
    pairs = @tournament.round_name_date_pairs
    assert_equal Tournament::NUM_ROUNDS, pairs.size

    first_round = pairs.first
    assert_equal "Field 64", first_round.first # Match Round::NAMES
    assert_match(/Mar \d+\-\d+/, first_round.last)
  end

  test "game decisions bit operations" do
    # Update database column directly to avoid getter/setter overrides
    @tournament.update_column(:game_decisions, 1)
    assert_equal 2, @tournament.game_decisions # Left shift by 1

    @tournament.update_column(:game_decisions, 2)
    assert_equal 4, @tournament.game_decisions # Left shift by 1
  end

  test "game mask bit operations" do
    # Update database column directly to avoid getter/setter overrides
    @tournament.update_column(:game_mask, 1)
    assert_equal 2, @tournament.game_mask # Left shift by 1

    @tournament.update_column(:game_mask, 2)
    assert_equal 4, @tournament.game_mask # Left shift by 1
  end

  test "start eliminating check" do
    refute @tournament.start_eliminating?

    # Set up a tournament with 15 games remaining
    mask = (2**63 - 1) << 1
    mask &= ~(1 << 16) # Clear one game to make it 15 remaining
    @tournament.update!(game_mask: mask)

    assert @tournament.start_eliminating?
  end

  test "games_hash provides complete game data" do
    team = Team.first
    game = team.first_game
    @tournament.update_game!(game.slot, 0)

    game_data = @tournament.games_hash.find { |g| g[:slot] == game.slot }
    assert_equal team.id, game_data[:winningTeam][:id]
    assert_equal team.seed, game_data[:winningTeam][:seed]
    assert_equal team.name, game_data[:winningTeam][:name]
    assert_equal 0, game_data[:choice]
  end

  test "region_labels defaults to standard order" do
    assert_equal [ "South", "West", "East", "Midwest" ], @tournament.region_labels
  end

  test "region_labels accepts any permutation" do
    @tournament.region_labels = [ "East", "West", "South", "Midwest" ]
    assert @tournament.valid?
  end

  test "region_labels rejects duplicates" do
    @tournament.region_labels = [ "South", "South", "East", "Midwest" ]
    assert_not @tournament.valid?
    assert_includes @tournament.errors[:region_labels], "must be a permutation of the four region names"
  end

  test "region_labels rejects missing values" do
    @tournament.region_labels = [ "South", "West", "East" ]
    assert_not @tournament.valid?
    assert_includes @tournament.errors[:region_labels], "must be a permutation of the four region names"
  end

  test "region_labels rejects extra values" do
    @tournament.region_labels = [ "South", "West", "East", "Midwest", "North" ]
    assert_not @tournament.valid?
    assert_includes @tournament.errors[:region_labels], "must be a permutation of the four region names"
  end

  test "region_labels rejects non-standard names" do
    @tournament.region_labels = [ "South", "West", "East", "North" ]
    assert_not @tournament.valid?
    assert_includes @tournament.errors[:region_labels], "must be a permutation of the four region names"
  end
end
