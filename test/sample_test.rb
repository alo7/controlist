require 'test_helper'

class SampleTest < MiniTest::Unit::TestCase

  def setup
    @sample = Shrike::Sample.new
  end

  def test_fancy_name
    @sample.name = "Leon"
    assert_equal ">> Leon", @sample.fancy_name
  end

end
