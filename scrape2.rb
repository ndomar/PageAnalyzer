["rubygems", "curb", "happymapper", "xml_definitions", "bot_login"].each {|x| require x}

revisions = "max"
pages = File.read("pages.txt").split
# @user_name & @password are located in the bot_login.rb file.
@user_agent = "ChrisSalij_Bot_Contact:_Chris@Salij.org"
@cookie_file = "cookies.txt"

if @user_name.nil? || @password.nil?
  puts "X Please Supply a username and password"
end

puts "\nEstablishing Connection"        #Start Login to the English Wikipedia Site
login_xml = Curl::Easy.new "http://en.wikipedia.org/w/api.php?action=login&format=xml" do |curl|
  curl.http_post Curl::PostField.content("lgname", @user_name), Curl::PostField.content("lgpassword", @password)
  curl.headers["User-Agent"] = @user_agent
  # Extract the cookie set in the header
  curl.on_header do |header|
    if header.include?("Set-Cookie: enwiki_session=") && header.include?("; path=/; HttpOnly")      
      @enwiki_session = header.clone
      @enwiki_session.gsub! "Set-Cookie: ", ""
      @enwiki_session.gsub! "; path=/; HttpOnly ", ""
    end
    header.length
  end
  curl.perform
end # puts login_xml.body_str

# Extract the session variable
i = 0
begin
  if @enwiki_session[i..i].eql? ";"
    @enwiki_session = @enwiki_session[0..i]
    cont = false
  end
  i += 1
end while cont != false

# Extract the login token returned in the last page
Login.parse(login_xml.body_str).each do |login|
  if login.result.eql? "NeedToken"
    @token = login.token
  end 
end

#--------------------------------------------------------------------------------------------------------------------------------------------------------------# 
# Above the line is working. Do Not Touch #
#--------------------------------------------------------------------------------------------------------------------------------------------------------------# 

puts "Attempting to Login" #Complete Login to Wikipedia
headers = []
confirm = Curl::Easy.new "http://en.wikipedia.org/w/api.php?action=login&format=xml" do |curl|
  curl.http_post Curl::PostField.content("lgname", @user_name), Curl::PostField.content("lgpassword", @password), Curl::PostField.content("lgtoken", @token)
  curl.headers["User-Agent"] = @user_agent
  curl.cookies = @enwiki_session
  curl.on_header do |header|
      if header.include? "Set-Cookie: "
        head = header.clone
        head.gsub! "Set-Cookie: ", ""
        headers.push head
      end
      header.length
    end
  curl.perform
end # puts confirm.body_str

#--------------------------------------------------------------------------------------------------------------------------------------------------------------# 
# Above the line is working. Do Not Touch #
#--------------------------------------------------------------------------------------------------------------------------------------------------------------# 

# Extract the token returned in the last page
Login.parse(confirm.body_str).each do |login|
  if login.result.eql? "Success"
    puts "  Logged In ✓"
    @lgusername = login.lguserid
    @lgpassword = login.lgusername
    @lgtoken = login.lgtoken
    @cookie_prefix = login.cookieprefix
    @session_id = login.sessionid
  else # If login was not successful, print an informative help message
    puts " X Login failed."
    if login.result.eql?("WrongPass") || login.result.eql?("EmptyPass") || login.result.eql?("WrongPluginPass")
      puts "Incorrect Password"
    elsif login.result.eql?("Illegal") || login.result.eql?("NoName") || login.result.eql?("NotExists")
      puts "Incorrect Username"
    elsif login.result.eql?("Throttled") || login.result.eql?("Blocked")
      puts "You've going too fast, ease the fuck up on the requests."
    elsif login.result.eql?("NeedToken") || login.result.eql?("mustbeposted")
      puts "Something went wrong a bit further up the code."
    else
    end
  end
end

puts "Extracting Cookie Ingredients"
@cookies = "#{@enwiki_session} #{@cookie_prefix}Token=#{@lgtoken};"
headers.reverse.each do |cookie|
  i = 0; cont = "go"
  begin
    if cookie[i..i].eql? ";"
      @cookies += " #{cookie[0..i]}"
      cont = "stop"
    end
    i += 1
  end while !cont.eql? "stop"
end 
puts @cookies

# puts "Baking Cookies" # Construct the cookie from the information sent in the last request
# @cookie_string = ""
# @cookies.each do |cookie|
#   @cookie_string += "#{cookie}"
# end # puts @cookie_string

if !File.directory? "pages" # If a directectory called pages does not exist in the current folder, create it.
  puts "Created the 'pages' folder to store downloaded data"
  Dir.mkdir "pages"
end

puts "Fetching data from Wikipedia for the following pages"

pages.each do |page|
  puts "  ✓ #{page.gsub("_", " ")}"
  wikitext = Curl::Easy.new "http://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=#{page}&rvprop=ids|timestamp|user|comment|content&rvlimit=#{revisions}&format=xml" do |curl|
    #curl.cookies = @cookies
    curl.headers = {"User-Agent" => @user_agent}
    curl.perform
  end
  
  puts wikitext.cookies
  puts wikitext.cookiejar
  
  # This does a search and replace on the retrieved text. It makes it much simpler to traverse later on.
  # wikitext.body_str.gsub! 'xml:space="preserve">', 'xml:space="preserve"><text>'
  # wikitext.body_str.gsub! '</rev>', '</text></rev>'
  
  File.open("pages/#{page}.xml", "w"){|f| f.write(wikitext.body_str)}   # Save the modified xml to a file.
end

puts "\nDone Downloading Data. Downloaded a total of #{revisions*pages.length} revisions over #{pages.length} pages\n"