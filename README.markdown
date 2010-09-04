## Installation ##
Ruby and Ruby1.8-dev are required.

On ''Mac'' all gems install without issue.
On Ubuntu you will need to install the following packages before you start

*	sudo apt-get install ruby1.8-dev
*	sudo apt-get install libcurl4-gnutls-dev
*	sudo apt-get install libxml2-dev

### Required Gems ###

*	''Curb'' is required for the scraping code
*	''HappyMapper'' is required a number of different aspects

## Running the code ##

The config directory holds all the necessary information for the code to run.

*	bot_login.r		- Holds login details for a wikipedia bot, if you have one registered
*	config.rb		- Specifies a number of variables which control how much data is gathered and where it is stored.
*	pages_list.rb	- Specifies the pages for which information is to be downloaded. (see config.rb for guidelines)

Once you have set your necessary configuration information, run the ''run.rb'' file by typing ''ruby run.rb''.

This script accepts a number of arguments which modifies it's behaviour.
  Calling the script in the following way would run the scraping, parsing and analysis sections of the code, but not create the user files needed for analysis.
    ''$ ruby run.rb -spa''
  
  v   - Verbose Output. Includes a number of printouts that describe processes that are happening in the background.
  
  If any or all of the following are called, then the script will only perform that action
  s     - Runs the scraping code which gathers information from Wikipedia
  p     - Parses the data downloaded from Wikipedia
  a     - Analyzes and performs feature extraction of the data
  r     - Creates the user csv file
  t     - Converts the csv file to arff
  
  n     - Names the csv and arff files created. The name must be provided as the second argument. e.g.
    ''$ ruby run.rb -n \"csv_file\"''

## License ##

This package of code as a whole, falls under the GNU General Public License version 2.
(Full text included in the folder).

The reason for this is that the [Weka](http://www.cs.waikato.ac.nz/ml/weka/) software is included in this software and it is licensed under GPLv2. In order to redistribute the Weka code this program as a whole must be licensed under GPLv2 as well.

If you wish to use a sub-portion of the code, which does not directly include or rely on Weka (such as the scraping/parsing) and thus does not necessarily need to fall under GPLv2, contact me directly Chris[at]Salij.org.