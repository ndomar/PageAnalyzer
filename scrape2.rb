# This code is not pretty. It is not optimised, but it works.
["rubygems", "curb", "bot_login", "wiki_login"].each {|x| require x}

revisions = "max"
pages = File.read("pages.txt").split
# bot_login.rb holds the login information

if @user_name.nil? || @password.nil?
  puts "X Please Supply a username and password"
end

#--------------------------------------------------------------------------------------------------------------------------------------------------------------# 
# Go to wikipedia and download the data for the various pages that were requested
puts "Fetching data from Wikipedia for the following pages"
#--------------------------------------------------------------------------------------------------------------------------------------------------------------# 
download_time = {} # Tracks the time taken for each individual download. Not used at the moment
total_timer_start = Time.now

pages.each do |page|
  puts "  ✓ #{page.gsub("_", " ")}"
  page_timer_start = Time.now
  wikitext = Curl::Easy.new "http://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=#{page}&rvprop=ids|timestamp|user|comment|content&rvlimit=#{revisions}&format=xml" do |curl|
    curl.cookies = @cookies
    curl.headers = {"User-Agent" => @user_agent}
    curl.perform
  end
  download_time[page] = Time.now - page_timer_start
  
  # This does a search and replace on the retrieved text. It makes it much simpler to traverse later on.
  wikitext.body_str.gsub! 'xml:space="preserve">', 'xml:space="preserve"><text>'
  wikitext.body_str.gsub! '</rev>', '</text></rev>'
  
  File.open("pages/#{page}.xml", "w"){|f| f.write(wikitext.body_str)}   # Save the modified xml to a file.
  # puts Rev.parse(wikitext.body_str).length
end
puts "Time to complete this run: #{Time.now - total_timer_start}"

puts "\nDone Downloading Data. Downloaded a total of #{revisions*pages.length} revisions over #{pages.length} pages\n"