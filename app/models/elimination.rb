class Elimination
  attr_accessor :acc

  def initialize
    @acc = brackets.to_h { |b| [ b.id, 6 ] }
  end

  def results(t_decision_team_slots)
    return unless Tournament.field_64.start_eliminating?

    nil_slot = t_decision_team_slots.rindex(nil)

    if nil_slot && !nil_slot.zero?
      t_decision_team_slots[nil_slot] = t_decision_team_slots[nil_slot * 2] # decision == 0
      results(t_decision_team_slots)

      t_decision_team_slots[nil_slot] = t_decision_team_slots[(nil_slot * 2) + 1] # decision == 1
      results(t_decision_team_slots)

      t_decision_team_slots[nil_slot] = nil
    else
      tuples = brackets.map do |bracket|
        [ bracket.id, bracket.points_for(t_decision_team_slots) ]
      end

      tuples.sort_by! { |tuple| -tuple[1] }

      rank = 1
      tuples.each.with_index do |tuple, i|
        rank = i + 1 unless i.zero? || tuple[1] == tuples[i - 1][1]
        acc[tuple[0]] = [ rank, acc[tuple[0]] ].min
        break unless rank < 6
      end
    end
  end

  def brackets
    @brackets ||= Bracket.all
  end
end
