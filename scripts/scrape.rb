# This code is not pretty. It is not optimised, but it works.
require "curb"

if !File.directory? @scraped_folder # Create directory to store the downloaded files
	puts "Created the 'pages' folder to store downloaded data"
	Dir.mkdir @scraped_folder
end

puts "\n---------- Gathering Data -------------------\n\n"

if login_present? @username, @password, @useragent
	require "scripts/login"
	wikipedia_login
else
	puts login_present?(@username, @password, @useragent)[0]
end

#--------------------------------------------------------------------------------------------------------------------------------------------------------------# 
# Go to wikipedia and download the list of all bots currently registered on the site
puts "  Fetching bot list ✓" if ARGV[0].include?("v")
#--------------------------------------------------------------------------------------------------------------------------------------------------------------# 
bot_list = Curl::Easy.perform "http://en.wikipedia.org/w/api.php?action=query&list=allusers&augroup=bot&aulimit=max&format=xml" do |curl|   # Make the request
	curl.cookies = @cookies                       # Set the login Cookies
	curl.headers = {"User-Agent" => @useragent}
end # puts text.body_str

File.open("#{@scraped_folder}/bot_list.xml", "w"){|f| f.write(bot_list.body_str)}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------# 
# Go to wikipedia and download the data for the various pages that were requested
puts "\nFetching data from Wikipedia for the following pages"
puts " #{set_name_length("Page",19)}#{set_name_length("Revisions",11,",")}#{set_name_length("Links",7,",")}Done"
#--------------------------------------------------------------------------------------------------------------------------------------------------------------# 
revisions_per_query = 500                     # Set the maximum number of revisions per query to get (Max 500)                           # Tracks the time taken for each individual download. Not used at the moment
total_timer_start = Time.now
total_revision_count = 0
total_link_count = 0
STDOUT.sync = true

@pages.each do |page|
  print " #{set_name_length(page,20,":")}"
  last_rev = 0
  last_link = 0
  revision_count = 0
  link_count = 0
  @page_data = ""
  
  File.open("#{@scraped_folder}/#{page}.xml", "w"){|f| f.write("")}
  # Get the revisions for this page
  begin
    if @revisions_to_get < revisions_per_query
      @revisions_to_get = revisions_per_query
    end
    if last_rev == 0          # If we're on the first query, get the last X revisions starting at the most recent revision available
      query_url = "http://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=#{page}&rvprop=ids|timestamp|user|comment|content&rvlimit=#{revisions_per_query}&format=xml"
    else                      # If we're on a subsequent query, get the last X revisions starting at the revision previous to the oldest one we have on record
      query_url = "http://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=#{page}&rvprop=ids|timestamp|user|comment|content&rvlimit=#{revisions_per_query}&rvstartid=#{last_rev-1}&format=xml"
    end
    
    text = Curl::Easy.perform query_url do |curl|   # Make the request
      curl.cookies = @cookies                       # Set the login Cookies
      curl.headers = {"User-Agent" => @useragent}
    end # puts text.body_str
    
    page_data = text.body_str
    revisions_this_query = Rev.parse(text.body_str).length  # Get the amount of revisions returned in this query
    revision_count += revisions_this_query                  # Add the revisions returned in this query to the total amount for this page
    
    if last_rev != 0                                        # If we're not on the first query 
      page_data = remove_head page_data, "rev"              # remove the head of the document (XML declaration etc)
    end
    
    if revisions_this_query != 0                            # If there was were revision returned in this request
      page_data = remove_tail page_data, "rev"              # Remove the tail of the document
      
      # This adds an extra tag to each revision. It means that the text of each revision can be accessed as an element of it.
      page_data.gsub! 'xml:space="preserve">', 'xml:space="preserve"><text>'
      page_data.gsub! '</rev>', '</text></rev>'
      File.open("#{@scraped_folder}/#{page}.xml", "a"){|f| f.write(page_data)} # Append the current set of revisions to the existing ones
      last_rev = Rev.parse(text.body_str).last.revid              # Store the revision to continue on in the next query
    end
    text = nil
    page_data = nil
  end while revision_count < @revisions_to_get && revisions_this_query != 0
  
  # Finalise the data file and save 
  File.open("#{@scraped_folder}/#{page}.xml", "a"){|f| f.write("</revisions></page></pages></query></api>")} # Once we have all the results we need, append the correct ending to the file.
  total_revision_count += revision_count
  # Print the total number of revisions fetched for this page
  print set_name_length(revision_count.to_s,11,",")
  
  # Get the links pointing to this page
  begin  
    if last_link == 0                         # Get the maximum number of links to this mage
      query_url = "http://en.wikipedia.org/w/api.php?action=query&list=backlinks&bltitle=#{page}&bllimit=max&format=xml"
    else                                      # If there are more links, get as many more as possbile, starting at the most recent one gotten
      query_url = "http://en.wikipedia.org/w/api.php?action=query&list=backlinks&bltitle=#{page}&bllimit=max&blcontinue=#{last_link}&format=xml"
      @page_data = remove_tail @page_data, "bl"
    end
    
    text = Curl::Easy.perform query_url do |curl|       # Make the request
      curl.cookies = @cookies                       	# Set the login Cookies
      curl.headers = {"User-Agent" => @useragent}
    end # puts text.body_str
    
    links_this_query = Bl.parse(text.body_str).length 	# Get the amount of links returned in this query
    link_count += links_this_query
    
    if links_this_query == 0                      # If we've gotten all the links available
      @page_data += @tail                           # Add the closing tags to the document
    else                                          # Otherwise
      if last_link != 0                             # If we're not on the first request
        @page_data += remove_head text.body_str, "bl" # Remove the head of the text returned, and append it to the end of the data collected so far
      else                                          # If we are on the first request
        @page_data += text.body_str                   # Save the returned text to be used later
      end
      last_link = Backlinks.parse(text.body_str).last.blcontinue # Get the point from which we should continue
    end
  end while links_this_query > 0                # While there is still more to get, get more links
  
  File.open("#{@scraped_folder}/#{page}_links.xml", "w"){|f| f.write(@page_data)}
  # Print the total number of links gathered for this page
  print set_name_length(link_count.to_s,7,",")
  total_link_count += link_count
  
  puts " ✓" # Prints a tick to show that this section is done.
end

# Prints a report of the all the data which has been gathered
puts "\a"
puts "A total of #{total_revision_count} revisions were downloaded across #{@pages.size} pages"
puts "A total of #{total_link_count} links were downloaded across #{@pages.size} pages"
puts "Time to scrape data: #{compute_time_taken(Time.now-total_timer_start)}"

puts "\n---------- Finished Gathering Data ----------\n"