# frozen_string_literal: true

module Scenarios
  module States
    # Scenario: Completed - Tournament is finished with all games decided
    #
    # State:
    #   - Tournament: In completed state with all 63 games decided
    #   - Users: 10 users exist (1 admin, 9 regular)
    #   - Brackets: 25 brackets exist, all locked and fully scored
    #   - Standings: Final standings with all points calculated
    #
    # This represents the tournament after completion. All 63 games have been
    # played and a champion has been crowned. Every bracket has been fully scored.
    #
    # This scenario is ideal for:
    #   - Testing final standings display
    #   - Verifying historical tournament viewing
    #   - Testing archive/results pages
    #
    class Completed < Base
      NUM_GAMES = 63

      private

      def setup
        create_tournament_in_progress
        generate_game_results
        complete_tournament
      end

      def generate_game_results
        # Generate all 63 games (complete tournament)
        Generators::TournamentGenerator.new(NUM_GAMES).call
      end

      def complete_tournament
        # Transition tournament to completed state
        tournament.completed!
      end
    end
  end
end
