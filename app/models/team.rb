class Team < ApplicationRecord
  SEED_ORDER = [ 1, 16, 8, 9, 5, 12, 4, 13, 6, 11, 3, 14, 7, 10, 2, 15 ].freeze

  validates :name, presence: true, length: { maximum: 15 }, uniqueness: true

  default_scope { order(starting_slot: :asc) }

  def self.placeholder_name_for(starting_slot)
    index = starting_slot - 64
    region_label = Tournament.field_64.region_labels[index / 16]
    seed = seed_for_slot(starting_slot)
    "#{region_label} #{seed}"
  end

  def self.seed_for_slot(starting_slot)
    SEED_ORDER[starting_slot % 16]
  end

  def first_game
    Tournament.field_64.tree.at(starting_slot / 2)
  end

  def still_playing?
    Rails.cache.fetch("#{Tournament.field_64.cache_key}/#{starting_slot}/still_playing") do
      dts = Tournament.field_64.decision_team_slots
      slot = starting_slot / 2
      until dts[slot].nil?
        return false if dts[slot] != starting_slot

        slot /= 2
      end
      true
    end
  end

  def eliminated?
    !still_playing?
  end
end
