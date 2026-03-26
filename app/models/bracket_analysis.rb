class BracketAnalysis
  attr_reader :bracket

  PAYOUT_WEIGHTS = { 1 => 50, 2 => 20, 3 => 15, 4 => 10, 5 => 5 }.freeze

  def initialize(bracket)
    @bracket = bracket
  end

  def finish_distribution
    @finish_distribution ||= begin
      counts = OutcomeRanking.where(bracket_id: bracket.id).group(:rank).count
      (1..5).each_with_object({}) { |r, h| h[r] = counts[r] || 0 }
    end
  end

  def total_scenarios
    @total_scenarios ||= OutcomeRanking.distinct.count(:game_decisions)
  end

  def sixth_plus_count
    total_scenarios - finish_distribution.values.sum
  end

  def best_finish
    @best_finish ||= OutcomeRanking.where(bracket_id: bracket.id).minimum(:rank)
  end

  def game_impacts
    @game_impacts ||= begin
      known_games.map do |game|
        dist = outcome_distribution_for_game(game.slot)
        {
          slot: game.slot,
          team_zero: game.first_team,
          team_one: game.second_team,
          round_name: game.round.name,
          region: game.region,
          outcomes: dist,
          impact_score: compute_impact(dist)
        }
      end.sort_by { |i| -i[:impact_score] }
    end
  end

  def undetermined_games
    @undetermined_games ||= remaining_games.reject { |g| known_matchup?(g) }.map do |game|
      { slot: game.slot, round_name: game.round.name, region: game.region }
    end
  end

  def outcome_distribution_for_game(slot)
    bit = 1 << (slot - 1)
    outcome_expr = Arel.sql("CASE WHEN (game_decisions & #{bit}) = 0 THEN 0 ELSE 1 END")
    rows = OutcomeRanking
      .where(bracket_id: bracket.id)
      .group(outcome_expr, :rank)
      .count(:all)
    result = { 0 => {}, 1 => {} }
    rows.each do |(outcome, rank), count|
      result[outcome][rank] = count
    end
    result
  end

  private

  def tournament
    Current.tournament
  end

  def remaining_games
    @remaining_games ||= begin
      tree = tournament.tree
      dts = tournament.decision_team_slots
      (1..63).filter_map do |slot|
        game = tree.at(slot)
        game if dts[slot].nil?
      end
    end
  end

  def known_games
    remaining_games.select { |g| known_matchup?(g) }
  end

  def known_matchup?(game)
    dts = tournament.decision_team_slots
    left_slot = game.slot * 2
    right_slot = game.slot * 2 + 1
    if game.leaf?
      true
    else
      dts[left_slot].present? && dts[right_slot].present?
    end
  end

  def compute_impact(dist)
    ev_zero = expected_value(dist[0])
    ev_one = expected_value(dist[1])
    (ev_zero - ev_one).abs
  end

  def expected_value(rank_counts)
    total = rank_counts.values.sum
    return 0.0 if total.zero?
    weighted_sum = rank_counts.sum do |rank, count|
      (PAYOUT_WEIGHTS[rank] || 0) * count
    end
    weighted_sum.to_f / total
  end
end
