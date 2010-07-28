require "functions"

if ARGV[0] then user_file = ARGV[0] else user_file = "user.csv" end
File.open(user_file, "w"){|f| f.write("Pagename,User Count,Reliable User Count,Reliable User Percentage,Reliable User Edit Count,Reliable User Edit Percentage,Other User Count,Other User Percentage,Other User Edit Count,Other User Edit Percentage,Revert Count,Link Count\n")}


start = Time.now
  pagename = 0
  user_count = 0
  reliable_user_count = 0
  reliable_user_percentage = 0
  reliable_user_edit_count = 0
  reliable_user_edit_percentage = 0
  other_user_count = 0
  other_user_percentage = 0
  other_user_edit_count = 0
  other_user_editpercentage = 0
  revert_count = 0
  link_count = 0


  # Pagename, User Count, Reliable User Count, Reliable User Percentage, Reliable User Edit Count, Reliable User Edit Percentage, Other User Count, Other User Percentage, Other User Edit Count, Other User Edit Percentage, Revert Count, Link Count

  str = name.to_s+","+bot.to_s+","+edit_count.to_s+","+reverted_to.to_s+","+reverted_over.to_s+","+pages_count.to_s+","+rating.to_s+"\n"
  File.open(user_file, "a"){|f| f.write(str)}

puts "\n\nTime to complete this run: #{compute_time_taken(Time.now-start)}\n"
print "\a\a\a\a\a\a\a\a\a\a"
