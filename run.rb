["rubygems", "curb", "happymapper"].each {|x| require x}

require "definitions/xml_definitions"

# Config files
require "config/bot_login"
require "config/config"

# Library files
require "scripts/functions_scrape"
require "scripts/functions"

# Read in the list of pages
@pages = File.read(@pages_list).split

# Runtime files

if login_present? @username, @password, @useragent
  require "scripts/login"
end

require "scripts/scrape"
require "scripts/parse"
