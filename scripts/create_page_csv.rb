require "functions"

if ARGV[0] then user_file = ARGV[0] else user_file = "pages.csv" end
File.open(user_file, "w"){|f| f.write("Pagename,Edit Count,Link Count,Revert Count,User Count,Reliable User Count,Other User Count,Reliable User Percentage,Other User Percentage,Reliable User Edit Percentage,Other User Edit Percentage,Rating\n")}
STDOUT.sync = true
start = Time.now

# Create user rating table
print "Compiling User Rating Table:"
user_rank = {}
for file in Dir['./parsed_data/user_*']
  user = User.parse File.read "#{file}"
  if !user.rating.nil?
    user_rank[user.name] = user.rating
  end
end
print "  ✓\n"

# good_pages = File.read("pages/Articles_FA.txt").split
# good_pages += File.read("pages/Articles_A.txt").split
# good_pages += File.read("pages/Articles_GA.txt").split
# 
# medium_pages = File.read("pages/Articles_B.txt").split
# medium_pages += File.read("pages/Articles_C.txt").split
# 
# poor_pages = File.read("pages/Articles_Start.txt").split
# poor_pages += File.read("pages/Articles_Stub.txt").split

good_pages = File.read("pages/Articles_FA.txt").split
good_pages += File.read("pages/Articles_A.txt").split
good_pages += File.read("pages/Articles_GA.txt").split
good_pages += File.read("pages/Articles_B.txt").split

medium_pages = File.read("pages/Articles_C.txt").split

poor_pages = File.read("pages/Articles_Start.txt").split
poor_pages += File.read("pages/Articles_Stub.txt").split

# user_rank.keys.each do |user|
#   puts user+" "+user_rank[user]
# end

for file in Dir['./parsed_data/page_*']
  name                          = 0
  edit_count                    = 0
  user_count                    = 0
  link_count                    = 0
  revert_count                  = 0
  reliable_user_count           = 0
  reliable_user_percentage      = 0
  reliable_user_edit_count      = 0
  reliable_user_edit_percentage = 0
  other_user_count              = 0
  other_user_percentage         = 0
  other_user_edit_count         = 0
  other_user_edit_percentage    = 0
  anon_user_count               = 0
  anon_user_percentage          = 0
  anon_user_edit_count          = 0
  anon_user_edit_percentage     = 0
  
  page = Page.parse File.read "#{file}"
  
  name = page.name
  # Compiling User Contribution table
  user_hash = {}
  page.revisions.each do |revision|
   edit_count += 1
   user_hash[revision.user] = user_hash.fetch(revision.user, 0) + 1
  end
  user_count = user_hash.length
  
  # Compute the edits made by each type of user
  user_hash.keys.each do |user|
    if user_rank.include? user
      if user_rank[user] == "reliable"
        reliable_user_count += 1
        reliable_user_edit_count += user_hash[user]
      elsif user_rank[user] == "other"
        other_user_count += 1
        other_user_edit_count += user_hash[user]
      end
    else
      anon_user_count += 1
      anon_user_edit_count += user_hash[user]
    end
  end
  
  reliable_user_percentage      = reliable_user_count/(user_count*1.0000)
  other_user_percentage         = other_user_count/(user_count*1.0000)
  anon_user_percentage          = anon_user_count/(user_count*1.0000)
  
  reliable_user_edit_percentage = reliable_user_edit_count/(edit_count*1.000)
  other_user_edit_percentage    = other_user_edit_count/(edit_count*1.000)
  anon_user_edit_percentage     = anon_user_edit_count/(edit_count*1.000)
  
  page.links.each do |link|
    link_count+= 1
  end
  
  page = nil
  revisions = Revision.parse File.read "#{@parse_folder}/revisions_#{name}.xml"
  revisions.each do |revision|
    if !revision.revertid.nil?
      revert_count += 1
    end
  end
  page = nil
  
  if good_pages.include? name
    rating = "good"
  elsif medium_pages.include? name
    rating = "medium"
  elsif poor_pages.include? name
    rating = "poor"
  else # This shouldn't happen. If it does, something went wrong
    rating = "Fuck"
  end
  
  # puts "Name: "+name
  # puts "Edit: "+edit_count.to_s
  # puts "Link: "+link_count.to_s
  # puts "#Rev: "+revert_count.to_s
  # puts "User: "+user_count.to_s
  # puts "User Count: "
  # puts "  Reliable: "+reliable_user_count.to_s
  # puts "  Other:    "+other_user_count.to_s
  # puts "  Anon:     "+anon_user_count.to_s
  # puts "User Percentage: "
  # puts "  Reliable: "+reliable_user_percentage.to_s
  # puts "  Other:    "+other_user_percentage.to_s
  # puts "  Anon:     "+anon_user_percentage.to_s
  # puts "User Edit Percentage: "
  # puts "  Reliable: "+reliable_user_edit_percentage.to_s
  # puts "  Other:    "+other_user_edit_percentage.to_s
  # puts "  Anon:     "+anon_user_edit_percentage.to_s
  # puts
  
  name.gsub! "'", ""
  name.gsub! ",", ""
  if rating.eql? "medium"
    puts set_name_length(name)+"    "+rating+":    ✓"
    #     Pagename,Edit Count,         Link Count,         Revert Count,         User Count,         Reliable User Count,         Other User Count        Reliable User Percentage,        Other User Percentage,                  Reliable User Edit Percentage,         Other User Edit Percentage,                 Rating
    str = name+","+edit_count.to_s+","+link_count.to_s+","+revert_count.to_s+","+user_count.to_s+","+reliable_user_count.to_s+","+(other_user_count+anon_user_count).to_s+","+reliable_user_percentage.to_s+","+(other_user_percentage+anon_user_percentage).to_s+","+reliable_user_edit_percentage.to_s+","+(other_user_edit_percentage+anon_user_edit_percentage).to_s+","+rating+"\n"
    File.open(user_file, "a"){|f| f.write(str)}
  end
end

puts "\n\nTime to complete this run: #{compute_time_taken(Time.now-start)}\n"
print "\a\a\a\a\a\a\a\a\a\a"
