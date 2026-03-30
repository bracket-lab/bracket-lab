Rails.application.config.to_prepare do
  ActiveRecord::Type.register(:shifted_bitwise, ShiftedBitwiseType)
end
