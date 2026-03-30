class PossibleOutcomesController < ApplicationController
  before_action :check_tournament_status

  def index
    if stale?(OutcomeRanking.all)
      rankings = OutcomeRanking.includes(bracket: :user).order(:game_decisions, :rank)

      @outcomes = rankings.group_by(&:game_decisions).map do |game_decisions, group|
        slots = Tournament.decisions_to_slots(game_decisions)
        winning_team_slot = slots[1]
        losing_team_slot = winning_team_slot == slots[2] ? slots[3] : slots[2]

        ranked_brackets = group.map do |ranking|
          {
            bracket: ranking.bracket,
            points: ranking.points,
            rank: ranking.rank,
            tied: group.any? { |other| other != ranking && other.rank == ranking.rank }
          }
        end

        {
          winner: Team.find_by(starting_slot: winning_team_slot),
          loser: Team.find_by(starting_slot: losing_team_slot),
          slots: slots,
          ranked_brackets: ranked_brackets
        }.with_indifferent_access
      end
    end
  end

  private

  def check_tournament_status
    if Current.tournament.num_games_remaining > 3
      redirect_to root_path, alert: "Outcomes are only shown in final four."
    end
  end
end
