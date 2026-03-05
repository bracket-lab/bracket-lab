# frozen_string_literal: true

module Scenarios
  module States
    # Scenario: Final Four - Elite 8 complete, only Final Four and Championship remain
    #
    # State:
    #   - Tournament: In in_progress state with 60 games decided
    #   - Users: 10 users exist (1 admin, 9 regular)
    #   - Brackets: 25 brackets exist, all locked
    #   - Standings: Points accumulated through 4 rounds (R1, R2, Sweet 16, Elite 8)
    #
    # This represents the tournament at the Final Four stage. All regional
    # champions have been determined (Elite 8 complete). Only 3 games remain:
    # the two Final Four semifinal games (slots 2-3) and the Championship (slot 1).
    #
    # With only 3 games left and 8 possible outcomes, this scenario is ideal for:
    #   - Testing the possibilities/scenarios calculator
    #   - Verifying eliminated bracket detection
    #   - Testing "can still win" vs "mathematically eliminated" logic
    #
    class FinalFour < Base
      NUM_GAMES = 60

      private

      def setup
        create_tournament_in_progress
        generate_game_results
      end

      def generate_game_results
        # Generate 60 games (R1 + R2 + Sweet 16 + Elite 8)
        # This leaves only Final Four (slots 2-3) and Championship (slot 1)
        Generators::TournamentGenerator.new(NUM_GAMES).call
      end
    end
  end
end
