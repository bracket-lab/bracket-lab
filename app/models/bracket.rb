class Bracket < ApplicationRecord
  include ShiftedBitwiseColumns
  shifted_bitwise_columns :game_decisions

  FULL_BRACKET_MASK = 0xFFFFFFFFFFFFFFFE

  POINTS_PER_ROUND = [ 0, 1, 2, 3, 5, 8, 13 ].freeze

  belongs_to :user

  validates :name, presence: true, uniqueness: true
  validates :game_decisions, presence: true

  def paid?
    position = user.brackets.order(:created_at).pluck(:id).index(id)
    position.present? && position < user.payment_credits
  end

  def final_four_teams
    sorted_four_team_slots.map { |slot| Team.find_by(starting_slot: slot) }
  end

  def points
    @points ||= begin
                  tournament_slots = Current.tournament.decision_team_slots
                  points_for(tournament_slots)
                end
  end

  def points_for(tournament_slots)
    (1..63).reduce(0) do |acc, i|
      t = tournament_slots[i]
      b = decision_team_slots[i]
      if t.present? && t == b
        team_seed = Team.seed_for_slot(b)
        round_number = Round.round_num_for_slot(i)
        acc + POINTS_PER_ROUND[round_number] + team_seed
      else
        acc
      end
    end
  end

  def possible_points
    @possible_points ||= begin
                           tournament_slots = Current.tournament.decision_team_slots
                           eliminated_picks = Set.new

                           (1..63).to_a.reverse.reduce(0) do |acc, i|
                             t_slot = tournament_slots[i]
                             b_slot = decision_team_slots[i]

                             if eliminated_picks.include?(b_slot)
                               acc
                             elsif t_slot.present? && b_slot != t_slot
                               eliminated_picks.add(b_slot)
                               acc
                             else
                               team_seed = Team.seed_for_slot(b_slot)
                               round_number = Round.round_num_for_slot(i)
                               acc + POINTS_PER_ROUND[round_number] + team_seed
                             end
                           end
                         end
  end

  def eliminated?
    return false unless Current.tournament.display_eliminations?
    best_finish.nil? || best_finish > 5
  end

  def best_finish
    OutcomeRanking.where(bracket_id: id).minimum(:rank)
  end

  def tree
    TournamentTree.unmarshal(Current.tournament, game_decisions, FULL_BRACKET_MASK)
  end

  private

  def sorted_four_team_slots
    Array(decision_team_slots[1..7]).uniq.reverse
  end

  def decision_team_slots
    @decision_team_slots ||= begin
                               result = Array.new(64)

                               (1..63).to_a.reverse.each do |i|
                                 current_position = 1 << i
                                 decision = self.game_decisions.nobits?(current_position) ? 0 : 1
                                 position = (i * 2) + decision

                                 result[i] = i >= 32 ? position : result[position]
                               end

                               result
                             end
  end
end
