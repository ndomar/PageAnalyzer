# Compute how long a given number (in seconds) is
# and returns the value in it's appropriate units
def compute_time_taken num
	return nil if num.nil?
	
	minute = 60.000000
	hour = 60*minute
	day = 24*hour
	week = 7*day
	year = 52*week
	if num < minute
		return "#{num} Seconds"
	elsif num < hour
		return  "#{num/minute} Minutes"
	elsif num < day
		return  "#{num/hour} Hours"
	elsif num < week
		return  "#{num/day} Days"
	elsif num < year
		return  "#{num/week} Weeks"
	elsif num > year
		return  "#{num/year} Years"	
	end
end

# Sets a string to have a certain length. If the string is
# shorter than the given length, then '..' is added to the end.
# An optional 3rd paramater can be added to specifify a line ending.
def set_name_length input, length, ending = " "
	return input if length < 5 # Cannot shorten strings to less than 5 characters
  
	str = input.clone
	if str.length < length-1
		str << ending
		begin 
			str << " "
		end while str.length < length
	elsif str.length >= length-1
		if ending.eql? " "
			str = str[0..length-4]
			str << ".. "
		else
			str = str[0..length-5]
			str << "..#{ending} "
		end
	else
		str << "#{ending} "
	end
	return str.gsub("_", " ")
end

# Checks to see if all details required to use a bot on Wikipedia re present
def login_present? username, password, useragent
	if username.nil? || password.nil?
		return [false, "X No username and password supplied.\n		If you want to use a bot, please edit the 'config/bot_login.rb' file"]
	elsif useragent.nil? || useragent.eql?("") || useragent.eql?(" ")
		return [false, "X No user agent provided. This needs to be set. Please edit the config/bot_login.rb file.\n Otherwise Wikipedia block you!"]
	end
	return true
end

# Strip any encoding shouldn't be in xml
def strip str
	if !str.nil?
		str.gsub! "<", "&lt;"
		str.gsub! ">", "&gt;"
		str.gsub! "&", "&amp;"
	end
	return str
end

# Remove a supplied string from the given file
def remove_string_from_file filename, str_to_remove
	string = File.read filename
	if string.include? str_to_remove
		string = string.gsub! str_to_remove, ""
		File.open(filename, "w"){|f| f.write(string)}
	end
end