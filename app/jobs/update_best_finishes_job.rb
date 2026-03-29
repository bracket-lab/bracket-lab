class UpdateBestFinishesJob < ApplicationJob
  queue_as :default
  limits_concurrency key: :only, duration: 30.minutes

  def perform
    OutcomeRanking.populate(Current.tournament)
  end
end
