# frozen_string_literal: true

module Scenarios
  module States
    class Completed < Base
      private

      def setup
        ensure_brackets
        set_tournament_state(:completed, num_games: 63)
      end
    end
  end
end
