# This code is not pretty. It is not optimised, but it works.
["rubygems", "curb", "bot_login", "wiki_login"].each {|x| require x}

revisions_to_get = 10000
pages = File.read("pages.txt").split

# Truncates the head of an xml article making it
# start with the opening tag of the first revision
def remove_head str
  i = 0; cont = "go"
  begin
    if str[i..i+10].eql? "<rev revid="
      str = str[i..str.length]
      cont = "stop"
    end
    i += 1
  end while cont != "stop"
  return str
end

# Truncates the tail of an xml article making it
# end on the close tag of the last revision
def remove_tail str
  i = str.length; cont = "go"
  begin
    if str[i..i+5].eql? "</rev>"
      @tail = str[i+6..str.length] # In case we reach the reach the end of the revisions and need to reinstate the tail
      str = str[0..i+5]
      cont = "stop"
    end
    i -= 1
  end while cont != "stop"
  return str
end

#--------------------------------------------------------------------------------------------------------------------------------------------------------------# 
# Go to wikipedia and download the data for the various pages that were requested
puts "Fetching data from Wikipedia for the following pages"
#--------------------------------------------------------------------------------------------------------------------------------------------------------------# 
revisions_per_query = 500                     # Set the maximum number of revisions per query to get (Max 500)
download_time = {}                            # Tracks the time taken for each individual download. Not used at the moment
total_timer_start = Time.now
overall_revision_count = 0

pages.each do |page|
  puts "  ✓ #{page.gsub("_", " ")}"
  page_timer_start = Time.now
  @page_data = ""
  last_rev = 0
  revision_count = 0
  
  begin
    if revisions_to_get < revisions_per_query
      revisions_to_get = revisions_per_query
    end
    if last_rev == 0                          # If we're on the first query, get the last X revisions starting at the most recent revision available
      query_url = "http://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=#{page}&rvprop=ids|timestamp|user|comment|content&rvlimit=#{revisions_per_query}&format=xml"
    else                                      # If we're on a subsequent query, get the last X revisions starting at the revision previous to the oldest one we have on record
      query_url = "http://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=#{page}&rvprop=ids|timestamp|user|comment|content&rvlimit=#{revisions_per_query}&rvstartid=#{last_rev-1}&format=xml"
      @page_data = remove_tail @page_data
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
        @page_data +=  remove_head text.body_str
      else
        @page_data += text.body_str
      end
      last_rev = Rev.parse(text.body_str).last.revid
    end
    puts "    # of Revisions: #{revisions_this_query}"
  end while revision_count < revisions_to_get && revisions_this_query != 0
  
  # This does a search and replace on the retrieved text. It makes it much simpler to traverse later on.
  @page_data.gsub! 'xml:space="preserve">', 'xml:space="preserve"><text>'
  @page_data.gsub! '</rev>', '</text></rev>'
  
  File.open("pages/#{page}.xml", "w"){|f| f.write(@page_data)} 
  download_time[page] = Time.now - page_timer_start
  total_rev_count = Rev.parse(File.read("pages/#{page}.xml")).length
  
  if total_rev_count == revision_count
    puts "    - Total # of Revisions: #{Rev.parse(File.read("pages/#{page}.xml")).length}"
  else
    puts "    Shit something went wrong. Our count is off"
  end
  overall_revision_count += total_rev_count
end
puts "A total of #{overall_revision_count}s were downloaded across #{pages.size} pages"
puts "Time to complete this run: #{(Time.now-total_timer_start)/60} minutes"