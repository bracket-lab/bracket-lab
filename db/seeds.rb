64.times do |i|
  starting_slot = i + 64
  seed = Team.seed_for_slot(starting_slot)
  region = i / 16

  Team.find_or_create_by!(starting_slot: starting_slot) do |team|
    team.name = Team.placeholder_name_for(starting_slot)
    team.seed = seed
    team.region = region
  end
end
