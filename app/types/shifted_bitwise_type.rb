class ShiftedBitwiseType < ActiveRecord::Type::Integer
  MAX_INT64 = 0x7FFFFFFFFFFFFFFF

  # DB → Ruby (reading)
  def deserialize(value)
    return 0 if value.nil?
    Integer(value) << 1
  end

  # Ruby → DB (writing + WHERE clauses)
  def serialize(value)
    return nil if value.nil?
    (Integer(value) >> 1) & MAX_INT64
  end

  # User input → Ruby (attribute assignment)
  def cast(value)
    return 0 if value.nil?
    Integer(value)
  end
end
