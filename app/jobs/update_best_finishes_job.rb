class UpdateBestFinishesJob < ApplicationJob
  queue_as :default
  limits_concurrency key: :only, duration: 30.minutes

  def perform
    elimination = Elimination.new
    elimination.results(Current.tournament.decision_team_slots)

    elimination.acc.each do |bracket_id, best_finish|
      possible_result = PossibleResult.find_or_create_by!(bracket_id: bracket_id)
      possible_result.update!(best_finish: best_finish)
    end
  end
end
