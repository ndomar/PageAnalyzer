# This parses the information in an xml doc downloaded using the scrape2.rb script
# This is the script that will extract all the information we want.
["rubygems", "happymapper", "digest/sha1", "functions", "definitions/xml_definitions", "amatch"].each {|x| require x}
include Amatch
STDOUT.sync = true

pages = File.read("pages.txt").split
@folder = "parsed_data"

@bot_list_file = ""

if !File.directory? @folder # If a directectory called pages does not exist in the current folder, create it.
  puts "\nCreated the #{@folder} folder to store parsed data"
  Dir.mkdir @folder
end

#--------------------------------------------------------------------------------------------------------------------------------------------------------------# 
# Process the list of registered bots we have downloaded from wikipedia
print "  Processing Bot List"
#--------------------------------------------------------------------------------------------------------------------------------------------------------------# 
U.parse(File.read "scraped_data/bot_list.xml").each {|bot| @bot_list_file += bot.name+"\n" }
File.open("#{@folder}/bot_list.xml", "w"){|f| f.write(@bot_list_file)}
@bot_list =  File.read("#{@folder}/bot_list.xml").split("\n")
puts " ✓"
#--------------------------------------------------------------------------------------------------------------------------------------------------------------# 
# Processing files downloaded from wikipedia.
puts "  Processing files downloaded from wikipedia:"
puts "    #{set_name_length "Page"} Revisions, Links"
#--------------------------------------------------------------------------------------------------------------------------------------------------------------# 
start = Time.now

pages.each do |page|
  print "    #{set_name_length page.clone.capitalize}"
  @user_hash = {}; @unreg_hash = {}; @reg_hash = {} # Initialise/Empty User Hashes for each page
  
  # Create the two files we will be editing for this page
  File.open("#{@folder}/revisions_#{page}.xml", "w"){|f| f.write("<?xml version=\"1.0\"?><revisions>")}
  File.open("#{@folder}/page_#{page}.xml", "w"){|f| f.write("<?xml version=\"1.0\"?><page><name>#{page}</name><revisions></revisions></page>")}
  
  data_string = File.read "scraped_data/#{page}.xml"    # Get the scraped data (revisions) for this page
  
  revs = []
  revisions = Rev.parse data_string                     # Use HappyMapper to make an array of the revisions
  revisions.reverse.each do |rev|
    if !rev.text.nil?      
      process_revision rev, revs, page         # What must be done on each revision/revision_file
      user_add_revision rev.user, page, rev.revid
      page_add_revision page, rev.user, rev.revid
      # puts "------"
    end
    # if !@prev.nil?
    #   puts @prev.text.levenshtein_similar rev.text
    # end
    # @prev = rev
    
    # Once the last revision is reached, make sure to save any leftover revisions
    if rev === revisions.last
      revision_add_revision revs.fetch(revs.length-2), revert?(rev, revs), page
      revision_add_revision rev, revert?(rev, revs), page
    end
  end
  File.open("#{@folder}/revisions_#{page}.xml", "a"){|f| f.write("</revisions>")}
  data_string = nil
  revisions = nil
  print "    ✓"
  
  link_string = File.read "scraped_data/#{page}_links.xml" # Get the scraped data (links) for this page
  links = Bl.parse link_string
  
  # Parse and organise the list of links
  link_text = "<links>"
  links.each do |link|
    link_text += "<link pageid=\"#{link.pageid}\" title=\"#{link.title}\">"
  end
  link_text += "</links>"
  
  page_add_links page, link_text # Insert the links into the page file
  puts "        ✓"
end

# Print out a report of the key stats
puts "\nTime to complete this run: #{compute_time_taken(Time.now-start)}"
print "\a\a\a\a\a\a\a\a\a\a"
