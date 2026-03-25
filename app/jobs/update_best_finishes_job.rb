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
  end

  private

  def populate(tournament)
    elimination = Elimination.new
    elimination.results(tournament.decision_team_slots.dup)
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

    # Touch a surviving row so OutcomeRanking.maximum(:updated_at) advances.
    # Pruning only deletes rows — without this, the leaderboard's HTTP cache
    # (stale? check) would never invalidate after the async job completes.
    OutcomeRanking.limit(1).touch_all
  end
end
