# frozen_string_literal: true

namespace :dev do
  desc "List scenarios or reset to a specific scenario state"
  task :scenarios, [ :scenario ] => :environment do |_t, args|
    unless Rails.env.development? || Rails.env.test?
      puts "ERROR: This task can only run in development or test environments"
      puts "Current environment: #{Rails.env}"
      exit 1
    end

    scenario = args[:scenario]

    if scenario.blank?
      puts "Available scenarios:"
      puts "  pre_selection   - No tournament"
      puts "  pre_tipoff      - Tournament set, brackets editable"
      puts "  tipoff          - Locked, no results"
      puts "  some_games      - ~10 Round 1 games"
      puts "  first_weekend   - 48 games (R1+R2)"
      puts "  mid_tournament  - 50 games with Sweet 16 gaps"
      puts "  final_four      - 60 games (3 remain)"
      puts "  completed       - All 63 games"
      puts
      puts "Usage: rake dev:scenarios[scenario_name]"
    else
      klass = "Scenarios::States::#{scenario.camelize}".constantize
      klass.new.call
      puts "Reset to #{scenario}"
    end
  rescue NameError
    puts "Unknown scenario: #{scenario}"
    puts "Run `rake dev:scenarios` to see available options"
    exit 1
  end
end
