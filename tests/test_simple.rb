require "test/unit"
$: << File.join(File.dirname(__FILE__), "/../")
require "functions"

class TestFunctions < Test::Unit::TestCase
  def test_bad_edit
    assert_equal bad_edit?(1, 2, 3), "+"
    assert_equal bad_edit?(3, 2, 3), "-"
  end
end
