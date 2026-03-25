# frozen_string_literal: true

require "test_helper"

class Scenarios::Generators::BracketGeneratorTest < ActiveSupport::TestCase
  test "returns an integer" do
    result = Scenarios::Generators::BracketGenerator.new(:balanced, seed: 42).call
    assert_kind_of Integer, result
  end

  test "produces deterministic results with same seed" do
    result1 = Scenarios::Generators::BracketGenerator.new(:balanced, seed: 42).call
    result2 = Scenarios::Generators::BracketGenerator.new(:balanced, seed: 42).call

    assert_equal result1, result2
  end

  test "produces different results with different seeds" do
    result1 = Scenarios::Generators::BracketGenerator.new(:balanced, seed: 1).call
    result2 = Scenarios::Generators::BracketGenerator.new(:balanced, seed: 2).call

    refute_equal result1, result2
  end

  test "different styles produce different results with same seed" do
    chalk = Scenarios::Generators::BracketGenerator.new(:chalk, seed: 42).call
    upset = Scenarios::Generators::BracketGenerator.new(:upset, seed: 42).call

    refute_equal chalk, upset
  end

  test "works without seed (backward compatible)" do
    result = Scenarios::Generators::BracketGenerator.new(:balanced).call
    assert_kind_of Integer, result
  end
end
