class AddRegionLabelsToTournaments < ActiveRecord::Migration[8.1]
  def change
    add_column :tournaments, :region_labels, :json, default: [ "South", "West", "East", "Midwest" ], null: false
  end
end
