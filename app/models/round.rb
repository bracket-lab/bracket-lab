class Round
  NAMES = [ "Field 64", "Field 32", "Sweet 16", "Elite Eight", "Final Four", "Champion" ].freeze

  attr_reader :number

  def initialize(number:)
    @number = number
  end

  def self.round_num_for_slot(slot)
    depth = Math.log2(slot).floor + 1
    (1..NAMES.size).to_a.reverse[depth - 1]
  end

  def name
    NAMES[number - 1]
  end

  def start_date
    start_date_for(number)
  end

  def end_date
    if NAMES.last(2).include?(name)
      start_date
    else
      start_date + 1.day
    end
  end

  def regions
    Team.region_names if [ "Final Four", "Champion" ].exclude?(name)
  end

  private

  def start_date_for(round_number)
    case round_number
    when 1
      Tournament::TIP_OFF.to_date + 1.day
    when 2, 4, 6
      start_date_for(round_number - 1) + 2.days
    else
      day = start_date_for(round_number - 1) + 5.days
      day += Tournament::NUM_ROUNDS > 4 ? (round_number - 3).days : (round_number - 1).days
      day
    end
  end
end
