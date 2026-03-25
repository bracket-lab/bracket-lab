class UpdateBestFinishesJob < ApplicationJob
  queue_as :default
  limits_concurrency key: :only, duration: 30.minutes

  def perform
    tournament = Current.tournament
    return unless tournament.start_eliminating?

    if Outcome.none?
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

    Outcome.transaction do
      outcome_rows = elimination.outcomes.map { |o| { game_decisions: o[:game_decisions] } }
      Outcome.insert_all(outcome_rows)

      id_map = Outcome.pluck(:game_decisions, :id).to_h

      ranking_rows = elimination.outcomes.flat_map do |outcome|
        outcome_id = id_map[outcome[:game_decisions]]
        outcome[:rankings].map do |r|
          {
            outcome_id: outcome_id,
            bracket_id: r[:bracket_id],
            rank: r[:rank],
            points: r[:points]
          }
        end
      end

      OutcomeRanking.insert_all(ranking_rows) if ranking_rows.any?
    end

    tournament.update!(outcomes_calculated: true)
  end

  def prune(tournament)
    # Read raw DB values (right-shifted) bypassing the left-shifting getter
    tournament_mask = tournament[:game_mask]
    tournament_decisions = tournament[:game_decisions]

    Outcome.where(
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
