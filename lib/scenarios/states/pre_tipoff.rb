# frozen_string_literal: true

module Scenarios
  module States
    # After Selection Sunday, before tip-off. Teams selected, brackets editable.
    class PreTipoff < Base
      private

      def setup
        set_tournament_state(:not_started)
        ensure_brackets
      end
    end
  end
end
