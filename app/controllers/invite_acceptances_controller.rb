class InviteAcceptancesController < ApplicationController
  allow_unauthenticated_access

  layout "authentication"

  before_action :set_invite
  before_action :ensure_invite_valid

  def new
    @user = User.new(
      email_address: @invite.email_address,
      full_name: @invite.full_name
    )
  end

  def create
    @user = User.create(user_params.merge(email_address: @invite.email_address, full_name: @invite.full_name, payment_credits: @invite.payment_credits))

    if @user.valid?
      @invite.update!(used_at: Time.current)
      start_new_session_for(@user)
      redirect_to root_path, notice: "Welcome! Your account has been created."
    else
      redirect_to new_invite_acceptance_path(token: @invite.token), alert: "Ensure passwords match."
    end
  end

  private

  def set_invite
    @invite = Invite.find_by(token: params[:token])
    redirect_to new_session_path, alert: "Invalid or missing invite token." if @invite.nil?
  end

  def ensure_invite_valid
    unless @invite.valid_for_use?
      redirect_to new_session_path, alert: @invite.used? ? "This invite has already been used." : "This invite has expired."
    end
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
