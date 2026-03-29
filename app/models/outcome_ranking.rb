class OutcomeRanking < ApplicationRecord
  include ShiftedBitwiseColumns
  shifted_bitwise_columns :game_decisions

  belongs_to :bracket

  class << self
    def populate(tournament = nil)
      tournament = Tournament.find(tournament ? tournament.id : Tournament.field_64.id)
      brackets = Bracket.all

      if tournament.start_eliminating?
        prune(tournament)
        leaf_nodes(tournament.decision_team_slots.dup) do |t_decision_team_slots|
          process_leaf(t_decision_team_slots, brackets)
        end
        tournament.update!(outcomes_calculated: true) unless tournament.outcomes_calculated?

      else
        OutcomeRanking.delete_all
        tournament.update!(outcomes_calculated: false) if tournament.outcomes_calculated?
      end
    end

    def prune(tournament = nil)
      tournament ||= Tournament.field_64

      # Read raw DB values (right-shifted) bypassing the left-shifting getter
      tournament_mask = tournament[:game_mask]
      tournament_decisions = tournament[:game_decisions]

      OutcomeRanking.where(
        "game_decisions & :mask != :decisions & :mask",
        mask: tournament_mask, decisions: tournament_decisions
      ).delete_all

      # Touch a surviving row so OutcomeRanking.maximum(:updated_at) advances.
      # Pruning only deletes rows — without this, the leaderboard's HTTP cache
      # (stale? check) would never invalidate after the async job completes.
      OutcomeRanking.limit(1).touch_all
    end

    private

    def leaf_nodes(t_decision_team_slots, &block)
      nil_slot = t_decision_team_slots.rindex(nil)

      if nil_slot && !nil_slot.zero?
        t_decision_team_slots[nil_slot] = t_decision_team_slots[nil_slot * 2]
        leaf_nodes(t_decision_team_slots, &block)

        t_decision_team_slots[nil_slot] = t_decision_team_slots[(nil_slot * 2) + 1]
        leaf_nodes(t_decision_team_slots, &block)

        t_decision_team_slots[nil_slot] = nil
      else
        yield t_decision_team_slots
      end
    end

    def process_leaf(t_decision_team_slots, brackets)
      tuples = brackets.map do |bracket|
        [ bracket.id, bracket.points_for(t_decision_team_slots) ]
      end

      tuples.sort_by! { |tuple| -tuple[1] }

      decisions = Tournament.slots_to_decisions(t_decision_team_slots)
      # game_decisions is a shifted bitwise column: the Ruby getter left-shifts
      # and the setter right-shifts, but ActiveRecord's query interface does NOT
      # go through the setter.  We query the raw (already-shifted) DB value so
      # find_or_create_by! can locate existing rows correctly.
      raw_decisions = decisions >> 1

      rank = 1
      tuples.each.with_index do |tuple, i|
        rank = i + 1 unless i.zero? || tuple[1] == tuples[i - 1][1]
        if rank < 6
          OutcomeRanking
            .where(game_decisions: raw_decisions, bracket_id: tuple[0], rank: rank, points: tuple[1])
            .first_or_create! { |r| r.game_decisions = decisions }
        end
        break unless rank < 6
      end
    end
  end
end
