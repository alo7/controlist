require 'test_helper'

class UserTest < ActiveSupport::TestCase

  def setup
  end

  def test_count
    assert_equal 2, User.all.size
  end

end
