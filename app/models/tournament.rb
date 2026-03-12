class Tournament < ApplicationRecord
  TIP_OFF = Time.iso8601(ENV.fetch("TIP_OFF", "2026-03-19T16:00:00Z"))
  NUM_ROUNDS = 6
  REGION_NAMES = ["South", "West", "East", "Midwest"].freeze
  NUM_REGIONS = 4

  serialize :region_labels, coder: JSON

  validate :region_labels_must_be_valid_permutation

  after_update do |tournament|
    UpdateBestFinishesJob.perform_later if tournament.num_games_remaining < 16
  end

  enum :state, [ :pre_selection, :not_started, :in_progress, :completed ]

  def selection_sunday
    # Selection Sunday is always the Sunday before tip-off at 6pm ET
    @selection_sunday ||= begin
      sunday = tip_off.beginning_of_week(:sunday)
      sunday.change(hour: 22, min: 0, sec: 0) # 6pm ET in UTC
    end
  end

  def set?
    !pre_selection?
  end

  def selection_in_progress?
    Time.current > selection_sunday && pre_selection?
  end

  def started?
    in_progress? || completed?
  end

  def start!
    in_progress! if not_started?
  end

  def set_teams!
    not_started! if pre_selection?
  end

  def self.field_64
    first_or_create!
  end

  def tip_off
    TIP_OFF
  end

  def num_rounds
    NUM_ROUNDS
  end

  def finished?
    num_games_remaining.zero?
  end

  def start_eliminating?
    num_games_remaining < 16 && num_games_remaining.positive?
  end

  delegate :championship, to: :tree

  def num_games
    (2**num_rounds) - 1
  end

  def num_games_played
    game_mask.to_s(2).count("1")
  end

  def num_games_remaining
    num_games - num_games_played
  end

  def game_slots_for(round_number, region = nil)
    game_ids = tree.game_slots_for(round_number)

    # regions can symbols (names) or ints (enum idx)
    region = Team.regions[region] if region.is_a?(Symbol)

    if region.present? && game_ids.size >= Team.regions.size
      slice_size = game_ids.size / Team.regions.size
      slice_index = region
      slices = game_ids.each_slice(slice_size).to_a
      slices[slice_index]
    else
      game_ids
    end
  end

  def rounds
    @rounds ||= (1..num_rounds).to_a.map { |n| Round.new number: n }
  end

  def round_name_date_pairs
    rounds.map do |round|
      date_range_string = round.start_date.strftime("%b %e")
      date_range_string += "-#{round.end_date.strftime('%e')}" if round.start_date != round.end_date
      [ round.name, date_range_string ]
    end
  end

  def round_for(round_number, region = nil)
    tree.select_games(game_slots_for(round_number, region))
  end

  def tree
    TournamentTree.unmarshal(self, game_decisions, game_mask)
  end

  def update_game(position, choice)
    working_tree = tree
    working_tree.update_game(position, choice)

    marshalled_tree = working_tree.marshal
    self.game_decisions = marshalled_tree.decisions
    self.game_mask = marshalled_tree.mask
  end

  def update_game!(position, choice)
    update_game(position, choice)
    save!
  end

  def clear_game(position)
    update_game(position, nil)

    # Also clear any dependent games
    clear_game(position / 2) if position > 1
  end

  def games
    working_tree = tree
    (1..num_games).map { |slot| working_tree.at(slot) }
  end

  def games_hash
    games.map do |node|
      {
        slot: node.slot,
        teamOne: team_hash(node.team_one),
        teamTwo: team_hash(node.team_two),
        winningTeam: team_hash(node.team),
        gameOneId: node.left_position,
        gameTwoId: node.right_position,
        nextGameId: node.next_game_slot,
        nextSlot: node.next_slot,
        choice: node.decision
      }
    end
  end

  def self.slots_to_decisions(slots)
    decisions = 0
    slots.to_enum.with_index.reverse_each do |slot, i|
      next if i.zero?

      decision = if i >= 32
                   slot.even? ? 0 : 1
      else
                   slot == slots[i * 2] ? 0 : 1
      end

      decisions |= decision << i
    end

    decisions
  end

  def decision_team_slots
    @decision_team_slots ||= begin
      decisions = game_decisions
      result = Array.new(64)

      (1..63).to_a.reverse.each do |i|
        current_position = 1 << i
        next unless current_position.anybits?(game_mask)

        decision = decisions.nobits?(current_position) ? 0 : 1
        position = (i * 2) + decision

        result[i] = i >= 32 ? position : result[position]
      end

      result
    end
  end

  def cache_key
    ActiveSupport::Digest.hexdigest(to_json)
  end

  # Override getter to shift bits left
  def game_decisions
    value = super
    value << 1
  end

  def game_decisions=(value)
    self[:game_decisions] = unsigned_right_shift(value)
  end

  # Override getter to shift bits left
  def game_mask
    value = super
    value << 1
  end

  def game_mask=(value)
    self[:game_mask] = unsigned_right_shift(value)
  end

  private

  def team_hash(team)
    team.present? ? { id: team.id, seed: team.seed, name: team.name } : nil
  end

  def unsigned_right_shift(num)
    # First perform the right shift
    result = num >> 1

    # Then mask off the MSB (for 64-bit integer)
    result & Bracket::MAX_INT64
  end

  def region_labels_must_be_valid_permutation
    unless region_labels.is_a?(Array) && region_labels.sort == REGION_NAMES.sort
      errors.add(:region_labels, "must be a permutation of the four region names")
    end
  end
end
