require "test_helper"

class TeamTest < ActiveSupport::TestCase
  def setup
    @tournament = Tournament.field_64
  end

  test "region names are normalized to keys" do
    Team.region_names.each do |region_name|
      assert region_name.is_a?(Symbol)
    end
  end

  test "always ordered by starting slot" do
    starting_slots = Team.all.pluck(:starting_slot)
    exp = (64...128).to_a

    assert_equal exp, starting_slots
  end

  test "max name length is 15" do
    team = teams(:team_64)
    team.name = "longer than 15 name"
    assert_not team.valid?
  end

  test "first game the team plays" do
    game = @tournament.round_for(1).sample
    assert_equal game.slot, game.team_one.first_game.slot
    assert_equal game.slot, game.team_two.first_game.slot
  end

  test "#still_playing? / #eliminated?" do
    game = @tournament.round_for(1).first
    team = game.first_team
    assert team.still_playing?
    assert_not team.eliminated?

    # winning first game
    @tournament.update_game!(game.slot, 0)
    game = @tournament.round_for(1).first
    team = game.first_team
    assert team.still_playing?
    assert_not team.eliminated?

    # winning next game
    @tournament.update_game!(game.parent.slot, 0)
    game = @tournament.round_for(1).first
    team = game.first_team
    assert team.still_playing?
    assert_not team.eliminated?

    # losing next game
    # @tournament.update_game!(game.parent.slot, 1)
    # game = @tournament.round_for(1).first
    # team = game.first_team
    # assert_not team.still_playing?
    # assert team.eliminated?
  end
  #
  #       context 'won the championship' do
  #         let(:tournament) { tournament_completed }
  #         subject { tournament.championship.team }
  #
  #         it 'is true' do
  #           expect(subject).to_not be_eliminated
  #           expect(subject).to be_still_playing
  #         end
  #       end
  #     end
  #
  #     context 'lost the first game' do
  #       subject { game.first_team }
  #
  #       before do
  #         tournament.update_game(game.slot, 1)
  #         allow(Tournament).to receive(:field_64) { tournament }
  #       end
  #
  #       it 'is false' do
  #         expect(subject).to_not be_still_playing
  #         expect(subject).to be_eliminated
  #       end
  #     end
  #   end
end
