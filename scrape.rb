# This code is not pretty. It is not optimised, but it works.
["rubygems", "curb", "bot_login", "wiki_login"].each {|x| require x}

revisions_to_get = 2000
links_to_get = 10000
pages = File.read("pages.txt").split

# Truncates the head of an xml article making it
# start with the opening tag of the first revision
def remove_head str, state
  if state.eql? "rev"
    match_str = "<rev revid="
  elsif state.eql? "bl"
    match_str = "<bl pageid"
  end
  i = 0; cont = "go"
  begin
    if str[i..i+10].eql? match_str
      str = str[i..str.length]
      cont = "stop"
    end
    i += 1
  end while cont != "stop"
  return str
end

# Truncates the tail of an xml article making it
# end on the close tag of the last revision
def remove_tail str, state
  if state.eql? "rev"
    match_str = "</rev>"
    j=5
  elsif state.eql? "bl"
    match_str = "\" />"
    j=4
  end
  i = str.length; cont = "go"
  begin
    if str[i..i+j].eql? "</rev>"
      @tail = str[i+j+1..str.length] # In case we reach the reach the end of the revisions and need to reinstate the tail
      str = str[0..i+j]
      cont = "stop"
    end
    i -= 1
  end while cont != "stop"
  return str
end

#--------------------------------------------------------------------------------------------------------------------------------------------------------------# 
# Go to wikipedia and download the data for the various pages that were requested
puts "\nFetching data from Wikipedia for the following pages"
#--------------------------------------------------------------------------------------------------------------------------------------------------------------# 
revisions_per_query = 500                     # Set the maximum number of revisions per query to get (Max 500)
download_time = {}                            # Tracks the time taken for each individual download. Not used at the moment
total_timer_start = Time.now
overall_revision_count = 0
overall_link_count = 0

pages.each do |page|
  puts "  ✓ #{page.gsub("_", " ")}"
  page_timer_start = Time.now
  @page_data = ""
  last_rev = 0
  last_link = 0
  revision_count = 0
  link_count = 0
  
  begin   # Get the revisions
    if revisions_to_get < revisions_per_query
      revisions_to_get = revisions_per_query
    end
    if last_rev == 0                          # If we're on the first query, get the last X revisions starting at the most recent revision available
      query_url = "http://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=#{page}&rvprop=ids|timestamp|user|comment|content&rvlimit=#{revisions_per_query}&format=xml"
    else                                      # If we're on a subsequent query, get the last X revisions starting at the revision previous to the oldest one we have on record
      query_url = "http://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=#{page}&rvprop=ids|timestamp|user|comment|content&rvlimit=#{revisions_per_query}&rvstartid=#{last_rev-1}&format=xml"
      @page_data = remove_tail @page_data, "rev"
    end
    
    text = Curl::Easy.perform query_url do |curl|       # Make the request
      curl.cookies = @cookies                       # Set the login Cookies
      curl.headers = {"User-Agent" => @user_agent}
    end # puts text.body_str
    
    revisions_this_query = Rev.parse(text.body_str).length  # The amount of revisions returned in this query
    revision_count += revisions_this_query
    
    if revisions_this_query == 0              # Then we've gone back as far as we can.
      @page_data += @tail                     # Add the tail back on that was chopped off
    else                                      # Don't both parsing it as there is nothing to parse
      if last_rev != 0                        # If this is not the first query
        @page_data +=  remove_head text.body_str, "rev"
      else
        @page_data += text.body_str
      end
      last_rev = Rev.parse(text.body_str).last.revid
    end
    #puts "    # of Revisions: #{revisions_this_query}"
  end while revision_count < revisions_to_get && revisions_this_query != 0
  
  # This does a search and replace on the retrieved text. It makes it much simpler to traverse later on.
  @page_data.gsub! 'xml:space="preserve">', 'xml:space="preserve"><text>'
  @page_data.gsub! '</rev>', '</text></rev>'
  
  File.open("pages/#{page}.xml", "w"){|f| f.write(@page_data)} 
  download_time[page] = Time.now - page_timer_start
  total_rev_count = Rev.parse(File.read("pages/#{page}.xml")).length
  puts "      + #{total_rev_count} revisions Downloaded"
  
  @page_data = ""
  begin  # Get the Link
    if links_to_get < revisions_per_query
      links_to_get = revisions_per_query
    end
    if last_link == 0                          # If we're on the first query, get the last X revisions starting at the most recent revision available
      query_url = "http://en.wikipedia.org/w/api.php?action=query&list=backlinks&bltitle=#{page}&bllimit=#{revisions_per_query}&format=xml"
    else                                      # If we're on a subsequent query, get the last X revisions starting at the revision previous to the oldest one we have on record
      query_url = "http://en.wikipedia.org/w/api.php?action=query&list=backlinks&bltitle=#{page}&bllimit=#{revisions_per_query}&blcontinue=#{last_link-1}format=xml"
      @page_data = remove_tail @page_data, "bl"
    end
    
    text = Curl::Easy.perform query_url do |curl|       # Make the request
      curl.cookies = @cookies                       # Set the login Cookies
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
      last_rev = Bl.parse(text.body_str).last.pageid
    end # puts "    # of Links: #{links_this_query}"
  end while revision_count < revisions_to_get && revisions_this_query != 0
  
  File.open("pages/#{page}_links.xml", "w"){|f| f.write(@page_data)}
  download_time[page] = Time.now - page_timer_start
  total_link_count = Bl.parse(File.read("pages/#{page}_links.xml")).length
  puts "      + #{total_link_count} links Downloaded"
  
  if total_rev_count == revision_count
    puts "    - Total # of Revisions: #{Rev.parse(File.read("pages/#{page}.xml")).length}"
  else
    puts "    Shit something went wrong. Our count is off"
  end
  overall_revision_count += total_rev_count
  overall_link_count += total_link_count
  
end

puts
puts "A total of #{overall_revision_count} revisions were downloaded across #{pages.size} pages"
puts "A total of #{overall_link_count} linkss were downloaded across #{pages.size} pages"
puts "Time to complete this run: #{(Time.now-total_timer_start)/60} minutes"