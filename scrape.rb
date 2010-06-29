# This code is not pretty. It is not optimised, but it works.
["rubygems", "curb", "bot_login", "wiki_login"].each {|x| require x}

revisions_to_get = 1000
pages = File.read("pages.txt").split

# Truncates the head of an xml document making it
# start with the opening tag of the first revision
def remove_head str, state
  if state.eql? "rev"
    match_str = "<rev revid="
  elsif state.eql? "bl"
    match_str = "<bl pageid="
  end
  i = 0; cont = "go"
  begin
    if str[i..i+10].eql? match_str
      str = str[i..str.length]
      cont = "stop"
    end
    i += 1
  end while cont != "stop" && i < str.length
  return str
end

# Truncates the tail of an xml document making it
# end on the close tag of the last revision
def remove_tail str, state
  if state.eql? "rev"
    match_str = "</rev>"
    j=5
  elsif state.eql? "bl"
    match_str = "</backlinks>"
    j=11
  end
  i = str.length; cont = "go"
  begin
    if str[i..i+j].eql? match_str
      if state.eql? "rev"
        @tail = str[i+j+1..str.length] # In case we reach the reach the end of the revisions and need to reinstate the tail
        str = str[0..i+j]
      elsif state.eql? "bl"
        @tail = str[i..str.length] # In case we reach the reach the end of the revisions and need to reinstate the tail
        str = str[0..i-1]
      end
      cont = "stop"
    end
    i -= 1
  end while cont != "stop" && i > 0
  return str
end

#--------------------------------------------------------------------------------------------------------------------------------------------------------------# 
# Go to wikipedia and download the data for the various pages that were requested
puts "\nFetching data from Wikipedia for the following pages"
puts " Page:          Revs, Links, Done"
#--------------------------------------------------------------------------------------------------------------------------------------------------------------# 
revisions_per_query = 500                     # Set the maximum number of revisions per query to get (Max 500)                           # Tracks the time taken for each individual download. Not used at the moment
total_timer_start = Time.now
total_revision_count = 0
total_link_count = 0
STDOUT.sync = true

def set_name_length str
  if str.length < 14
    str << ":"
    begin 
      str << " "
    end while str.length < 15
  elsif str.length > 14
    str = str[0..10]
    str << "..:"
  else
    str << ":"
  end
  return str.gsub("_", " ")
end

pages.each do |page|  
  print " #{set_name_length page.clone}"
  last_rev = 0
  last_link = 0
  revision_count = 0
  link_count = 0
  @page_data = ""
  
  File.open("#{@folder}/#{page}.xml", "w"){|f| f.write("")}
  begin   # Get the revisions
    if revisions_to_get < revisions_per_query
      revisions_to_get = revisions_per_query
    end
    if last_rev == 0          # If we're on the first query, get the last X revisions starting at the most recent revision available
      query_url = "http://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=#{page}&rvprop=ids|timestamp|user|comment|content&rvlimit=#{revisions_per_query}&format=xml"
    else                      # If we're on a subsequent query, get the last X revisions starting at the revision previous to the oldest one we have on record
      query_url = "http://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=#{page}&rvprop=ids|timestamp|user|comment|content&rvlimit=#{revisions_per_query}&rvstartid=#{last_rev-1}&format=xml"
    end
    
    text = Curl::Easy.perform query_url do |curl|   # Make the request
      curl.cookies = @cookies                       # Set the login Cookies
      curl.headers = {"User-Agent" => @user_agent}
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
      File.open("#{@folder}/#{page}.xml", "a"){|f| f.write(page_data)} # Append the current set of revisions to the existing ones
      last_rev = Rev.parse(text.body_str).last.revid              # Store the revision to continue on in the next query
    end
    text = nil
    page_data = nil
  end while revision_count < revisions_to_get && revisions_this_query != 0
  
  File.open("#{@folder}/#{page}.xml", "a"){|f| f.write("</revisions></page></pages></query><query-continue><revisions rvstartid=\"357322858\" /></query-continue></api>")} # Once we have all the results we need, append the correct ending to the file.
  total_revision_count += revision_count
  print "#{revision_count}"
  
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
      curl.headers = {"User-Agent" => @user_agent}
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
  
  File.open("#{@folder}/#{page}_links.xml", "w"){|f| f.write(@page_data)}
  print ", #{link_count},"
  total_link_count += link_count
  
  puts "    ✓"
end

puts "\a"
puts "A total of #{total_revision_count} revisions were downloaded across #{pages.size} pages"
puts "A total of #{total_link_count} links were downloaded across #{pages.size} pages"
puts "Time to complete this run: #{(Time.now-total_timer_start)/60} minutes"