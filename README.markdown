## Installation ##
Ruby and Ruby1.8-dev are required.

On ''Mac'' all gems install without issue.
On Ubuntu you will need to install the following packages before you start

*	sudo apt-get install ruby1.8-dev
*	sudo apt-get install libcurl4-gnutls-dev
*	sudo apt-get install libxml2-dev

### Required Gems ###

*	''Curb'' is required to run the scraping code
*	''HappyMapper'' is required for the entire thing


## Running the code ##

Specify the list of pages you wish to get information for in the pages.txt file. (Make sure they're spelt correctly, with all the underscores)

Once you have the above gems installed run the code in the following order

1.	scrape.rb - This file gets the information from wikipedia
2.	parse.rb - This file parses the information and stores it in a much easier to access way.
3.	step3.rb - Well this is still a work in progress, so it's unclear exactly what its going to do.