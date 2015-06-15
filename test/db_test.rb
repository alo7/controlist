require 'test_helper'

class DBTest < ActiveSupport::TestCase

  def setup
  end

  def test_count
    User.all.count
    c = Clazz.joins(:users).count
    p c
    assert_equal 1, c
  end

end
