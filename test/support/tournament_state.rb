# frozen_string_literal: true

module TournamentState
  STATE_CONFIG = {
    pre_selection:  { state: :pre_selection },
    pre_tipoff:     { state: :not_started },
    tipoff:         { state: :in_progress },
    some_games:     { state: :in_progress, num_games: 10 },
    first_weekend:  { state: :in_progress, num_games: 48 },
    mid_tournament: { state: :in_progress, num_games: 50, gap_slots: [ 10, 13 ] },
    final_four:     { state: :in_progress, num_games: 60 },
    completed:      { state: :in_progress, num_games: 63, completed: true }
  }.freeze

  def set_tournament_state(state_name)
    config = STATE_CONFIG.fetch(state_name)
    tournament = Tournament.field_64
    tournament.update!(state: config[:state], game_decisions: 0, game_mask: 0)

    if config[:num_games]
      result = Scenarios::Generators::TournamentGenerator.new(
        config[:num_games],
        seed: Minitest.seed,
        gap_slots: config[:gap_slots]
      ).call
      result.apply_to(tournament)
      tournament.completed! if config[:completed]
    end
  end
end
