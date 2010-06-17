["rubygems", "curb", "happymapper", "xml_definitions", "bot_login"].each {|x| require x}

revisions = 10
pages = File.read("pages.txt").split

# @user_name & @password are located in the bot_login.rb file.
@user_agent = "ChrisSalij_Bot_Contact:_Chris@Salij.org"
@cookie_file = "cookies.txt"

puts "\nEstablishing Connection"        #Start Login to the English Wikipedia Site
login_xml = Curl::Easy.new "http://en.wikipedia.org/w/api.php?action=login&format=xml" do |curl|
  curl.http_post Curl::PostField.content("lgname", @user_name), Curl::PostField.content("lgpassword", @password)
  curl.headers["User-Agent"] = @user_agent
  
  # Extract the cookie set in the header
  curl.on_header do |header|
    if header.include?("Set-Cookie: enwiki_session=") && header.include?("; path=/; HttpOnly")      
      @cookie = header.clone
      @cookie.gsub! "Set-Cookie: ", ""
      @cookie.gsub! "; path=/; HttpOnly", ""
    end
    header.length
  end
  curl.perform
end #puts login_xml.body_str
puts "Attempting to Login"

# Extract the login token returned in the last page
Login.parse(login_xml.body_str).each do |login|
  if login.result.eql? "NeedToken"
    @token = login.token
  end 
end

#Complete Login to Wikipedia
headers = []
confirm = Curl::Easy.new "http://en.wikipedia.org/w/api.php?action=login&format=xml" do |curl|
  curl.http_post Curl::PostField.content("lgname", @user_name), Curl::PostField.content("lgpassword", @password), Curl::PostField.content("lgtoken", @token)
  curl.headers["User-Agent"] = @user_agent
  curl.cookies = "#{@cookie};"
  curl.on_header do |header|
      if header.include? "Set-Cookie: "
        head = header.clone
        head.gsub! "Set-Cookie: ", ""
        headers.push head
      end
      header.length
    end
  curl.perform
end

# Extract the token returned in the last page
Login.parse(confirm.body_str).each do |login|
  if login.result.eql? "Success"
    puts "  Logged In ✓"
    #@user_id = login.lguserid
    #@login_name = login.lgusername
    @lgtoken = login.lgtoken
    @cookie_prefix = login.cookieprefix
    @session_id = login.sessionid
  else # If login was not successful, print an informative help message
    puts " X Login failed."
    if login.result.eql?("WrongPass") || login.result.eql?("EmptyPass") || login.result.eql?("WrongPluginPass")
      puts "Incorrect Password"
    elsif login.result.eql?("Illegal") || login.result.eql?("NoName") || login.result.eql?("NotExists")
      puts "Incorrect Username"
    elsif login.result.eql? "Throttled"
      puts "You've been throttled, ease the fuck up on the requests."
    elsif login.result.eql? "Blocked"
      puts "You've been blocked, ease the fuck up on the requests."
    elsif login.result.eql?("NeedToken") || login.result.eql?("mustbeposted")
      puts "Something went wrong a bit further up the code."
    else
    end
  end
end

puts "Extracting Cookie Ingredients"
@cookies = []
headers.each do |cookie|
  i = 0
  begin
    if cookie[i..i].eql? ";"
      @cookies.push cookie[0..i-1]
      cont = false
    end
    i += 1
  end while cont != false
end

puts "Baking Cookies"
# Construct the cookie from the information sent in the last request
@cookie_string = ""
@cookies.each do |cookie|
  @cookie_string += "#{cookie}; "
end
@cookie_string += "#{@cookie_prefix}Token=#{@lgtoken}; #{@cookie};"

if !File.directory? "pages" # If a directectory called pages does not exist in the current folder, create it.
  puts "Created the 'pages' folder to store downloaded data"
  Dir.mkdir "pages"
end

puts "Fetching data from Wikipedia for the following pages"


pages.each do |page|
  puts "  ✓ #{page.gsub("_", " ")}"
  wikitext = Curl::Easy.new "http://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=#{page}&rvprop=ids|timestamp|user|comment|content&rvlimit=#{revisions}&format=xml" do |curl|
    curl.cookies = @cookie_string
    curl.headers["User-Agent"] = @user_agent
    curl.perform
  end
    
  # This does a search and replace on the retrieved text. It makes it much simpler to traverse later on.
  wikitext.body_str.gsub! 'xml:space="preserve">', 'xml:space="preserve"><text>'
  wikitext.body_str.gsub! '</rev>', '</text></rev>'
  
  File.open("pages/#{page}.xml", "w"){|f| f.write(wikitext.body_str)}   # Save the modified xml to a file.
end

puts "\nDone Downloading Data. Downloaded a total of #{revisions*pages.length} revisions over #{pages.length} pages\n"