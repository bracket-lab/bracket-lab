class Team < ApplicationRecord
  REGION_NAMES = [ :south, :west, :east, :midwest ]
  SEED_ORDER = [ 1, 16, 8, 9, 5, 12, 4, 13, 6, 11, 3, 14, 7, 10, 2, 15 ].freeze

  validates :name, length: { maximum: 15 }

  default_scope { order(starting_slot: :asc) }

  enum :region, REGION_NAMES, suffix: true

  def self.region_names
    REGION_NAMES
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
