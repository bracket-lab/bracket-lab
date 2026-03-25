# frozen_string_literal: true

module Scenarios
  module States
    class Tipoff < Base
      private

      def setup
        ensure_brackets
        set_tournament_state(:in_progress)
      end
    end
  end
end
