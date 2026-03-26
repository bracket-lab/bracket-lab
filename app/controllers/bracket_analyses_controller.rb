class BracketAnalysesController < ApplicationController
  before_action :set_bracket
  before_action :check_eliminations

  def show
    @analysis = BracketAnalysis.new(@bracket)
  end

  private

  def set_bracket
    @bracket = Bracket.find(params[:bracket_id])
  end

  def check_eliminations
    redirect_to bracket_path(@bracket) unless Current.tournament.display_eliminations?
  end
end
