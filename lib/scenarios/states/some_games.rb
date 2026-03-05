# frozen_string_literal: true

module Scenarios
  module States
    # Scenario: Early tournament - some Round 1 games decided
    #
    # State:
    #   - Tournament: In in_progress state with ~10 games decided
    #   - Users: 10 users exist (1 admin, 9 regular)
    #   - Brackets: 25 brackets exist, all locked
    #   - Standings: Points start appearing based on correct picks
    #
    # This represents the first day of tournament action. About a third of
    # Round 1 games have been played, so users can see early standings
    # and how their brackets are performing.
    #
    class SomeGames < Base
      NUM_GAMES = 10

      private

      def setup
        create_tournament_in_progress
        generate_game_results
      end

      def generate_game_results
        # Generate 10 Round 1 game results
        Generators::TournamentGenerator.new(NUM_GAMES).call
      end
    end
  end
end
