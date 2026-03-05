class Admin::InvitesController < Admin::BaseController
  def index
    @invites = Invite.pending.order(created_at: :desc)
  end

  def new
    @invite = Invite.new
  end

  def create
    @invite = Invite.new(invite_params)
    @invite.created_by = Current.user

    if @invite.save
      InvitesMailer.invite(@invite).deliver_later
      redirect_to admin_invites_path, notice: "Invitation sent successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @invite = Invite.includes(:created_by).find(params[:id])
  end

  def destroy
    @invite = Invite.find(params[:id])
    if @invite.pending?
      @invite.destroy
      redirect_to admin_invites_path, notice: "Invite was successfully deleted."
    else
      redirect_to admin_invites_path, alert: "Only pending invites can be deleted."
    end
  end

  def bulk_new
  end

  def bulk_preview
    @valid_invites = []
    @invalid_invites = []

    params[:bulk_invites].to_s.split("\n").each do |line|
      line.strip!
      next if line.blank?

      if line =~ /^(.+?)\s*<([^>]+)>$/
        name = $1.strip
        email = $2.strip

        invite = Invite.new(
          email_address: email,
          full_name: name,
          created_by: Current.user
        )

        if invite.valid?
          @valid_invites << { name: name, email: email }
        else
          @invalid_invites << { line: line, error: invite.errors.full_messages.join(", ") }
        end
      else
        @invalid_invites << { line: line, error: "Invalid format. Expected: Full Name <email@address.com>" }
      end
    end

    @preview_data = { valid_invites: @valid_invites, invalid_invites: @invalid_invites }
    render turbo_stream: turbo_stream.update("bulk_preview", partial: "admin/invites/bulk_preview_content")
  end

  def bulk_create
    results = { success: [], error: [] }

    (params[:invites] || []).each do |invite_params|
      if invite_params[:email].present?
        invite = Invite.new(
          email_address: invite_params[:email],
          full_name: invite_params[:name],
          created_by: Current.user
        )

        if invite.save
          InvitesMailer.invite(invite).deliver_later
          results[:success] << invite
        end
      end
    end

    redirect_to admin_invites_path,
      notice: "Successfully sent #{results[:success].size} invites."
  end

  private

  def invite_params
    params.require(:invite).permit(:email_address, :full_name)
  end
end
