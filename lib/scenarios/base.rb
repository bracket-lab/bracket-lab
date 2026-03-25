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
      "Champion Picks", "Cinderella Story", "Final Four Frenzy", "March Magic",
      "Bracket Buster", "Sweet 16 Dreams", "Elite Eight Express", "Underdog Special",
      "Chalk Talk", "Upset City", "The Favorite", "Dark Horse",
      "Lucky Picks", "Statistical Edge", "Gut Feeling", "Championship Run",
      "Madness Method", "Seeds of Victory", "Bracket Science", "Wild Card",
      "Perfect Storm", "Buzzer Beater", "Net Results", "Court Vision", "Hoop Dreams"
    ].freeze

    def call
      ensure_admin
      ensure_users
      ensure_teams
      setup
    end

    private

    def ensure_admin
      return if User.exists?(admin: true)

      admin_attrs = USERS.find { |u| u[:admin] }
      User.create!(
        full_name: admin_attrs[:full_name],
        email_address: admin_attrs[:email_address],
        password: "password",
        admin: true
      )
    end

    def ensure_users
      return if User.count >= USERS.size

      USERS.reject { |u| u[:admin] }.each do |attrs|
        User.find_or_create_by!(email_address: attrs[:email_address]) do |user|
          user.full_name = attrs[:full_name]
          user.password = "password"
        end
      end
    end

    def ensure_teams
      return if Team.count >= 64

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
      # 5 users get 3 brackets, 5 users get 2 brackets = 25 total
      all_users = User.all.to_a
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
      # Mix of bracket styles: 10 balanced, 8 chalk, 7 upset
      styles = []
      styles += Array.new(10, :balanced)
      styles += Array.new(8, :chalk)
      styles += Array.new(7, :upset)
      styles.shuffle
    end

    def ensure_brackets
      return if Bracket.count >= BRACKET_NAMES.size

      users = distribute_users_for_brackets
      styles = distribute_styles_for_brackets

      BRACKET_NAMES.each_with_index do |name, index|
        Bracket.find_or_create_by!(name: name) do |bracket|
          bracket.user = users[index]
          bracket.game_decisions = Generators::BracketGenerator.new(styles[index]).call
        end
      end
    end

    def set_tournament_state(state, num_games: 0, gap_slots: nil)
      t = tournament
      t.set_teams! if t.pre_selection?

      if num_games > 0
        result = Generators::TournamentGenerator.new(num_games, gap_slots: gap_slots).call
        result.apply_to(t)
      else
        t.update!(state: state, game_decisions: 0, game_mask: 0)
      end

      t.start! if state == :in_progress && t.not_started?
      t.completed! if state == :completed
    end
  end
end
