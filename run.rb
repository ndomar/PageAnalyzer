["rubygems", "curb", "happymapper"].each {|x| require x}

require "config/bot_login.rb"
require "scripts/login"
require "scripts/scrape"
require "scripts/functions"

@pages = File.read(@pages_list).split