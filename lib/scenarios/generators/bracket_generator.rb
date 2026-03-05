# frozen_string_literal: true

module Scenarios
  module Generators
    # Generates realistic bracket picks with different picking styles.
    #
    # Brackets have 63 games stored as a BigInt:
    # - Bits 32-63: Round 1 (32 games)
    # - Bits 16-31: Round 2 (16 games)
    # - Bits 8-15:  Sweet 16 (8 games)
    # - Bits 4-7:   Elite 8 (4 games)
    # - Bits 2-3:   Final Four (2 games)
    # - Bit 1:      Championship (1 game)
    #
    # For each game at slot N:
    # - Left child: slot N*2 (or team starting_slot if N >= 32)
    # - Right child: slot N*2 + 1
    # - Bit 0 = left/lower slot wins, bit 1 = right/higher slot wins
    #
    # Usage:
    #   BracketGenerator.new.call           # balanced picking
    #   BracketGenerator.new(:chalk).call   # favors higher seeds
    #   BracketGenerator.new(:upset).call   # favors upsets
    #
    class BracketGenerator
      STYLES = %i[balanced chalk upset].freeze

      # Upset probabilities by seed difference, adjusted per style
      # Base probabilities match GameOutcome:
      # - 0-1 diff: 45% upset (close matchup like 8v9)
      # - 2-4 diff: 30% upset
      # - 5-8 diff: 15% upset
      # - 9+ diff:  5% upset (heavy favorite like 1v16)
      UPSET_CHANCES = {
        balanced: { close: 0.45, moderate: 0.30, strong: 0.15, heavy: 0.05 },
        chalk:    { close: 0.30, moderate: 0.15, strong: 0.05, heavy: 0.01 },
        upset:    { close: 0.55, moderate: 0.45, strong: 0.30, heavy: 0.15 }
      }.freeze

      def initialize(style = :balanced)
        unless STYLES.include?(style)
          raise ArgumentError, "Unknown style: #{style}. Must be one of: #{STYLES.join(', ')}"
        end

        @style = style
        @chances = UPSET_CHANCES[style]
        @winners = {} # slot => winning team's starting_slot
      end

      # Generate a complete bracket and return the game_decisions BigInt
      def call
        decisions = 0

        # Process games from Round 1 (slots 32-63) up to Championship (slot 1)
        (32..63).each { |slot| decisions = decide_game(slot, decisions) }
        (16..31).each { |slot| decisions = decide_game(slot, decisions) }
        (8..15).each  { |slot| decisions = decide_game(slot, decisions) }
        (4..7).each   { |slot| decisions = decide_game(slot, decisions) }
        (2..3).each   { |slot| decisions = decide_game(slot, decisions) }
        decisions = decide_game(1, decisions)

        decisions
      end

      private

      def decide_game(slot, decisions)
        left_slot = slot * 2
        right_slot = slot * 2 + 1

        # Get the teams playing in this game
        left_team = team_at(left_slot)
        right_team = team_at(right_slot)

        # Determine winner
        decision = pick_winner(left_team, right_team)

        # Record winner for later rounds
        winning_team = decision.zero? ? left_team : right_team
        @winners[slot] = winning_team

        # Set the bit if right side wins (decision = 1)
        decisions |= (decision << slot)

        decisions
      end

      def team_at(slot)
        # Round 1 children are team starting_slots (64-127)
        # Later rounds reference previous game winners
        if slot >= 64
          slot
        else
          @winners[slot]
        end
      end

      def pick_winner(left_team, right_team)
        left_seed = Team.seed_for_slot(left_team)
        right_seed = Team.seed_for_slot(right_team)

        # Determine favorite and underdog
        if left_seed <= right_seed
          # Left is favorite (lower seed = better)
          favorite_wins = higher_seed_wins?(left_seed, right_seed)
          favorite_wins ? 0 : 1
        else
          # Right is favorite
          favorite_wins = higher_seed_wins?(right_seed, left_seed)
          favorite_wins ? 1 : 0
        end
      end

      def higher_seed_wins?(favorite_seed, underdog_seed)
        diff = underdog_seed - favorite_seed

        upset_chance = case diff
        when 0..1 then @chances[:close]
        when 2..4 then @chances[:moderate]
        when 5..8 then @chances[:strong]
        else @chances[:heavy]
        end

        rand > upset_chance
      end
    end
  end
end
