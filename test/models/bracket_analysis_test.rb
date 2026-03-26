require "test_helper"

class BracketAnalysisTest < ActiveSupport::TestCase
  setup do
    set_tournament_state(:final_four)
    @tournament = Tournament.field_64
    @tournament.update!(outcomes_calculated: true)
    Current.tournament = @tournament
    OutcomeRanking.delete_all
    @bracket = brackets(:one)
  end

  test "finish_distribution returns counts per rank" do
    create_rankings(@bracket, { 1 => 3, 3 => 2, 5 => 1 }, total_scenarios: 8)
    analysis = BracketAnalysis.new(@bracket)
    dist = analysis.finish_distribution
    assert_equal 3, dist[1]
    assert_equal 0, dist[2]
    assert_equal 2, dist[3]
    assert_equal 0, dist[4]
    assert_equal 1, dist[5]
  end

  test "total_scenarios counts distinct game_decisions" do
    create_rankings(@bracket, { 1 => 3, 3 => 2 }, total_scenarios: 8)
    analysis = BracketAnalysis.new(@bracket)
    assert_equal 8, analysis.total_scenarios
  end

  test "sixth_plus_count is total minus ranked scenarios" do
    create_rankings(@bracket, { 1 => 2 }, total_scenarios: 8)
    analysis = BracketAnalysis.new(@bracket)
    assert_equal 6, analysis.sixth_plus_count
  end

  test "best_finish returns minimum rank" do
    create_rankings(@bracket, { 2 => 3, 4 => 1 }, total_scenarios: 8)
    analysis = BracketAnalysis.new(@bracket)
    assert_equal 2, analysis.best_finish
  end

  test "best_finish returns nil when no rankings exist" do
    analysis = BracketAnalysis.new(@bracket)
    assert_nil analysis.best_finish
  end

  test "game_impacts returns impact data for known matchups" do
    create_rankings(@bracket, { 1 => 4, 3 => 4 }, total_scenarios: 8)
    analysis = BracketAnalysis.new(@bracket)
    impacts = analysis.game_impacts
    assert impacts.any?, "Should have at least one game impact"
    impact = impacts.first
    assert impact[:slot].present?
    assert impact[:team_zero].present?
    assert impact[:team_one].present?
    assert impact[:round_name].present?
    assert impact[:impact_score].is_a?(Numeric)
    assert impact[:outcomes].is_a?(Hash)
    assert impact[:outcomes].key?(0)
    assert impact[:outcomes].key?(1)
  end

  test "game_impacts sorted by impact_score descending" do
    create_rankings(@bracket, { 1 => 4, 3 => 4 }, total_scenarios: 8)
    analysis = BracketAnalysis.new(@bracket)
    impacts = analysis.game_impacts
    scores = impacts.map { |i| i[:impact_score] }
    assert_equal scores.sort.reverse, scores
  end

  test "undetermined_games present at final four" do
    create_rankings(@bracket, { 1 => 4 }, total_scenarios: 8)
    analysis = BracketAnalysis.new(@bracket)
    assert analysis.undetermined_games.any?, "Should have undetermined games at final four"
  end

  test "outcome_distribution_for_game splits scenarios by bit" do
    # Slot 2: bit 2 in logical, bit 1 in DB (right-shifted)
    # Outcome 0 (bit 2=0 logical): game_decisions 0, 8 -> DB 0, 4 -> bit 1 is 0
    # Outcome 1 (bit 2=1 logical): game_decisions 4, 12 -> DB 2, 6 -> bit 1 is 1
    OutcomeRanking.create!(game_decisions: 0, bracket: @bracket, rank: 1, points: 200)
    OutcomeRanking.create!(game_decisions: 8, bracket: @bracket, rank: 3, points: 180)
    OutcomeRanking.create!(game_decisions: 4, bracket: @bracket, rank: 2, points: 190)
    OutcomeRanking.create!(game_decisions: 12, bracket: @bracket, rank: 5, points: 150)
    other = brackets(:perfect)
    OutcomeRanking.create!(game_decisions: 0, bracket: other, rank: 2, points: 190)
    OutcomeRanking.create!(game_decisions: 4, bracket: other, rank: 1, points: 200)
    OutcomeRanking.create!(game_decisions: 8, bracket: other, rank: 3, points: 170)
    OutcomeRanking.create!(game_decisions: 12, bracket: other, rank: 4, points: 160)

    analysis = BracketAnalysis.new(@bracket)
    dist = analysis.outcome_distribution_for_game(2)

    assert_equal 1, dist[0][1]
    assert_equal 1, dist[0][3]
    assert_equal 1, dist[1][2]
    assert_equal 1, dist[1][5]
  end

  private

  def create_rankings(bracket, rank_counts, total_scenarios:)
    game_decisions_counter = 0
    scenarios_with_ranking = 0
    rank_counts.each do |rank, count|
      count.times do
        # Use even values so each maps to a unique DB value after right-shift
        OutcomeRanking.create!(game_decisions: game_decisions_counter * 2, bracket: bracket, rank: rank, points: 200 - (rank * 10))
        game_decisions_counter += 1
        scenarios_with_ranking += 1
      end
    end
    other_bracket = brackets(:perfect)
    (total_scenarios - scenarios_with_ranking).times do
      OutcomeRanking.create!(game_decisions: game_decisions_counter * 2, bracket: other_bracket, rank: 1, points: 300)
      game_decisions_counter += 1
    end
  end
end
