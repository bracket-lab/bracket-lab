class GameResultsController < ApplicationController
  def index
    redirect_to root_path, alert: "Tournament hasn't started yet" unless Current.tournament.started? || Current.user.admin?
  end
end
