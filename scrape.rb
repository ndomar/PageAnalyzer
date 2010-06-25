# This code is not pretty. It is not optimised, but it works.
["rubygems", "curb", "bot_login", "wiki_login"].each {|x| require x}

revisions_to_get = 1000
pages = File.read("pages.txt").split

# Truncates the head of an xml article making it
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

# Truncates the tail of an xml article making it
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
puts "  Page: Revs, Links, Done"
#--------------------------------------------------------------------------------------------------------------------------------------------------------------# 
revisions_per_query = 500                     # Set the maximum number of revisions per query to get (Max 500)
download_time = {}                            # Tracks the time taken for each individual download. Not used at the moment
total_timer_start = Time.now
overall_revision_count = 0
overall_link_count = 0
STDOUT.sync = true

pages.each do |page|  
  print " #{page.gsub("_", " ")}"
  page_timer_start = Time.now
  last_rev = 0
  last_link = 0
  revision_count = 0
  link_count = 0
  
  File.open("pages/#{page}.xml", "w"){|f| f.write("")}
  begin   # Get the revisions
    page_data = ""
    if revisions_to_get < revisions_per_query
      revisions_to_get = revisions_per_query
    end
    if last_rev == 0                          # If we're on the first query, get the last X revisions starting at the most recent revision available
      query_url = "http://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=#{page}&rvprop=ids|timestamp|user|comment|content&rvlimit=#{revisions_per_query}&format=xml"
    else                                      # If we're on a subsequent query, get the last X revisions starting at the revision previous to the oldest one we have on record
      query_url = "http://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=#{page}&rvprop=ids|timestamp|user|comment|content&rvlimit=#{revisions_per_query}&rvstartid=#{last_rev-1}&format=xml"
    end
    
    text = Curl::Easy.perform query_url do |curl|       # Make the request
      curl.cookies = @cookies                       # Set the login Cookies
      curl.headers = {"User-Agent" => @user_agent}
    end # puts text.body_str
    File.open("pages/#{page}#{last_rev}.xml", "w"){|f| f.write(text.body_str)} # Append the current set of revisions to the existing ones
    
    page_data = text.body_str
    revisions_this_query = Rev.parse(text.body_str).length  # The amount of revisions returned in this query
    revision_count += revisions_this_query
    
    if last_rev != 0
      page_data = remove_head page_data, "rev"
    end
    
    if revisions_this_query != 0
      page_data = remove_tail page_data, "rev"
      
      # This does a search and replace on the retrieved text. It makes it much simpler to traverse later on.
      page_data.gsub! 'xml:space="preserve">', 'xml:space="preserve"><text>'
      page_data.gsub! '</rev>', '</text></rev>'
      # puts page_data[0..300]
      File.open("pages/#{page}.xml", "a"){|f| f.write(page_data)} # Append the current set of revisions to the existing ones
    end
    
    last_rev = Rev.parse(text.body_str).last.revid
    #puts "    # of Revisions: #{revisions_this_query}"
  end while revision_count < revisions_to_get && revisions_this_query != 0
  File.open("pages/#{page}.xml", "a"){|f| f.write("</revisions></page></pages></query><query-continue><revisions rvstartid=\"357322858\" /></query-continue></api>")}
  
  download_time[page] = Time.now - page_timer_start
  total_rev_count = Rev.parse(File.read("pages/#{page}.xml")).length
  print ":  #{total_rev_count}"
  
  @page_data = ""
  begin  # Get the Links
    if last_link == 0                          # If we're on the first query, get the last X revisions starting at the most recent revision available
      query_url = "http://en.wikipedia.org/w/api.php?action=query&list=backlinks&bltitle=#{page}&bllimit=max&format=xml"
    else                                      # If we're on a subsequent query, get the last X revisions starting at the revision previous to the oldest one we have on record
      query_url = "http://en.wikipedia.org/w/api.php?action=query&list=backlinks&bltitle=#{page}&bllimit=max&blcontinue=#{last_link}&format=xml"
      @page_data = remove_tail @page_data, "bl"
    end
    
    text = Curl::Easy.perform query_url do |curl|       # Make the request
      curl.cookies = @cookies                       	# Set the login Cookies
      curl.headers = {"User-Agent" => @user_agent}
    end # puts text.body_str
    links_this_query = Bl.parse(text.body_str).length  # The amount of revisions returned in this query
    link_count += links_this_query
    
    if links_this_query == 0                    # Then we've gone back as far as we can.
      @page_data += @tail                       # Add the tail back on that was chopped off
    else                                        # Don't both parsing it as there is nothing to parse
      if last_link != 0                         # If this is not the first query
        @page_data += remove_head text.body_str, "bl"
      else
        @page_data += text.body_str
      end
      last_link = Backlinks.parse(text.body_str).last.blcontinue
    end # puts "    # of Links: #{links_this_query}"
  end while links_this_query > 0
  
  File.open("pages/#{page}_links.xml", "w"){|f| f.write(@page_data)}
  download_time[page] = Time.now - page_timer_start
  total_link_count = Bl.parse(File.read("pages/#{page}_links.xml")).length
  print ",	#{total_link_count}"
  
  # if total_rev_count == revision_count
  #   puts "    - Total # of Revisions: #{Rev.parse(File.read("pages/#{page}.xml")).length}"
  # else
  #   puts "    Shit something went wrong. Our count is off"
  # end
  # overall_revision_count += total_rev_count
  overall_link_count += total_link_count
  puts "    ✓" 
end

puts "\a"
puts "A total of #{overall_revision_count} revisions were downloaded across #{pages.size} pages"
puts "A total of #{overall_link_count} links were downloaded across #{pages.size} pages"
puts "Time to complete this run: #{(Time.now-total_timer_start)/60} minutes"