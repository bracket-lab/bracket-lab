require "test_helper"

class UpdateBestFinishesJobTest < ActiveJob::TestCase
  test "delegates to OutcomeRanking.populate" do
    set_tournament_state(:final_four)
    tournament = Tournament.field_64

    OutcomeRanking.expects(:populate).with(tournament)

    UpdateBestFinishesJob.perform_now
  end
end
