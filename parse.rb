# This parses the information in an xml doc downloaded using the scrape2.rb script
# This is the script that will extract all the information we want.
["rubygems", "happymapper", "digest/sha1", "functions", "xml_definitions"].each {|x| require x}
pages = File.read("pages.txt").split

pages.each do |page|
  @user_hash = {}; @unreg_hash = {}; @reg_hash = {} # Initialise/Empty User Hashes for each page
  @output = "<?xml version=\"1.0\"?>"
  begin
    xml_string = File.read "pages/#{page}.xml"
  rescue => err # Oh shit, something went wrong. Deal with it.
    puts "Oh fiddle-sticks, something went wrong! Try running the scrape.rb file again to make sure that we have all the files we're looking for"
    err
  end
  
  puts "\n------------------------------------------------- \n  #{page.capitalize}:\n "
  revs = []
  revisions = Rev.parse xml_string  # Use HappyMapper to make an array of the revisions
  @output += "<name>#{page}</name>"
  @output += "<revisions>"
  
  revisions.reverse.each do |rev|
    revert = process_revision rev, revs
    
    if !revert.nil?
      @output += "<rev revertid=\"#{revert}\">"
    else
      @output += "<rev revertid=\"\">"
    end
    
    @output += "<revid>#{rev.revid}</revid>"
    @output += "<parentid>#{rev.parentid}</parentid>"
    @output += "<user>#{rev.user}</user>"
    @output += "<timestamp>#{rev.timestamp}</timestamp>"
    @output += "<unixtime>#{Time.parse(rev.timestamp).to_i}</unixtime>"
    @output += "<age>#{rev.age}</age>"
    @output += "<comment>#{rev.comment}</comment>"
    @output += "<text>#{rev.text}</text>"
    @output += "</rev>"
    
#   <revisions>                     <!-- A list of all of the revisions of this page -->
#      <rev revertid="" >          <!-- An individual revision. Attribute stores whether this revision is a revert, and it which revision is it a revert to. -->
#        <revid></revid>               <!-- The id of a revision -->
#        <parentid></parentid>             <!-- The parent if of this revision -->
#        <user></user>               <!-- The user that made this particular revision -->
#        <timestamp></timestamp>           <!-- The date-time timestamp of this revision -->
#        <unixtime></unixtime>           <!-- The unix timestamp of this revision -->
#        <age></age>                 <!-- The edit age of the revision -1 for the most recent age-->
#        <comment></comment>             <!-- The comment included with this revision -->
#        <text xml:space="preserve"></text>      <!-- The text of this revision -->
#      </rev>
#    </revisions>

    #process_revision rev, revs      # What must be done on each revision
    
    puts "------"
  end
  @output += "</revisions></page>"
  File.open("data/page_#{page}.xml", "w"){|f| f.write(@output)} 
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