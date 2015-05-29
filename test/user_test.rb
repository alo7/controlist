require 'test_helper'

class UserTest < ActiveSupport::TestCase

  def test_count
    assert_equal 2, User.count
  end

end
