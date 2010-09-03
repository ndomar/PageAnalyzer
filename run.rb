["rubygems", "curb", "happymapper"].each {|x| require x}
require "definitions/xml_definitions"

if ARGV[0].include? "h"
  puts "
  This script accepts a number of arguments which modifys it's behaviour.
  Calling the script in the following way would run the scraping, parsing and analysis sections of the code, but not create the user files needed for analysis.
    $ ruby run.rb -spa
  
  v   - Verbose Output. Includes a number of printouts that describe processes that are happening in the background.
  
  If any or all of the following are called, then the script will only perform that action
  s     - Runs the scraping code which gathers information from Wikipedia
  p     - Parses the data downloaded from Wikipedia
  a     - Analyzes and performs feature extraction of the data
  r     - Creates the user csv file
  t     - Converts the csv file to arff
  
  n     - Names the csv and arff files created. The name must be provided as the second argument. e.g.
    $ ruby run.rb -n \"csv_file\"
  "
else
  ARGV[0] = "" if ARGV[0].eql? nil
  
  
  # Config files
  require "config/bot_login"
  require "config/config"

  # Library files
  require "scripts/functions_scrape"
  require "scripts/functions"

  # Read in the list of pages
  @pages = File.read(@pages_list).split
  classpath = "\"$CLASSPATH:#{File.expand_path(File.dirname(__FILE__))}/weka/weka.jar\""
  
  if !ARGV[0].nil? && ARGV[0].include?("n") then @user_file = "#{@analysis_folder}/#{ARGV[1]}"
  else @user_file = "#{@analysis_folder}/user.csv" end
  # Runtime files
  if ARGV[0].eql?("") || ARGV[0].include?("v")
    require "scripts/scrape"
    require "scripts/parse"
    require "scripts/analyse"
    require "scripts/create_user_csv"
    puts "Ignore the following 6 warnings. They come from Weka and are not relevant :)"
    system "java -cp #{classpath} -Xmx500m weka.core.converters.CSVLoader #{@user_file} > #{@user_file}.arff"
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
    if ARGV[0].include? "r"
      require "scripts/create_user_csv"
    end
    if ARGV[0].include? "t"
      # Convert the user csv file into an arff file
      puts "Ignore the following 5 warnings. They come from Weka and are not relevant :)\n\n"
      system "java -cp #{classpath} -Xmx500m weka.core.converters.CSVLoader #{@user_file} > #{@user_file}.arff"
    end
  end
  
  # Remove some shit
  arff_file = File.read "#{@user_file}.arff"
  if arff_file.include? "true,255,255,255,255,reliable\ntrue,255,255,255,255,other\n"
    arff_file = arff_file.gsub!"\ntrue,255,255,255,255,reliable\ntrue,255,255,255,255,other\n", ""
    File.open("#{@user_file}.arff", "w"){|f| f.write(arff_file)}
  end
  
  csv_file = File.read @user_file
  if csv_file.include? "true,255,255,255,255,reliable\ntrue,255,255,255,255,other\n"
    csv_file = csv_file.gsub!"true,255,255,255,255,reliable\ntrue,255,255,255,255,other\n", ""
    File.open("#{@user_file}", "w"){|f| f.write(csv_file)}
  end
end