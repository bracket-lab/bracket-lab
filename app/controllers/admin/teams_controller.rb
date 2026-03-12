class Admin::TeamsController < Admin::BaseController
  include ActionView::RecordIdentifier

  def index
    @teams = Team.all
  end

  def update
    @team = Team.find(params[:id])

    if @team.update(team_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@team), partial: "admin/teams/team", locals: { team: @team }
          )
        end
        format.html { redirect_to admin_teams_path, notice: "Team updated." }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@team), partial: "admin/teams/team", locals: { team: @team }
          ), status: :unprocessable_entity
        end
        format.html { redirect_to admin_teams_path, alert: @team.errors.full_messages.to_sentence }
      end
    end
  end

  private

  def team_params
    params.require(:team).permit(:name)
  end
end
