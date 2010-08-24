require "test/unit"
$: << File.join(File.dirname(__FILE__), "/../")
require "scripts/functions"

class TestFunctions < Test::Unit::TestCase
  def test_bad_edit
    assert_equal bad_edit?(1, 2, 3), "+"
    assert_equal bad_edit?(3, 2, 3), "-"
  end
  
  def test_login_present?
    assert login_present? "Chris", "Salij", "test"
    assert !(login_present? nil,nil,nil)
  end
  
  def test_set_name_length
    array = [
      "",
      "1",
      "12",
      "123",
      "1234",
      "12345",
      "123456",
      "1234567",
      "12345678",
      "123456789",
      "1234567890",
      "12345678901",
      "123456789012",
      "1234567890123",
      "12345678901234",
      "123456789012345",
      "1234567890123456",
      "12345678901234567",
      "123456789012345678",
      "1234567890123456789",
      "12345678901234567890",
      "123456789012345678901",
    ]
    (0..4).entries.each do |i|
      array.each do |a|
        assert_same set_name_length(a, i).length, a.length
        assert_same set_name_length(a, i, ":").length, a.length
      end
    end
    
    (5..200).entries.each do |i|
      array.each do |a|
        assert_same set_name_length(a, i).length, i
        assert_same set_name_length(a, i, ":").length, i
      end
    end
  end
end
