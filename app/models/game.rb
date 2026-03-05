# frozen_string_literal: true

class Game < BinaryDecisionTree::Node
  alias game_one left
  alias game_two right
  alias next_game parent

  attr_accessor :bracket

  def round_number
    rounds = (1..tournament_tree.depth).to_a.reverse
    rounds[current_depth - 1]
  end

  def round
    Round.new number: round_number
  end

  def region
    game_slots = tree.game_slots_for(round_number)
    return nil if game_slots.size < Team.regions.size

    regions = Team.region_names

    slice_size = game_slots.size / regions.size
    slices = game_slots.each_slice(slice_size).to_a
    regions.find.with_index { |_name, idx| slices[idx].include?(slot) }
  end

  def championship?
    parent_position.zero?
  end

  def tournament_game
    tournament_tree.at(slot)
  end

  def next_slot
    return nil if championship?

    slot.even? ? 1 : 2
  end

  def next_game_slot
    championship? ? nil : parent_position
  end

  def team_one
    leaf? ? team_by_slot(left_position) : nil
  end

  def team_two
    leaf? ? team_by_slot(right_position) : nil
  end

  def first_team
    team_one || team_by_slot(left)
  end

  def second_team
    team_two || team_by_slot(right)
  end

  def team
    team_by_slot(self)
  end

  alias winner team

  def loser
    return nil if winner.blank?

    ([ first_team, second_team ] - [ winner ]).first
  end

  def ==(other)
    other.class == self.class && other.state == state
  end

  alias eql? ==

  delegate :hash, to: :state

  protected

  def state
    [ tree, slot, value ]
  end

  private

  def team_seed
    tournament.team_seed(value)
  end

  def team_by_slot(in_slot)
    slot_number = in_slot.try(:value) || in_slot
    Team.find_by(starting_slot: slot_number)
  end

  def tournament
    tree.tournament
  end

  def tournament_tree
    tournament.tree
  end
end
