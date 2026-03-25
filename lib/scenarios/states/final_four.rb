# frozen_string_literal: true

module Scenarios
  module States
    class FinalFour < Base
      private

      def setup
        ensure_brackets
        set_tournament_state(:in_progress, num_games: 60)
      end
    end
  end
end
