class AddPaymentCreditsToInvites < ActiveRecord::Migration[8.1]
  def change
    add_column :invites, :payment_credits, :integer, default: 0, null: false
  end
end
