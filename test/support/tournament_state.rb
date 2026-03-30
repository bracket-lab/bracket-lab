# frozen_string_literal: true

module TournamentState
  STATE_CONFIG = {
    pre_selection:  { state: :pre_selection },
    pre_tipoff:     { state: :not_started },
    tipoff:         { state: :in_progress },
    some_games:     { num_games: 10 },
    first_weekend:  { num_games: 48 },
    mid_tournament: { num_games: 50, gap_slots: [ 10, 13 ] },
    final_four:     { num_games: 60 },
    completed:      { num_games: 63 }
  }.freeze

  def set_tournament_state(state_name)
    config = STATE_CONFIG.fetch(state_name)
    tournament = Tournament.field_64

    if config[:num_games]
      result = Scenarios::Generators::TournamentGenerator.new(
        config[:num_games],
        seed: Minitest.seed,
        gap_slots: config[:gap_slots]
      ).call
      result.apply_to(tournament)
    else
      tournament.update!(state: config[:state], game_decisions: 0, game_mask: 0)
    end

    OutcomeRanking.delete_all
    tournament.update!(outcomes_calculated: false)
  end
end
