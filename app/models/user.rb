class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :brackets, dependent: :destroy

  validates :full_name, presence: true
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def brackets_paid?
    payment_credits >= brackets.count
  end
end
