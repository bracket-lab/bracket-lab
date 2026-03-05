# frozen_string_literal: true

module Scenarios
  module States
    # Scenario: Mid-tournament - Sweet 16 partially complete with gaps
    #
    # State:
    #   - Tournament: In in_progress state with 50 games decided
    #   - Users: 10 users exist (1 admin, 9 regular)
    #   - Brackets: 25 brackets exist, all locked
    #   - Standings: Points accumulated through 2 rounds + 2 Sweet 16 games
    #
    # This represents the tournament midpoint where Sweet 16 games are
    # partially complete. The key feature is that completed Sweet 16 games
    # are non-adjacent (slots 10 and 13), creating gaps in the decision tree.
    #
    # Sweet 16 slot layout (8-15):
    #   8  9  10  11  12  13  14  15
    #         ^           ^
    #         |           |
    #     completed   completed
    #
    # The gap between slots 10 and 13 (3 apart) tests that the scoring
    # and elimination systems handle non-contiguous game completion.
    #
    class MidTournament < Base
      NUM_GAMES = 50
      GAP_SLOTS = [ 10, 13 ].freeze  # Non-adjacent Sweet 16 slots

      private

      def setup
        create_tournament_in_progress
        generate_game_results
      end

      def generate_game_results
        # Generate 50 games: all Round 1 (32) + Round 2 (16) + 2 Sweet 16
        # Using gap_slots ensures non-adjacent Sweet 16 games (10 and 13)
        Generators::TournamentGenerator.new(NUM_GAMES, gap_slots: GAP_SLOTS).call
      end
    end
  end
end
