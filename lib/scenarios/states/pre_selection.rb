# frozen_string_literal: true

module Scenarios
  module States
    # Scenario: Before Selection Sunday
    #
    # State:
    #   - Tournament: In pre_selection state (teams not yet selected)
    #   - Users: 10 users exist (1 admin, 9 regular)
    #   - Brackets: None
    #
    # This represents the period before Selection Sunday when users can
    # register but cannot create brackets because teams haven't been
    # selected for the tournament yet.
    #
    class PreSelection < Base
      private

      def setup
        # Create tournament in pre_selection state (the default enum value)
        Tournament.create!(state: :pre_selection)

        # No brackets to create - users can't pick until teams are selected
      end
    end
  end
end
