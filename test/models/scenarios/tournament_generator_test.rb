# frozen_string_literal: true

require "test_helper"

class Scenarios::Generators::TournamentGeneratorTest < ActiveSupport::TestCase
  test "call returns a result with decisions and mask" do
    result = Scenarios::Generators::TournamentGenerator.new(10, seed: 42).call

    assert_respond_to result, :decisions
    assert_respond_to result, :mask
    assert_kind_of Integer, result.decisions
    assert_kind_of Integer, result.mask
  end

  test "produces deterministic results with same seed" do
    result1 = Scenarios::Generators::TournamentGenerator.new(10, seed: 42).call
    result2 = Scenarios::Generators::TournamentGenerator.new(10, seed: 42).call

    assert_equal result1.decisions, result2.decisions
    assert_equal result1.mask, result2.mask
  end

  test "produces different results with different seeds" do
    result1 = Scenarios::Generators::TournamentGenerator.new(32, seed: 1).call
    result2 = Scenarios::Generators::TournamentGenerator.new(32, seed: 2).call

    refute_equal result1.decisions, result2.decisions
  end

  test "mask has correct number of bits set" do
    result = Scenarios::Generators::TournamentGenerator.new(10, seed: 42).call
    bits_set = result.mask.to_s(2).count("1")

    assert_equal 10, bits_set
  end

  test "apply_to updates tournament" do
    tournament = Tournament.field_64
    result = Scenarios::Generators::TournamentGenerator.new(10, seed: 42).call
    result.apply_to(tournament)

    assert_equal 10, tournament.num_games_played
  end

  test "respects gap_slots for partial rounds" do
    result = Scenarios::Generators::TournamentGenerator.new(50, seed: 42, gap_slots: [ 10, 13 ]).call
    bits_set = result.mask.to_s(2).count("1")

    assert_equal 50, bits_set
    # Slots 10 and 13 should be set in the mask
    assert result.mask.anybits?(1 << 10)
    assert result.mask.anybits?(1 << 13)
  end

  test "works without seed (backward compatible, non-deterministic)" do
    result = Scenarios::Generators::TournamentGenerator.new(10).call

    assert_respond_to result, :decisions
    assert_respond_to result, :mask
  end
end
