class Elimination
  def initialize
   @start_eliminating = Tournament.field_64.start_eliminating?
  end

  def results(t_decision_team_slots)
    return unless @start_eliminating

    nil_slot = t_decision_team_slots.rindex(nil)

    if nil_slot && !nil_slot.zero?
      t_decision_team_slots[nil_slot] = t_decision_team_slots[nil_slot * 2] # decision == 0
      results(t_decision_team_slots)

      t_decision_team_slots[nil_slot] = t_decision_team_slots[(nil_slot * 2) + 1] # decision == 1
      results(t_decision_team_slots)

      t_decision_team_slots[nil_slot] = nil
    else
      process_leaf(t_decision_team_slots)
    end
  end

  def brackets
    @brackets ||= Bracket.all
  end

  private

  def process_leaf(t_decision_team_slots)
    tuples = brackets.map do |bracket|
      [ bracket.id, bracket.points_for(t_decision_team_slots) ]
    end

    tuples.sort_by! { |tuple| -tuple[1] }

    decisions = Tournament.slots_to_decisions(t_decision_team_slots)

    rank = 1
    tuples.each.with_index do |tuple, i|
      rank = i + 1 unless i.zero? || tuple[1] == tuples[i - 1][1]
      if rank < 6
        OutcomeRanking.create!(game_decisions: decisions, bracket_id: tuple[0], rank: rank, points: tuple[1])
      end
      break unless rank < 6
    end
  end
end
