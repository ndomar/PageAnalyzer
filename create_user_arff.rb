#User
#  no of edits
#  % of positive edits
#  % of negative edits
#  
#  no of reverts
#  
#  no of reverted edits  
#  no of pages edited
["rubygems", "happymapper",  "functions", "definitions/xml_definitions", "amatch"].each {|x| require x}

Dir.chdir("./parsed_data")
for file in Dir['**/user_*']

  edit_count          = 0
  percent_positive    = 0
  percent_negative    = 0
  revert_count        = 0
  reverted_edit_count = 0
  pages_count         = 0
  bot                 = nil
  registered          = nil

  user = User.parse File.read "#{file}"

  puts "\nName: "+user.name
  puts "Bot?: "+user.bot.to_s
  puts "Reg?: "+user.registered.to_s


  bot = user.bot
  registered = user.registered
  pages_count = user.pages.length
  if user.reverted_to.nil?   then reverted_to = 0   else reverted_to = user.reverted_to     end
  if user.reverted_over.nil? then reverted_over = 0 else reverted_over = user.reverted_over end

  user.pages.each do |page|
    puts "  "+page.name
    edit_count += page.revisions.length 
    page.revisions.each do |revision|
      puts "    "+revision.revisionid.to_s
    end
  end

  puts
  puts "Edit Count:        "+edit_count.to_s
  puts "% Positive:        "+percent_positive.to_s
  puts "% Negative:        "+percent_negative.to_s
  puts "Reverted to:       "+reverted_to.to_s
  puts "Reverted over:     "+reverted_over.to_s
  puts "Pages Count:       "+pages_count.to_s
  puts "Bot?:              "+bot.to_s
  puts "Registered?:       "+registered.to_s
  puts 
end
