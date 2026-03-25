# frozen_string_literal: true

module Scenarios
  module States
    class MidTournament < Base
      private

      def setup
        ensure_brackets
        set_tournament_state(:in_progress, num_games: 50, gap_slots: [ 10, 13 ])
      end
    end
  end
end
