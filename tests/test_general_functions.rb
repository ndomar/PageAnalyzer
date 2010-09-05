require "test/unit"
$: << File.join(File.dirname(__FILE__), "/../")
require "scripts/general_functions"

class TestFunctions < Test::Unit::TestCase
	def test_login_present
		assert login_present? "Chris", "Salij", "test"
		assert !(login_present?("Chris","Salij",nil)[0])
		assert !(login_present?(nil,nil,nil)[0])
	end
	
	def test_compute_time_taken
		assert_equal compute_time_taken(nil), nil
		assert_equal compute_time_taken(0), "0 Seconds"
		# assert_equal compute_time_taken(1), "1 Seconds"
		assert_equal compute_time_taken(30), "30 Seconds"
		# assert_equal compute_time_taken(60), "1 Minute"
		assert_equal compute_time_taken(90), "1.5 Minutes"
		# assert_equal compute_time_taken(3600), "1 Hour"
		# assert_equal compute_time_taken(7200), "2 Hours"
		# assert_equal compute_time_taken(86400), "1 Day"
		# assert_equal compute_time_taken(172800), "2 Days"
	end
	
	def test_strip
		assert_equal strip(nil), nil
		assert_equal strip(""), ""
	end
	
	# def test_set_name_length
	# 	 array = [
	# 		"",
	# 		"1",
	# 		"12",
	# 		"123",
	# 		"1234",
	# 		"12345",
	# 		"123456",
	# 		"1234567",
	# 		"12345678",
	# 		"123456789",
	# 		"1234567890",
	# 		"12345678901",
	# 		"123456789012",
	# 		"1234567890123",
	# 		"12345678901234",
	# 		"123456789012345",
	# 		"1234567890123456",
	# 		"12345678901234567",
	# 		"123456789012345678",
	# 		"1234567890123456789",
	# 		"12345678901234567890",
	# 		"123456789012345678901",
	# 	 ]
	# 	 (0..4).entries.each do |i|
	# 		array.each do |a|
	# 		  assert_same set_name_length(a, i).length, a.length
	# 		  assert_same set_name_length(a, i, ":").length, a.length
	# 		end
	# 	 end
	# 	 
	# 	 (5..200).entries.each do |i|
	# 		array.each do |a|
	# 			assert_same set_name_length(a, i).length, i
	# 			assert_same set_name_length(a, i, ":").length, i
	# 		end
	# 	 end
	# 	end
end