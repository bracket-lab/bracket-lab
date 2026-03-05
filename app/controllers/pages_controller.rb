class PagesController < ApplicationController
  def rules
    @title = "Rules and Scoring"
  end

  def countdown
    @title = "Countdown to Selection Sunday"
    redirect_to root_path if Current.tournament.set?
  end

  def home
    tournament = Current.tournament

    if tournament.pre_selection?
      redirect_to countdown_path
    elsif !tournament.started?
      redirect_to brackets_path
    elsif !tournament.finished? && tournament.num_games_remaining <= 3
      redirect_to possible_outcomes_path
    else
      redirect_to leaderboard_path
    end
  end
end
