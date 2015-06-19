require 'test_helper'

class DBTest < ActiveSupport::TestCase

  def setup
  end

  def test_count
    c = User.all.count
    assert_equal 0, c
  end

end
