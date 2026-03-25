# frozen_string_literal: true

module Scenarios
  module States
    class PreTipoff < Base
      private

      def setup
        set_tournament_state(:not_started)
        ensure_brackets
      end
    end
  end
end
