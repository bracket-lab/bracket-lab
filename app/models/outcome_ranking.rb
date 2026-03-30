class OutcomeRanking < ApplicationRecord
  attribute :game_decisions, :shifted_bitwise

  belongs_to :bracket

  validates :bracket_id, uniqueness: { scope: :game_decisions }

  class << self
    def populate(tournament = nil)
      tournament ||= Tournament.field_64
      brackets = Bracket.all

      if tournament.start_eliminating?
        prune(tournament)
        leaf_nodes(tournament.decision_team_slots).each do |t_decision_team_slots|
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

      # Read raw DB values (right-shifted) bypassing the type cast bitshift
      tournament_mask = tournament.read_attribute_before_type_cast(:game_mask)
      tournament_decisions = tournament.read_attribute_before_type_cast(:game_decisions)

      OutcomeRanking.where(
        "game_decisions & :mask != :decisions & :mask",
        mask: tournament_mask, decisions: tournament_decisions
      ).delete_all
    end

    private

    def leaf_nodes(t_decision_team_slots, &block)
      return enum_for(:leaf_nodes, t_decision_team_slots.dup) unless block

      nil_slot = t_decision_team_slots.rindex(nil)

      if nil_slot && !nil_slot.zero?
        t_decision_team_slots[nil_slot] = t_decision_team_slots[nil_slot * 2]
        leaf_nodes(t_decision_team_slots, &block)

        t_decision_team_slots[nil_slot] = t_decision_team_slots[(nil_slot * 2) + 1]
        leaf_nodes(t_decision_team_slots, &block)

        t_decision_team_slots[nil_slot] = nil
      else
        yield t_decision_team_slots.dup
      end
    end

    def process_leaf(t_decision_team_slots, brackets)
      tuples = brackets.map do |bracket|
        [ bracket.id, bracket.points_for(t_decision_team_slots) ]
      end

      tuples.sort_by! { |tuple| -tuple[1] }

      game_decisions = Tournament.slots_to_decisions(t_decision_team_slots)

      rank = 1
      tuples.each.with_index do |tuple, i|
        bracket_id = tuple[0]
        points = tuple[1]
        rank = i + 1 unless i.zero? || tuple[1] == tuples[i - 1][1]
        if rank < 6
          OutcomeRanking.find_or_create_by!(game_decisions:, bracket_id:, rank:, points:)
        end
        break unless rank < 6
      end
    end
  end
end
