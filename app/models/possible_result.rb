class PossibleResult < ApplicationRecord
  belongs_to :bracket

  validates :best_finish, presence: true
end
