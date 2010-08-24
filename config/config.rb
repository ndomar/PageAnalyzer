# This file holds the basic configuration information for the script

# The following variable sets the location of the file which lists the pages whose information you want to get.
# The path is relative to the main directory (which contains run.rb), not the config directory.

# This file should have each entry on a new line.
# The name should be that which falls at the end of the Wikipedia URL
#   e.g. The Wikipedia page for Ancient History is http://en.wikipedia.org/wiki/Ancient_history
#        Thus the entry you should put in this file is Ancient_history
@pages_list = "config/pages_list.txt"

# This sets the number of revisions to get for each of the pages in the @pages_list above
# The pages fetched will not be exact. It may be as much a a few hundred over your request.
# This is due to the amount of information returned after each request.

# If there are fewer revisions for a page than you requested, then it will fetch all of them.
@revisions_to_get = 1000

# Folders
# N.B:These paths are relative to the main directory (which contains run.rb), not the config directory.

# Where to store the data downloded from Wikipedia
@scraped_folder = "downloaded_data"

# Where to store the data when it parsed into a more consise form.
@parsed_folder  = "parsed_data"