module ApplicationHelper
  def pool_name
    Rails.configuration.env[:pool_name]
  end

  def bracket_picker_props(bracket)
    tournament = Current.tournament

    {
      tournament: {
        gameDecisions: tournament.game_decisions.to_s,
        gameMask: tournament.game_mask.to_s,
        rounds: tournament.rounds.map do |round|
          {
            name: round.name,
            number: round.number,
            startDate: round.start_date.iso8601,
            endDate: round.end_date.iso8601,
            regions: round.regions
          }
        end
      },
      teams: Team.all.map do |team|
        {
          startingSlot: team.starting_slot,
          seed: team.seed,
          name: team.name
        }
      end,
      gameDecisions: bracket.game_decisions.to_s,
      gameMask: bracket.persisted? || bracket.game_decisions.nonzero? ? Bracket::FULL_BRACKET_MASK.to_s : "0",
      betaUser: Current.user.admin?
    }
  end
end
