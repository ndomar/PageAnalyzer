# This parses the information in an xml doc downloaded using the scrape2.rb script
# This is the script that will extract all the information we want.
["rubygems", "happymapper", "digest/sha1", "functions", "definitions/xml_definitions"].each {|x| require x}
pages = File.read("pages.txt").split
start = Time.now

pages.each do |page|
  @user_hash = {}; @unreg_hash = {}; @reg_hash = {} # Initialise/Empty User Hashes for each page
  File.open("data/revisions_#{page}.xml", "w"){|f| f.write("<?xml version=\"1.0\"?><revisions>")}
  @user_file = "<?xml version=\"1.0\"?><user>"
  File.open("data/page_#{page}.xml", "w"){|f| f.write("<?xml version=\"1.0\"?><page><name>#{page}</name><revisions></revisions></page>")}
  
  begin
    data_string = File.read "pages/#{page}.xml"
    link_string = File.read "pages/#{page}_links.xml"
  rescue => err # Oh shit, something went wrong. Deal with it.
    puts "Oh fiddle-sticks, something went wrong! Try running the scrape.rb file again to make sure that we have all the files we're looking for"
    err
  end
  
  puts "\n------------------------------------------------- \n  #{page.capitalize}:\n "
  revs = []
  revisions = Rev.parse data_string              # Use HappyMapper to make an array of the revisions
  
  revisions.reverse.each do |rev|
    if !rev.text.nil?
      process_revision rev, revs, page         # What must be done on each revision@revision_file
      user_add_revision rev.user, page, rev.revid
      page_add_revision page, rev.user, rev.revid
      # puts "------"
    end
  end
  
  File.open("data/revisions_#{page}.xml", "a"){|f| f.write("</revisions>")}
  
  links = Bl.parse link_string
  link_text = "<links>"
  links.each do |link|
    link_text += "<link pageid=\"#{link.pageid}\" title=\"#{link.title}\">"
  end
  link_text += "</links>"
  page_add_links page, link_text
  
end
puts Time.now-start