require "test_helper"

class CurrentTest < ActiveSupport::TestCase
  test "tournament lazy loads the field 64 tournament" do
    tournament = Tournament.field_64
    assert_equal tournament, Current.tournament
  end
end
