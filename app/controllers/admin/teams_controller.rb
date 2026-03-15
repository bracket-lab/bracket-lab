class Admin::TeamsController < Admin::BaseController
  def index
    @teams = Team.all
  end

  def update
    @team = Team.find(params[:id])

    if @team.update(team_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            @team, partial: "admin/teams/team", locals: { team: @team }
          )
        end
        format.html { redirect_to admin_teams_path, notice: "Team updated." }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            @team, partial: "admin/teams/team", locals: { team: @team }
          ), status: :unprocessable_entity
        end
        format.html { redirect_to admin_teams_path, alert: @team.errors.full_messages.to_sentence }
      end
    end
  end

  def import
    @current_names = params[:team_names].presence || Team.order(:starting_slot).pluck(:name).join("\n")
  end

  def import_preview
    @names = params[:team_names].to_s.split("\n").map(&:strip).reject(&:blank?)
    @errors = validate_import(@names)

    if @errors.any?
      @current_names = params[:team_names].to_s
      render :import, status: :unprocessable_entity
    else
      @preview = build_preview(@names)
    end
  end

  def import_apply
    names = params[:names]

    unless names.is_a?(Array) && names.size == 64
      redirect_to import_admin_teams_path, alert: "Invalid import data."
      return
    end

    Team.transaction do
      teams = Team.order(:starting_slot).to_a

      teams.each_with_index do |team, i|
        team.update_columns(name: "__import_#{i}")
      end

      teams.each_with_index do |team, i|
        team.update!(name: names[i])
      end
    end

    redirect_to admin_teams_path, notice: "All 64 team names updated."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to import_admin_teams_path(team_names: names.join("\n")),
      alert: e.record.errors.full_messages.to_sentence
  end

  private

  def team_params
    params.require(:team).permit(:name)
  end

  def validate_import(names)
    errors = []
    errors << "Expected 64 team names, got #{names.size}" unless names.size == 64
    names.each_with_index do |name, i|
      errors << "Line #{i + 1} (\"#{name}\") exceeds 15 characters" if name.length > 15
    end
    if names.size != names.uniq.size
      dupes = names.group_by(&:itself).select { |_, v| v.size > 1 }.keys
      errors << "Duplicate names: #{dupes.join(', ')}"
    end
    errors
  end

  def build_preview(names)
    teams = Team.order(:starting_slot).to_a
    names.each_with_index.map do |name, i|
      { team: teams[i], new_name: name, changed: teams[i].name != name }
    end
  end
end
