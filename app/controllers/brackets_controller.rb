class BracketsController < ApplicationController
  before_action :set_bracket, only: [ :show, :edit, :update, :destroy ]
  before_action :check_tournament_set, only: [ :index ]

  def index
    @brackets = policy_scope(Bracket)
  end

  def show
    authorize @bracket
  end

  def new
    @bracket = current_user.brackets.build
    authorize @bracket
  end

  def create
    @bracket = current_user.brackets.build(bracket_params)
    authorize @bracket

    if @bracket.save
      redirect_to brackets_path, notice: "Bracket was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @bracket
  end

  def update
    authorize @bracket
    if @bracket.update(bracket_params)
      redirect_to @bracket, notice: "Bracket was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @bracket
    @bracket.destroy
    redirect_to brackets_path, notice: "Bracket was successfully deleted."
  end

  private

  def set_bracket
    @bracket = Bracket.find(params[:id])
  end

  def check_tournament_set
    if Current.tournament.pre_selection?
      redirect_to countdown_path
    elsif Current.tournament.started?
      redirect_to leaderboard_path
    end
  end

  def bracket_params
    params.require(:bracket).permit(:name, :game_decisions)
  end

  def current_user
    Current.user
  end
end
