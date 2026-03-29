class OutcomeRanking < ApplicationRecord
  include ShiftedBitwiseColumns
  shifted_bitwise_columns :game_decisions

  belongs_to :bracket

  class << self
    def populate(tournament = nil)
      tournament ||= Tournament.field_64
      brackets = Bracket.all

      if tournament.start_eliminating?
        prune(tournament)
        leaf_nodes(tournament.decision_team_slots.dup).each do |t_decision_team_slots|
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

      rank = 1
      tuples.each.with_index do |tuple, i|
        rank = i + 1 unless i.zero? || tuple[1] == tuples[i - 1][1]
        if rank < 6
          OutcomeRanking.find_or_create_by!(game_decisions: decisions, bracket_id: tuple[0], rank: rank, points: tuple[1])
        end
        break unless rank < 6
      end
    end
  end
end
