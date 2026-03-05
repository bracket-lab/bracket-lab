# frozen_string_literal: true

module Scenarios
  module States
    # Scenario: Tip-off moment - tournament has started, brackets are locked
    #
    # State:
    #   - Tournament: In in_progress state (game_decisions = 0, game_mask = 0)
    #   - Users: 10 users exist (1 admin, 9 regular)
    #   - Brackets: 25 brackets exist but are now locked (can't be edited)
    #
    # This represents the moment the first game tips off. The tournament has
    # officially started so brackets can no longer be modified, but no game
    # results have been recorded yet.
    #
    # Key difference from PreTipoff:
    #   - Tournament state is in_progress (not not_started)
    #   - Brackets still have their picks but are locked for editing
    #
    class Tipoff < Base
      private

      def setup
        create_tournament_in_progress
      end
    end
  end
end
