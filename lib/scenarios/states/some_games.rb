# frozen_string_literal: true

module Scenarios
  module States
    # Early tournament — ~10 Round 1 games decided.
    class SomeGames < Base
      private

      def setup
        ensure_brackets
        set_tournament_state(:in_progress, num_games: 10)
      end
    end
  end
end
