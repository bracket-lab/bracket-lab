class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :tournament

  delegate :user, to: :session, allow_nil: true

  def tournament
    attributes[:tournament] ||= Tournament.field_64
  end
end
