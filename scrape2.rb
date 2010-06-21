# This code is not pretty. It is not optimised, but it works.
["rubygems", "curb", "bot_login", "wiki_login"].each {|x| require x}

revisions = 520
pages = File.read("pages.txt").split

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
revs_per_query = 500                    # Set the maximum number of revisions per query to get (Max 500)
queries = revisions/revs_per_query      # Determine the number of queries to make
remainder = revisions%revs_per_query    # See if the number of revisions to get divides equally into the number of queries
if remainder > 0                        # If not then make an extra query to cover the remainder
  queries += 1
end 

download_time = {}                      # Tracks the time taken for each individual download. Not used at the moment
total_timer_start = Time.now

pages.each do |page|
  puts "  ✓ #{page.gsub("_", " ")}"
  page_timer_start = Time.now
  @page_data = ""
  cont_rev =0
  
  queries.times do |time|
    if cont_rev != -1                         # We reached the end of the history, no point in querying again
      if remainder != 0 && time == queries-1  # If there is a remainder and we're on the last query
        revs_per_query = remainder+1          # Only get the amount of revisions in the remainder
      end
      if cont_rev == 0                        # If we're on the first query, get the last X revisions starting at the most recent revision available
        query_url = "http://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=#{page}&rvprop=ids|timestamp|user|comment|content&rvlimit=#{revs_per_query}&format=xml"
      else                                    # If we're on a subsequent query, get the last X revisions starting at the revision previous to the oldest one we have on record
        query_url = "http://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=#{page}&rvprop=ids|timestamp|user|comment|content&rvlimit=#{revs_per_query-1}&rvstartid=#{cont_rev-1}&format=xml"
        @page_data = remove_tail @page_data
      end
      
      text = Curl::Easy.new query_url do |curl|
        curl.cookies = @cookies
        curl.headers = {"User-Agent" => @user_agent}
        curl.perform
      end # puts text.body_str
      
      if Rev.parse(text.body_str).last.nil?   # Then we've gone back as far as we can.
        @page_data += @tail                   # Add the tail back on that was chopped off
        cont_rev = -1                         # Make sure that no more calls are made on this page
      else                                    # Don't both parsing it as there is nothing to parse
        if cont_rev != 0                      # If this is not the first query
          @page_data +=  remove_head text.body_str
        else
          @page_data += text.body_str
        end
        File.open("pages/#{page}.xml", "w"){|f| f.write(text.body_str)} 
        cont_rev = Rev.parse(text.body_str).last.revid
        # puts cont_rev
      end
    end
  end
  
  # This does a search and replace on the retrieved text. It makes it much simpler to traverse later on.
  @page_data.gsub! 'xml:space="preserve">', 'xml:space="preserve"><text>'
  @page_data.gsub! '</rev>', '</text></rev>'
  
  File.open("pages/#{page}.xml", "w"){|f| f.write(@page_data)} 
  download_time[page] = Time.now - page_timer_start
  puts "# of Revisions: #{Rev.parse(File.read("pages/#{page}.xml")).length}"
end
puts "Time to complete this run: #{Time.now - total_timer_start}"

#puts "\nDone Downloading Data. Downloaded a total of #{revisions*pages.length} revisions over #{pages.length} pages\n"