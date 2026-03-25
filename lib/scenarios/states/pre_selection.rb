# frozen_string_literal: true

module Scenarios
  module States
    class PreSelection < Base
      private

      def setup
        set_tournament_state(:pre_selection)
      end
    end
  end
end
