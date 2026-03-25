# Game Decisions and Masks are used in code as a 1-offset array but stored
# shifted right to fit in a 64-bit signed int >= 0
module ShiftedBitwiseColumns
  MAX_INT64 = 0x7FFFFFFFFFFFFFFF # 2^63 - 1

  extend ActiveSupport::Concern

  class_methods do
    def shifted_bitwise_columns(*columns)
      columns.each do |col|
        define_method(col) do
          value = super()
          return 0 if value.nil?
          value << 1
        end

        define_method(:"#{col}=") do |value|
          self[col] = (Integer(value) >> 1) & MAX_INT64
        end
      end
    end
  end
end
