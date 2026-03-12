# frozen_string_literal: true

module Scenarios
  # Base class for development scenarios that set up test data.
  # Subclasses implement #setup to create specific tournament states.
  #
  # Usage:
  #   Scenarios::States::PreSelection.new.call
  #
  class Base
    USERS = [
      { full_name: "Admin User", email_address: "admin@example.com", admin: true },
      { full_name: "Jordan Smith", email_address: "jordan@example.com" },
      { full_name: "Taylor Johnson", email_address: "taylor@example.com" },
      { full_name: "Casey Williams", email_address: "casey@example.com" },
      { full_name: "Morgan Brown", email_address: "morgan@example.com" },
      { full_name: "Riley Davis", email_address: "riley@example.com" },
      { full_name: "Avery Miller", email_address: "avery@example.com" },
      { full_name: "Quinn Wilson", email_address: "quinn@example.com" },
      { full_name: "Drew Anderson", email_address: "drew@example.com" },
      { full_name: "Sam Martinez", email_address: "sam@example.com" }
    ].freeze

    TEAM_NAMES = [
      "Auburn", "Alabama St", "Louisville", "Creighton", "Michigan", "UC San Diego", "Texas A&M", "Yale",
      "Ole Miss", "N Carolina", "Iowa St", "Lipscomb", "Marquette", "New Mexico", "Michigan St", "Bryant",
      "Florida", "Norfolk St", "UConn", "Oklahoma", "Memphis", "Colorado St", "Maryland", "Grand Canyon",
      "Missouri", "Drake", "Texas Tech", "UNCW", "Kansas", "Arkansas", "St John's", "Omaha",
      "Duke", "Mnt St Mary's", "Miss St", "Baylor", "Oregon", "Liberty", "Arizona", "Akron",
      "BYU", "VCU", "Wisconsin", "Montana", "St Mary's", "Vanderbilt", "Alabama", "Robert Morris",
      "Houston", "SIUE", "Gonzaga", "Georgia", "Clemson", "McNeese", "Purdue", "High Point",
      "Illinois", "Xavier", "Kentucky", "Troy", "UCLA", "Utah St", "Tennessee", "Wofford"
    ].freeze

    BRACKET_NAMES = [
      "Champion Picks",
      "Cinderella Story",
      "Final Four Frenzy",
      "March Magic",
      "Bracket Buster",
      "Sweet 16 Dreams",
      "Elite Eight Express",
      "Underdog Special",
      "Chalk Talk",
      "Upset City",
      "The Favorite",
      "Dark Horse",
      "Lucky Picks",
      "Statistical Edge",
      "Gut Feeling",
      "Championship Run",
      "Madness Method",
      "Seeds of Victory",
      "Bracket Science",
      "Wild Card",
      "Perfect Storm",
      "Buzzer Beater",
      "Net Results",
      "Court Vision",
      "Hoop Dreams"
    ].freeze

    def call
      clear_data
      create_users
      ensure_teams
      setup
    end

    private

    def clear_data
      Bracket.destroy_all
      User.destroy_all
      Tournament.destroy_all
    end

    def create_users
      password = ENV.fetch("DEV_PASSWORD") { raise "DEV_PASSWORD environment variable is required" }

      USERS.each do |attrs|
        User.create!(
          full_name: attrs[:full_name],
          email_address: attrs[:email_address],
          password: password,
          admin: attrs[:admin] || false
        )
      end
    end

    def ensure_teams
      TEAM_NAMES.each_with_index do |name, i|
        starting_slot = i + 64
        seed = Team.seed_for_slot(starting_slot)
        region = i / 16

        team = Team.find_or_create_by!(starting_slot: starting_slot) do |t|
          t.seed = seed
          t.region = region
        end
        team.update!(name: name)
      end
    end

    def setup
      raise NotImplementedError, "Subclasses must implement #setup"
    end

    # Helper methods for subclasses

    def admin_user
      User.find_by(admin: true)
    end

    def regular_users
      User.where(admin: false)
    end

    def tournament
      Tournament.field_64
    end

    def distribute_users_for_brackets
      # Distribute 25 brackets across 10 users (roughly 2-3 per user)
      # Give some users 3 brackets, others 2 brackets
      all_users = User.all.to_a

      # 5 users get 3 brackets, 5 users get 2 brackets = 25 total
      distribution = []

      all_users.first(5).each do |user|
        3.times { distribution << user }
      end

      all_users.last(5).each do |user|
        2.times { distribution << user }
      end

      distribution.shuffle
    end

    def distribute_styles_for_brackets
      # Mix of bracket styles for variety:
      # - 10 balanced (most common picking style)
      # - 8 chalk (favoring favorites)
      # - 7 upset (favoring underdogs)
      styles = []
      styles += Array.new(10, :balanced)
      styles += Array.new(8, :chalk)
      styles += Array.new(7, :upset)
      styles.shuffle
    end

    def create_brackets
      users = distribute_users_for_brackets
      styles = distribute_styles_for_brackets

      BRACKET_NAMES.each_with_index do |name, index|
        user = users[index]
        style = styles[index]
        game_decisions = Generators::BracketGenerator.new(style).call

        Bracket.create!(
          name: name,
          user: user,
          game_decisions: game_decisions
        )
      end
    end

    # Common setup for scenarios with brackets in an active tournament.
    # Creates tournament, sets teams, creates 25 brackets, starts tournament.
    def create_tournament_in_progress
      t = Tournament.create!(state: :pre_selection)
      t.set_teams!
      create_brackets
      t.start!
    end
  end
end
