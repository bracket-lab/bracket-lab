# frozen_string_literal: true

module Scenarios
  module States
    class FirstWeekend < Base
      private

      def setup
        ensure_brackets
        set_tournament_state(:in_progress, num_games: 48)
      end
    end
  end
end
