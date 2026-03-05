# frozen_string_literal: true

module Scenarios
  module States
    # Scenario: First weekend complete - all Round 1 and Round 2 games decided
    #
    # State:
    #   - Tournament: In in_progress state with 48 games decided
    #   - Users: 10 users exist (1 admin, 9 regular)
    #   - Brackets: 25 brackets exist, all locked
    #   - Standings: Significant points accumulated through 2 rounds
    #
    # This represents the end of the first weekend of tournament action.
    # All 32 Round 1 games and all 16 Round 2 games have been played.
    # The Sweet 16 is about to begin.
    #
    class FirstWeekend < Base
      NUM_GAMES = 48

      private

      def setup
        create_tournament_in_progress
        generate_game_results
      end

      def generate_game_results
        # Generate 48 games (all Round 1 + Round 2)
        Generators::TournamentGenerator.new(NUM_GAMES).call
      end
    end
  end
end
