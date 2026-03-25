# frozen_string_literal: true

require "test_helper"

class Scenarios::Generators::GameOutcomeTest < ActiveSupport::TestCase
  test "returns boolean" do
    result = Scenarios::Generators::GameOutcome.higher_seed_wins?(1, 16)
    assert_includes [ true, false ], result
  end

  test "produces deterministic results with seeded rng" do
    rng1 = Random.new(42)
    rng2 = Random.new(42)
    results1 = 10.times.map { Scenarios::Generators::GameOutcome.higher_seed_wins?(1, 16, rng: rng1) }
    results2 = 10.times.map { Scenarios::Generators::GameOutcome.higher_seed_wins?(1, 16, rng: rng2) }

    assert_equal results1, results2, "Same seed should produce same sequence"
  end

  test "produces different results with different seeds" do
    rng1 = Random.new(1)
    rng2 = Random.new(2)
    results1 = 100.times.map { Scenarios::Generators::GameOutcome.higher_seed_wins?(8, 9, rng: rng1) }
    results2 = 100.times.map { Scenarios::Generators::GameOutcome.higher_seed_wins?(8, 9, rng: rng2) }

    refute_equal results1, results2
  end

  test "works without rng argument (backward compatible)" do
    result = Scenarios::Generators::GameOutcome.higher_seed_wins?(1, 16)
    assert_includes [ true, false ], result
  end
end
