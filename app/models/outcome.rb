class Outcome < ApplicationRecord
  has_many :outcome_rankings, dependent: :destroy
end
