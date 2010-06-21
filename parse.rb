# This parses the information in an xml doc downloaded using the scrape2.rb script
# This is the script that will extract all the information we want
["rubygems", "happymapper", "digest/sha1", "functions", "xml_definitions"].each {|x| require x}
pages = File.read("pages.txt").split

pages.each do |page|
  @user_hash = {}; @unreg_hash = {}; @reg_hash = {} # Initialise/Empty User Hashes for each page
  
  begin
    xml_string = File.read "pages/#{page}.xml"
  rescue => err #Oh shit, something went wrong. Deal with it.
    puts "Oh fiddle-sticks, something went wrong! Try running the scrape.rb file again to make sure that we have all the files we're looking for"
    err
  end
  
  puts "\n------------------------------------------------- \n  #{page.capitalize}:\n "
  revs = []
  revisions = Rev.parse xml_string # Use HappyMapper to make an array of the revisions
  
  revisions.reverse.each do |rev|
    # What must be done on each revision
    @user_hash[rev.user] = @user_hash.fetch(rev.user, 0)+1    # Collect user information
    rev.hash = Digest::SHA1.hexdigest rev.text                # Set the hash value (a hash of the text) for each revisions
    
    revert? rev, revs
    if revs.length > 2
      compute_intermediate_revision rev, revs.last, revs
      # process_text @first, @second, @third
    end
    revs.push rev
    
    
    # puts rev.comment
    # puts "Text:       #{rev.text}"
    # puts "Revid:      #{rev.revid.to_s}, Parentid:  #{rev.parentid.to_s}"
    # puts "User:       #{rev.user} "
    # puts "Timestamp:  #{rev.timestamp.to_s}"
    # puts "Comment:    #{rev.comment}"
    # puts "-----------------------------------------------"
    puts "------"
  end
end
# puts Time.parse(rev.timestamp).to_i
# process_user_hash user_hash
# 
# puts "List of all users"
# user_hash.keys.sort.each { |key| puts "  #{key}:     "+user_hash[key].to_s }
# 
# puts "List of registered users"
# @reg_hash.keys.sort.each { |key| puts "  #{key}:     "+user_hash[key].to_s }
# 
# puts "List of unregistered IPs"
# @unreg_hash.keys.sort.each { |key| puts "  #{key}:     "+user_hash[key].to_s }