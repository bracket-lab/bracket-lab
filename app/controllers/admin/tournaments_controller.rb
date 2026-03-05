class Admin::TournamentsController < Admin::BaseController
  def show
  end

  def set_teams
    if Current.tournament.set_teams!
      redirect_to admin_tournament_path, notice: "Tournament teams have been set"
    else
      redirect_to admin_tournament_path,
        alert: Current.tournament.errors.full_messages.to_sentence
    end
  end

  def start
    if Current.tournament.start!
      redirect_to admin_tournament_path, notice: "Tournament has been started"
    else
      redirect_to admin_tournament_path,
                  alert: Current.tournament.errors.full_messages.to_sentence
    end
  end

  def edit
  end

  def update
    if params[:choice] == "clear"
      Current.tournament.clear_game(params[:game_id].to_i)
      if Current.tournament.save
        respond_to do |format|
          format.html { redirect_to admin_tournament_path, notice: "Game result cleared successfully." }
          format.json { render json: { status: :ok } }
        end
      else
        respond_to do |format|
          format.html { redirect_to admin_tournament_path, alert: "Failed to clear game result." }
          format.json { render json: { status: :unprocessable_entity } }
        end
      end
    else
      if Current.tournament.update_game!(params[:game_id].to_i, params[:choice].to_i)
        respond_to do |format|
          format.html { redirect_to admin_tournament_path, notice: "Game result updated successfully." }
          format.json { render json: { status: :ok } }
        end
      else
        respond_to do |format|
          format.html { redirect_to admin_tournament_path, alert: "Failed to update game result." }
          format.json { render json: { status: :unprocessable_entity } }
        end
      end
    end
  end
end
