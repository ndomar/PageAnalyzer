# This code logs you into wikipedia using the API.

#--------------------------------------------------------------------------------------------------------------------------------------#
# Start Login to the English Wikipedia Site #
puts "\nEstablishing Connection"
#--------------------------------------------------------------------------------------------------------------------------------------#
login_xml = Curl::Easy.new "http://en.wikipedia.org/w/api.php?action=login&format=xml" do |curl|
  curl.http_post Curl::PostField.content("lgname", @username), Curl::PostField.content("lgpassword", @password)
  curl.headers["User-Agent"] = @useragent
  # Extract the cookie set in the header
  curl.on_header do |header|
    if header.include?("Set-Cookie: enwiki_session=") && header.include?("; path=/; HttpOnly")      
      @enwiki_session = header.clone
      @enwiki_session.gsub! "Set-Cookie: ", ""
    end
    header.length
  end
  curl.perform
end # puts login_xml.body_str

#--------------------------------------------------------------------------------------------------------------------------------------#
# Extract the session variable                        #
# Extract the login token returned in the last page   #
#--------------------------------------------------------------------------------------------------------------------------------------#
i = 0; cont = "go"
begin
  if @enwiki_session[i..i].eql? ";"
    @enwiki_session = @enwiki_session[0..i]
    cont = "stop"
  end
  i += 1
  end while !cont.eql? "stop"

Login.parse(login_xml.body_str).each do |login|
  if login.result.eql? "NeedToken"
    @token = login.token
  end 
end

#--------------------------------------------------------------------------------------------------------------------------------------#
# Complete Login to Wikipedia #
puts "Attempting to Login"
#--------------------------------------------------------------------------------------------------------------------------------------#
headers = []
confirm = Curl::Easy.new "http://en.wikipedia.org/w/api.php?action=login&format=xml" do |curl|
  curl.http_post  Curl::PostField.content("lgname", @username),
                  Curl::PostField.content("lgpassword", @password),
                  Curl::PostField.content("lgtoken", @token)
  curl.headers["User-Agent"] = @useragent
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

#--------------------------------------------------------------------------------------------------------------------------------# 
# Ensure that login was succesful                                   # Not used |--> Extract the tokens returned in the last page #
# Construct the cookies necessary to have a persistant connection   #
# Ensure that the pages/ directory exists                           #
#--------------------------------------------------------------------------------------------------------------------------------# 
Login.parse(confirm.body_str).each do |login|
  if login.result.eql? "Success"
    puts "  Logged In ✓"
#     @lgusername = login.lguserid
#     @lgpassword = login.lgusername
#     @lgtoken = login.lgtoken
#     @cookie_prefix = login.cookieprefix
#     @session_id = login.sessionid
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
    end
  end
end

puts "Baking Cookies"
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
end # puts @cookies

# At this point you are now logged in to wikipedia.
# @cookies is the cookie to send to wikipedia to verify yourself as a user.