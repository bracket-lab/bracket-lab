class PossibleOutcomesController < ApplicationController
  before_action :check_tournament_status

  def index
    if stale?(Current.tournament)
      @outcomes = calculate_outcomes(Current.tournament.decision_team_slots.dup)
    end
  end

  private

  def check_tournament_status
    if Current.tournament.num_games_remaining > 3
      redirect_to root_path, alert: "Outcomes are only shown in final four."
    end
  end

  def calculate_outcomes(t_decision_team_slots)
    nil_slot = t_decision_team_slots.rindex(nil)

    if nil_slot && !nil_slot.zero?
      t_decision_team_slots[nil_slot] = t_decision_team_slots[nil_slot * 2] # decision == 0
      decision_0 = calculate_outcomes(t_decision_team_slots)

      t_decision_team_slots[nil_slot] = t_decision_team_slots[(nil_slot * 2) + 1] # decision == 1
      decision_1 = calculate_outcomes(t_decision_team_slots)

      t_decision_team_slots[nil_slot] = nil

      decision_0 + decision_1
    else
      winning_team_slot = t_decision_team_slots[1]
      losing_team_slot = winning_team_slot == t_decision_team_slots[2] ? t_decision_team_slots[3] : t_decision_team_slots[2]

      winning_team = Team.find_by(starting_slot: winning_team_slot)
      losing_team = Team.find_by(starting_slot: losing_team_slot)

      outcome = {
        winner: winning_team,
        loser: losing_team,
        slots: t_decision_team_slots,
        ranked_brackets: calculate_bracket_rankings(t_decision_team_slots)
      }.with_indifferent_access

      [ outcome ]
    end
  end

  def calculate_bracket_rankings(slots)
    # Calculate points for each bracket with these game outcomes
    tuples = Bracket.all.filter_map do |bracket|
      [ bracket, bracket.points_for(slots) ] unless bracket.eliminated?
    end

    # Sort by points descending
    tuples.sort_by! { |tuple| -tuple[1] }

    # Calculate ranks (handling ties)
    ranked_brackets = tuples.each_with_index.map do |tuple, i|
      rank = i + 1
      {
        bracket: tuple[0],
        points: tuple[1],
        rank:,
        tied: false
      }
    end

    ranked_brackets.each_with_index do |rb, idx|
      prev_rb = ranked_brackets[idx - 1] if idx > 0
      if prev_rb && prev_rb[:points] == rb[:points]
        rb[:rank] = prev_rb[:rank]
        rb[:tied] = true
        prev_rb[:tied] = true
      end
    end

    ranked_brackets.filter do |rb|
      rb[:rank] <= 5
    end
  end
end
