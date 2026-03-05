module TournamentHelper
  def pick_class_for(team, game_team, round_one:)
    unless team
      Rails.logger.debug("pick_class_for called with nil team") if game_team
      return ""
    end
    return "" if round_one
    return "" if team.still_playing? && game_team.nil?

    if game_team && team.name == game_team.name
      "correct-pick"
    else
      "eliminated"
    end
  end
end
