# frozen_string_literal: true

module Scenarios
  module States
    # Final Four — 60 games decided, only 3 remain (slots 1-3).
    class FinalFour < Base
      private

      def setup
        ensure_brackets
        set_tournament_state(:in_progress, num_games: 60)
      end
    end
  end
end
