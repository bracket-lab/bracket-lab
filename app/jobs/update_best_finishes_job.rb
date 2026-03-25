class UpdateBestFinishesJob < ApplicationJob
  queue_as :default
  limits_concurrency key: :only, duration: 30.minutes

  def perform
    tournament = Current.tournament
    return unless tournament.start_eliminating?

    if OutcomeRanking.none?
      populate(tournament)
    else
      prune(tournament)
    end

    derive_possible_results
  end

  private

  def populate(tournament)
    elimination = Elimination.new
    elimination.results(tournament.decision_team_slots.dup)

    OutcomeRanking.insert_all(elimination.outcomes) if elimination.outcomes.any?

    tournament.update!(outcomes_calculated: true)
  end

  def prune(tournament)
    # Read raw DB values (right-shifted) bypassing the left-shifting getter
    tournament_mask = tournament[:game_mask]
    tournament_decisions = tournament[:game_decisions]

    OutcomeRanking.where(
      "game_decisions & :mask != :decisions & :mask",
      mask: tournament_mask, decisions: tournament_decisions
    ).delete_all
  end

  def derive_possible_results
    best_finishes = OutcomeRanking.group(:bracket_id).minimum(:rank)

    Bracket.find_each do |bracket|
      best_finish = best_finishes[bracket.id] || 6
      possible_result = PossibleResult.find_or_create_by!(bracket_id: bracket.id)
      possible_result.update!(best_finish: best_finish)
    end
  end
end
