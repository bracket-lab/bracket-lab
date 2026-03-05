# frozen_string_literal: true

module Scenarios
  module States
    # Scenario: After Selection Sunday, before tip-off
    #
    # State:
    #   - Tournament: In not_started state (teams selected, games pending)
    #   - Users: 10 users exist (1 admin, 9 regular)
    #   - Brackets: 25 brackets with realistic picks, distributed across users
    #
    # This represents the period after Selection Sunday when users can create
    # and edit their brackets, but before the tournament games have started.
    # No game results exist yet (game_decisions = 0, game_mask = 0).
    #
    class PreTipoff < Base
      private

      def setup
        create_tournament
        create_brackets
      end

      def create_tournament
        # Create tournament in pre_selection state, then set teams to transition
        # to not_started state (simulating Selection Sunday completion)
        tournament = Tournament.create!(state: :pre_selection)
        tournament.set_teams!
      end
    end
  end
end
