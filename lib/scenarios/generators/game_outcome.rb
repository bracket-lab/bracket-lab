# frozen_string_literal: true

module Scenarios
  module Generators
    # Weighted coin flip for realistic game outcomes.
    # Higher seeds (lower numbers) are favored, but upsets can happen.
    #
    # Seeds range from 1-16:
    # - 1-seed vs 16-seed: only 5% upset chance
    # - 8-seed vs 9-seed: nearly a coin flip (45% for 9-seed)
    #
    class GameOutcome
      def self.higher_seed_wins?(seed_a, seed_b, rng: Random)
        favorite = [ seed_a, seed_b ].min
        underdog = [ seed_a, seed_b ].max

        upset_chance = case underdog - favorite
        when 0..1 then 0.45  # Close matchup (8v9)
        when 2..4 then 0.30  # Moderate favorite
        when 5..8 then 0.15  # Strong favorite
        else 0.05            # Heavy favorite (1v16, 2v15)
        end

        rng.rand > upset_chance
      end
    end
  end
end
