# This parses the information in an xml doc downloaded using the scrape2.rb script
# This is the script that will extract all the information we want.
["rubygems", "happymapper", "digest/sha1", "functions", "xml_definitions"].each {|x| require x}
pages = File.read("pages.txt").split

pages.each do |page|
  @user_hash = {}; @unreg_hash = {}; @reg_hash = {} # Initialise/Empty User Hashes for each page
  @revision_file = "<?xml version=\"1.0\"?><revisions>"
  
  begin
    xml_string = File.read "pages/#{page}.xml"
  rescue => err # Oh shit, something went wrong. Deal with it.
    puts "Oh fiddle-sticks, something went wrong! Try running the scrape.rb file again to make sure that we have all the files we're looking for"
    err
  end
  
  puts "\n------------------------------------------------- \n  #{page.capitalize}:\n "
  revs = []
  revisions = Rev.parse xml_string  # Use HappyMapper to make an array of the revisions
  
  revisions.reverse.each do |rev|
    revert = process_revision rev, revs      # What must be done on each revision@revision_file
    
    puts "------"
  end
  @revision_file += "</revisions>"
  File.open("data/page_#{page}.xml", "w"){|f| f.write(@revision_file)} 
end
# process_user_hash
# puts @reg_hash.count
# puts @unreg_hash.count

# puts "List of all users"
# @user_hash.keys.sort.each { |key| puts "  #{key}:     " +@user_hash[key].to_s }
# 
# puts "List of registered users"
# @reg_hash.keys.sort.each { |key| puts "  #{key}:     "  +@user_hash[key].to_s }
# 
# puts "List of unregistered IPs"
# @unreg_hash.keys.sort.each { |key| puts "  #{key}:     "+@user_hash[key].to_s }