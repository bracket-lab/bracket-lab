require "test_helper"

class TournamentHelperTest < ActionView::TestCase
  setup do
    set_tournament_state(:pre_tipoff)
    @tournament = Tournament.field_64
    Current.tournament = @tournament
  end

  test "pick_class_for returns empty string when team is nil" do
    assert_equal "", pick_class_for(nil, nil, round_one: false)
  end

  test "pick_class_for returns empty string for round one" do
    team = Team.first
    assert_equal "", pick_class_for(team, nil, round_one: true)
  end

  test "pick_class_for returns empty string when team still playing and no game result" do
    # Team is still playing (no games decided yet in tournament)
    team = Team.first
    assert team.still_playing?, "Team should be still playing in fresh tournament"
    assert_equal "", pick_class_for(team, nil, round_one: false)
  end

  test "pick_class_for returns correct-pick when pick matches game result" do
    # When game_team is provided and matches team, it should return correct-pick
    # This is regardless of still_playing? status since game_team is not nil
    team = Team.first
    assert_equal "correct-pick", pick_class_for(team, team, round_one: false)
  end

  test "pick_class_for returns eliminated when pick does not match" do
    # When game_team is provided but doesn't match team, it should return eliminated
    team1 = Team.first
    team2 = Team.second
    assert_equal "eliminated", pick_class_for(team1, team2, round_one: false)
  end

  test "pick_class_for returns eliminated when team not still playing and no game result" do
    # Create a mock team object that is not still playing
    mock_team = Struct.new(:name, :still_playing?).new("Test Team", false)
    assert_equal "eliminated", pick_class_for(mock_team, nil, round_one: false)
  end
end
