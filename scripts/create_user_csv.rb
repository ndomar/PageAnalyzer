require "amatch"

puts "\n---------- Creating User File ---------------\n\n"

File.open(@user_file, "w"){|f| f.write("Bot,Edit Count,Reverted to,Reverted over,Pagescount,Rating\n")}

STDOUT.sync = true
count = 0
start = Time.now
print "|" if ARGV[0].include?("v")
for file in Dir["#{@parsed_folder}/user_*"]
  edit_count          = 0
  percent_positive    = 0
  percent_negative    = 0
  revert_count        = 0
  reverted_edit_count = 0
  pages_count         = 0
  bot                 = nil
  registered          = nil
  rating              = nil
  
  user = User.parse File.read "#{file}"

  name        = user.name
  bot         = user.bot
  registered  = user.registered
  pages_count = user.pages.length
  if user.rating.nil?         then rating = " "      else rating = user.rating               end
  if user.reverted_to.nil?    then reverted_to = 0   else reverted_to = user.reverted_to     end
  if user.reverted_over.nil?  then reverted_over = 0 else reverted_over = user.reverted_over end

  user.pages.each do |page|
    edit_count += page.revisions.length 
  end
  
  if !name.include?(",") && !name.include?("'") && !name.include?("%") && registered === "true" # && rating.eql?(" ")
        # bot,         edit_count,         reverted to,         reverted over,        pagescount,           rating
    str = bot.to_s+","+edit_count.to_s+","+reverted_to.to_s+","+reverted_over.to_s+","+pages_count.to_s+","+rating.to_s+"\n"
    File.open(@user_file, "a"){|f| f.write(str)}
    count += 1
    (if (count % 5 == 0) then print " " end)if ARGV[0].include?("v")
    print "|" if ARGV[0].include?("v")
  end
end

File.open(@user_file, "a"){|f| f.write("true,255,255,255,255,reliable\ntrue,255,255,255,255,other\n")}

puts "#{count} users added to the #{@user_file} file."
puts "\a\nTime to create the user file: #{compute_time_taken(Time.now-start)}\n"
puts "\n---------- Finished Creating User File ------\n\n"