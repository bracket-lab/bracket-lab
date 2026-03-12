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

  test "placeholder_name_for generates region and seed name" do
    # Slot 64 = South region (index 0), seed 1
    assert_equal "South 1", Team.placeholder_name_for(64)
    # Slot 65 = South region (index 0), seed 16
    assert_equal "South 16", Team.placeholder_name_for(65)
    # Slot 80 = West region (index 1), seed 1
    assert_equal "West 1", Team.placeholder_name_for(80)
    # Slot 96 = East region (index 2), seed 1
    assert_equal "East 1", Team.placeholder_name_for(96)
    # Slot 112 = Midwest region (index 3), seed 1
    assert_equal "Midwest 1", Team.placeholder_name_for(112)
  end

  test "name must be unique" do
    existing_team = teams(:team_64)
    new_team = Team.new(
      starting_slot: 999,
      name: existing_team.name,
      seed: 1,
      region: :south
    )
    assert_not new_team.valid?
    assert_includes new_team.errors[:name], "has already been taken"
  end

  test "idempotent seeding does not duplicate teams" do
    initial_count = Team.count
    # Run seeding logic a second time (teams already exist from fixtures)
    64.times do |i|
      starting_slot = i + 64
      seed = Team.seed_for_slot(starting_slot)
      region = i / 16

      Team.find_or_create_by!(starting_slot: starting_slot) do |team|
        team.name = Team.placeholder_name_for(starting_slot)
        team.seed = seed
        team.region = region
      end
    end
    assert_equal initial_count, Team.count
  end
end
