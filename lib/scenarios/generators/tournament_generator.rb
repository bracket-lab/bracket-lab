# frozen_string_literal: true

module Scenarios
  module Generators
    # Generates tournament results up to N games completed.
    # Uses GameOutcome for realistic weighted results.
    #
    # Tournament games are numbered 1-63:
    # - Slots 32-63: Round 1 (32 games)
    # - Slots 16-31: Round 2 (16 games)
    # - Slots 8-15:  Sweet 16 (8 games)
    # - Slots 4-7:   Elite 8 (4 games)
    # - Slots 2-3:   Final Four (2 games)
    # - Slot 1:      Championship (1 game)
    #
    # Games must be completed in round order (Round 1 before Round 2, etc.)
    # Within a round, games can complete in any order.
    #
    # Usage:
    #   TournamentGenerator.new(32, seed: 42).call   # Complete Round 1 only
    #   TournamentGenerator.new(48, seed: 42).call   # Complete Round 1 + Round 2
    #   TournamentGenerator.new(50, seed: 42, gap_slots: [10, 13]).call  # Mid-tournament with specific Sweet 16 games
    #   TournamentGenerator.new(63, seed: 42).call   # Complete tournament
    #
    class TournamentGenerator
      Result = Struct.new(:decisions, :mask, keyword_init: true) do
        def apply_to(tournament)
          tournament.update!(
            state: :in_progress,
            game_decisions: decisions,
            game_mask: mask
          )
        end
      end

      ROUNDS = [
        { name: "Round 1",      slots: 32..63, games: 32, cumulative: 32 },
        { name: "Round 2",      slots: 16..31, games: 16, cumulative: 48 },
        { name: "Sweet 16",     slots: 8..15,  games: 8,  cumulative: 56 },
        { name: "Elite 8",      slots: 4..7,   games: 4,  cumulative: 60 },
        { name: "Final Four",   slots: 2..3,   games: 2,  cumulative: 62 },
        { name: "Championship", slots: 1..1,   games: 1,  cumulative: 63 }
      ].freeze

      attr_reader :num_games, :gap_slots

      # @param num_games [Integer] Number of games to complete (1-63)
      # @param seed [Integer, nil] Random seed for deterministic results
      # @param gap_slots [Array<Integer>] For partial rounds, specific slots to complete
      #   Used for mid_tournament scenario to ensure non-adjacent Sweet 16 games
      def initialize(num_games, seed: nil, gap_slots: nil)
        @num_games = num_games.clamp(0, 63)
        @gap_slots = gap_slots
        @rng = seed ? Random.new(seed) : Random
        @winners = {} # slot => winning team's starting_slot
      end

      # Generate tournament results and return a Result struct
      # @return [Result] A struct with decisions and mask integers
      def call
        decisions = 0
        mask = 0
        games_completed = 0

        ROUNDS.each do |round|
          break if games_completed >= num_games

          slots_to_play = determine_slots_for_round(round, games_completed)

          slots_to_play.each do |slot|
            break if games_completed >= num_games

            decision = decide_game(slot)
            decisions |= (decision << slot)
            mask |= (1 << slot)
            games_completed += 1
          end
        end

        Result.new(decisions: decisions, mask: mask)
      end

      private

      def determine_slots_for_round(round, games_completed)
        games_remaining = num_games - games_completed
        all_slots = round[:slots].to_a

        if games_remaining >= round[:games]
          all_slots
        elsif gap_slots.present? && slots_overlap?(all_slots, gap_slots)
          gap_slots.select { |s| all_slots.include?(s) }
        else
          all_slots.first(games_remaining)
        end
      end

      def slots_overlap?(round_slots, specified_slots)
        (round_slots & specified_slots).any?
      end

      def decide_game(slot)
        left_slot = slot * 2
        right_slot = slot * 2 + 1

        left_team = team_at(left_slot)
        right_team = team_at(right_slot)

        left_seed = Team.seed_for_slot(left_team)
        right_seed = Team.seed_for_slot(right_team)

        decision = pick_winner(left_seed, right_seed)

        winning_team = decision.zero? ? left_team : right_team
        @winners[slot] = winning_team

        decision
      end

      def team_at(slot)
        # Slots >= 64 are team starting_slots; lower slots reference previous game winners
        if slot >= 64
          slot
        else
          @winners[slot]
        end
      end

      def pick_winner(left_seed, right_seed)
        if left_seed <= right_seed
          favorite_wins = GameOutcome.higher_seed_wins?(left_seed, right_seed, rng: @rng)
          favorite_wins ? 0 : 1
        else
          favorite_wins = GameOutcome.higher_seed_wins?(right_seed, left_seed, rng: @rng)
          favorite_wins ? 1 : 0
        end
      end
    end
  end
end
