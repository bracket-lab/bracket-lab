class Invite < ApplicationRecord
  belongs_to :created_by, class_name: "User"

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :full_name, presence: true
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :set_token_and_expiration, on: :create

  scope :pending, -> { where(used_at: nil).where("expires_at > ?", Time.current) }
  scope :accepted, -> { where.not(used_at: nil) }

  def expired?
    expires_at < Time.current
  end

  def used?
    used_at.present?
  end

  def valid_for_use?
    !used? && !expired?
  end

  def pending?
    valid_for_use?
  end

  private

  def set_token_and_expiration
    self.token = generate_token
    self.expires_at = 7.days.from_now
  end

  def generate_token
    loop do
      token = SecureRandom.urlsafe_base64(32)
      break token unless Invite.exists?(token: token)
    end
  end
end
