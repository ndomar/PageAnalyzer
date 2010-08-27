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
if ARGV[0].eql? nil
  require "scripts/scrape"
  require "scripts/parse"
  require "scripts/analyse"
  require "scripts/create_user_csv"
else
  if ARGV[0].include? "s"
    require "scripts/scrape"
  end
  if ARGV[0].include? "p"
    require "scripts/parse"
  end
  if ARGV[0].include? "a"
    require "scripts/analyse"
  end
  if ARGV[0].include? "c"
    require "scripts/create_user_csv"
  end
end

