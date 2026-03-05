class LeaderboardController < ApplicationController
  before_action :check_tournament_status
  def index
    possible_result_updated_at = PossibleResult.maximum(:updated_at)
    @last_updated = [ Current.tournament.updated_at, possible_result_updated_at ].compact.max

    if stale?(last_modified: @last_updated)
      @ranked_brackets = ranked_brackets
      @show_eliminated = possible_result_updated_at.present? && !Current.tournament.finished?
    end
  end

  private

  def ranked_brackets
    # Calculate rankings with ties before filtering
    sorted_brackets = Bracket.all.sort_by { |b| [ -b.points, -b.possible_points ] }

    ranked_brackets = sorted_brackets.each_with_index.map do |bracket, i|
      rank = i + 1
      { bracket:, rank:, tied: false }
    end

    ranked_brackets.each_with_index do |rb, idx|
      prev_rb = ranked_brackets[idx - 1] if idx > 0
      if prev_rb && prev_rb[:bracket].points == rb[:bracket].points
        rb[:rank] = prev_rb[:rank]
        rb[:tied] = true
        prev_rb[:tied] = true
      end
    end
  end

  def check_tournament_status
    unless Current.tournament.started?
      redirect_to brackets_path
    end
  end
end
