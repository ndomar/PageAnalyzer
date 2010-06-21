# This script goes to Wikipedia and downloads the last number of revisions of 
# all the articles speficied in the pages.txt file
["rubygems", "curb"].each {|x| require x}

revisions = 500
pages = File.read("pages.txt").split

Dir.mkdir "pages" unless File.directory? "pages" # If a directectory called pages does not exist in the current folder, create it.

pages.each do |page|
  puts "Getting data for #{page}"

  wikitext = Curl::Easy.perform "http://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=#{page}&rvprop=ids|timestamp|user|comment|content&rvlimit=#{revisions}&format=xml" do |curl|
    curl.headers["User-Agent"] = "Odcsss_Ruby_Wiki_Scraper_Contact:_Chris@Salij.org"
  end
  
  # This does a search and replace on the retrieved text. It makes it much simpler to traverse later on.
  wikitext.body_str.gsub! 'xml:space="preserve">', 'xml:space="preserve"><text>'
  wikitext.body_str.gsub! '</rev>', '</text></rev>'
  
  File.open("pages/#{page}.xml", "w"){|f| f.write(wikitext.body_str)}   # Save the modified xml to a file.
end


# Some other query urls that I used. I want to keep them as a reference:
# http://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=google&rvprop=timestamp|user|comment|content&rvlimit=10&format=xml
# http://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=#{page}&rvprop=ids|timestamp|user|comment|content&rvlimit=1&list=alllinks&alunique&allimit=40&format=xml