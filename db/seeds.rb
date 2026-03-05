# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


Team.delete_all

CSV.read(Rails.root.join('data/teams.csv').to_s).map.with_index do |row, i|
  name = row.first
  starting_slot = i + 64
  seed = Team.seed_for_slot(starting_slot)
  region = i / 16

  Team.create!(starting_slot:, name:, seed:, region:)
end
