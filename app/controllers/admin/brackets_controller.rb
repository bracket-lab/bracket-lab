class Admin::BracketsController < Admin::BaseController
  def index
    @brackets = Bracket.all.sort_by do |b|
      paid = b.paid? ? 1 : 0
      [ paid, b.user_id, b.created_at ]
    end
  end

  def destroy
    @bracket = Bracket.find(params[:id])
    @bracket.destroy
    redirect_to admin_brackets_path, notice: "Bracket was successfully deleted."
  end
end
