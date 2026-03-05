class Admin::DashboardController < Admin::BaseController
  def index
    paid_brackets = User.joins(:brackets)
                         .select("users.id, users.payment_credits, COUNT(brackets.id) AS bracket_count")
                         .group("users.id, users.payment_credits")
                         .map { |u| [ u.payment_credits, u.bracket_count ].min }
                         .sum
    @bracket_stats = {
      paid: paid_brackets,
      unpaid: Bracket.count - paid_brackets
    }

    @unused_credits = User.pluck(:payment_credits).compact.sum - paid_brackets

    @total_users = User.count
    @pending_invites = Invite.pending.count
    @recent_accepted_invites = Invite.accepted.order(used_at: :desc).limit(5)
  end
end
