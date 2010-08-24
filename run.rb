["rubygems", "curb", "happymapper"].each {|x| require x}

require "definitions/xml_definitions"

# Config files
require "config/bot_login"
require "config/config"

# Library files
require "scripts/functions_scrape"
require "scripts/functions"

@pages = File.read(@pages_list).split

# Runtime files
require "scripts/login"
require "scripts/scrape"
