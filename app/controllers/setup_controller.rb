class SetupController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :check_setup_complete
  layout "authentication"

  def new
    redirect_to root_path if User.exists?
    @user = User.new
  end

  def create
    @user = User.new(user_params.merge(admin: true))

    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: "Welcome! Your admin account has been created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :full_name, :password, :password_confirmation)
  end
end
