# frozen_string_literal: true

module Scenarios
  module States
    # Before Selection Sunday. Teams not yet selected, no brackets.
    class PreSelection < Base
      private

      def setup
        set_tournament_state(:pre_selection)
      end
    end
  end
end
