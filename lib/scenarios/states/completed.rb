# frozen_string_literal: true

module Scenarios
  module States
    # Tournament finished — all 63 games decided, champion crowned.
    class Completed < Base
      private

      def setup
        ensure_brackets
        set_tournament_state(:completed, num_games: 63)
      end
    end
  end
end
