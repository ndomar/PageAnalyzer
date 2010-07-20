# This file provides a number of custom functions used in the parse.rb file
require "amatch"
include Amatch
@parse_folder = "parsed_data"
@scraped_folder = "scraped_data"

# On every turn in the loop the following much be done
def process_revision rev, revs, page
  @user_hash[rev.user] = @user_hash.fetch(rev.user, 0)+1    # Collect user information
  rev.hash = Digest::SHA1.hexdigest rev.text                # Set the hash value (a hash of the text) for each revisions
  rev.age = compute_edit_age rev, revs.last                 # Get the edit age
  
  if revs.length > 1
    # puts rev.text.size.to_s+" "+revs.last.text.size.to_s
    compute_intermediate_revision rev, revs.last, revs
    # Compute_intermediate revision removes multiple sequential revisions by the same person. It removes all but the latest one
    # Thus if the length hasn't' changed then no revisions were removed
    if @prev_length === revs.length
      revision_add_revision revs.fetch(revs.length-3), revert?(rev, revs), page             # Add the contents of the current revision to the revision file
    end
  end
  revs.push rev
  @prev_length = revs.length
end

# Check to see if this middle edit was a bad edit, in the eyes of the other two
def bad_edit? rev1, rev2, rev3
  if rev1 > rev2 && rev2 < rev3
#    puts rev2.user
#    puts rev2.comment
  end
end

# Add a revision to a page. See definitions/user_template.xml
# for the layout of a user file
def user_add_revision name, page, revisionid
  if name.include? "&"
  	name.gsub! "&", "and"
  end
  
  if File.exists? "#{@parse_folder}/user_#{name}.xml"             # Check to see if the user exits
    str = File.read "#{@parse_folder}/user_#{name}.xml"
    user = User.parse str
    
    page_exists = false
    revision_exists = false
    user.pages.each do |p|                            # Does an entry for the page exist already
      if p.name.eql? page
        page_exists = true
        p.revisions.each do |revision|                # Does an entry for the revision exist already?      
          if revision.revisionid === revisionid
            revision_exists = true
          end
        end
      end
    end
    
    if page_exists                                    # If the page is already there, just add the revision
      if !revision_exists
        user_insert_revision name, str, page, revisionid # If it does, append this revision to the file
      end
    else                                            # If the page is not already there, add it in
      i = str.length
      file =nil
      begin
        if str[i..i+10].eql? "</userpage>" 
          file = str[0..i+10]+"<userpage name=\"#{page}\" >"+str[i..str.length]
          user_insert_revision name, file, page, revisionid
        elsif str[i..i+12].eql? "</registered>"
          file = str[0..i+12]+"<userpage name=\"#{page}\" ></userpage>"+str[i+12+1..str.length]
          user_insert_revision name, file, page, revisionid
        end
        i-=1
      end while file.nil? && i > -1
    end
  else                                                # If it doesn't, then create it
    file = "<?xml version=\"1.0\"?>\n<user>\n<name>#{name}</name>\n<bot>#{bot? name}</bot>\n<registered>#{registered? name}</registered>\n\n</user>"
    File.open("#{@parse_folder}/user_#{name}.xml", "w"){|f| f.write(file)}
    user_add_revision name, page, revisionid    # And call this method again
  end
end

# Add a revision to a page. See definitions/page_template.xml
# for the layout of a page file
def page_add_revision page, user, revisionid
  #  puts "inserting user rev #{revisionid}"
    str = File.read "#{@parse_folder}/page_#{page}.xml"
    file = nil
    i = str.length
    begin
      # Go Backward until you've found the page we're looking for.
      if str[i..i+11].eql? "</revisions>"
        file = str[0..i-1]+"<userrev revisionid=\"#{revisionid}\" user=\"#{user}\" />"+str[i..str.length]
        File.open("#{@parse_folder}/page_#{page}.xml", "w"){|f| f.write(file)}
      end
      i -=1
    end while file.nil? && i > -1
end

# Get the age of a revision. i.e. how long that revision has lasted before it was changed
def compute_edit_age rev1, rev2
  if rev2.nil?
    return nil
  else
    return Time.parse(rev1.timestamp).to_i-Time.parse(rev2.timestamp).to_i
  end
end

# Computes to see if the same person made 2 revisions in a short timespan.
# If they did, then discard the first revision and only keep the second
# Since they obviously wanted the later revision to be their final one
def compute_intermediate_revision rev1, rev2, revs
  time = 3*60*60 # Years*Weeks*Days*Hours*Minues*Seconds
  if rev1.user.eql?(rev2.user) && rev1.age < time
    # puts "These two edits by the same person are very close together"
    revs.pop # Remove the latest revision from the rev list
    return true
  end
  return false
end

# Add a revision to a revision file, based on the xml definition
# as seen in definitions/revision_template.xml
def revision_add_revision rev, revert, page
  revision_file = ""
  if !revert.nil?
    revision_file += "<revision revertid=\"#{revert}\">"
  else
    revision_file += "<revision revertid=\"\">"
  end
  revision_file += "<revid>#{rev.revid}</revid>"
  revision_file += "<parentid>#{rev.parentid}</parentid>"
  revision_file += "<user>#{rev.user}</user>"
  revision_file += "<timestamp>#{rev.timestamp}</timestamp>"
  revision_file += "<unixtime>#{Time.parse(rev.timestamp).to_i}</unixtime>"
  revision_file += "<age>#{rev.age}</age>"
  revision_file += "<comment>#{strip rev.comment}</comment>"
  revision_file += "<text xml:space=\"preserve\">#{strip rev.text}</text>"
  revision_file += "</revision>"
  File.open("#{@parse_folder}/revisions_#{page}.xml", "a"){|f| f.write(revision_file)}
end

# Insert a revision to a user file, based on the xml definition
# as seen in definitions/revision_template.xml
def user_insert_revision name, str, page, revisionid
#  puts "inserting user rev #{revisionid}"
  file = nil
  i = str.length
  begin
    # Go Backward until you've found the page we're looking for.
    if str[i..(i+18+page.length)].eql? "<userpage name=\"#{page}\" >"
      j = i+18+page.length
      begin       # Once you found the page, go forward until we're at the right section to insert
        if str[j..j+10].eql? "</userpage>"
          file = str[0..j-1]+"<userrev revisionid=\"#{revisionid}\" />"+str[j..str.length]
          File.open("#{@parse_folder}/user_#{name}.xml", "w"){|f| f.write(file)}
        end
        j += 1
      end while file.nil? && j < str.length-10
    end
    i -=1
  end while file.nil? && i > -1
end

def user_insert_reverted_to_count name, reverted_to_count
  str = File.read "#{@parse_folder}/user_#{name}.xml"
  file = nil
  i = 0
  begin
    # Go Backward until you've found the page we're looking for.
    if str[i..i+9].eql? "<userpage "
      file = str[0..i-1]+"<reverted_to>#{reverted_to_count}</reverted_to>\n"+str[i..str.length]
      File.open("#{@parse_folder}/user_#{name}.xml", "w"){|f| f.write(file)}
    end
    i +=1
  end while file.nil? && i < str.length
end

def user_insert_reverted_over_count name, reverted_over_count
  str = File.read "#{@parse_folder}/user_#{name}.xml"
  file = nil
  i = 0
  begin
    # Go Backward until you've found the page we're looking for.
    if str[i..i+9].eql? "<userpage "
      file = str[0..i-1]+"<reverted_over>#{reverted_over_count}</reverted_over>\n"+str[i..str.length]
      File.open("#{@parse_folder}/user_#{name}.xml", "w"){|f| f.write(file)}
    end
    i +=1
  end while file.nil? && i < str.length
end

# Add a link to a page file, based on the xml definition
# as seen in the definitions/page_template.xml
def page_add_links page, links
  file = nil
  str = File.read "#{@parse_folder}/page_#{page}.xml"
  i = 0
  begin
    if str[i..i+7].eql? "</name>"
      file = [0..i+7]+links+[i+8..str.length]
      File.open("data/page_#{page}.xml", "w"){|f| f.write(file)}
    end
    i += 1
  end while file.nil? && i < str.length
end

# Compute how long a given number (in seconds) is
# and returns the value in it's appropriate units
def compute_time_taken num
	minute = 60.000000
	hour = 60*minute
	day = 24*hour
	week = 7*day
	year = 52*week
	if num < minute
		return "#{num} seconds"
	elsif num < hour
		return  "#{num/minute} minutes"
	elsif num < day
		return  "#{num/hour} hours"
	elsif num < week
		return  "#{num/day} days"
	elsif num < year
		return  "#{num/week} weeks"
	elsif num > year
		return  "#{num/year} years"	
	end
end

# Compute whether this is a positive, negative or neutral edit.
def compute_value rev, revs
  rev.age
  # In the example shown below, 2 is a negative edit
  #      2
  #    ↗ |
  #  1   |
  #    ↘ ↓
  #      3  
  one = revs.fetch(revs.length-2)
  two = revs.last
  three = rev
  
  if !(one.hash === three.hash) # If its a revert, theres no use in computing the edit distance
#    one_to_two = one.text.jarowinkler_similar two.text
#    two_to_three = two.text.jarowinkler_similar three.text
#    one_to_three =  one.text.jarowinkler_similar three.text
    if one_to_three == 1.0
#  	  puts one
#  	  puts two
#     puts three
    end
    if one_to_two > two_to_three+0.01 && two_to_three+0.01 < one_to_three      
      two.value =  "-"
    end
  end
  if two.age > 60*60*2
    two.value = "+"
  end
  return ""
end

# See if the current revision is exactly the same as a previous revision (a revert)
# Also identify over how many revisions the revert was made
def revert? rev, revs
  i = revs.length
  revs.each do |old_rev|
    if rev.hash.eql? old_rev.hash
      #puts "#{rev.user} just reverted back #{i} revisions to #{each.user}'s version" 
      return old_rev.revid
      # puts revs.fetch(revs.length-(i+1)).user
      # puts "#{rev.hash} #{rev.user} #{rev.timestamp}"
      # puts "#{each.hash} #{each.user} #{each.timestamp}"
    end
    i-=1
  end
  return nil
end

# Checks whether a user is registered
# Returns false if they're not registered, true otherwise
def registered? name
  ip_check = Regexp.new(/^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/) #Regexp to identify IP addresses
  if !ip_check.match(name).nil?       # Checks if username is an IP address
    return false                      # Return false if the name is an IP address (And thus they are not registered)
  else
    return true                       # Return true otherwise
  end
end

def bot? name
  if @bot_list.include? name
    return true
  end
  return false
end

def set_name_length str
  if str.length < 19
    str << ":"
    begin 
      str << " "
    end while str.length < 20
  elsif str.length > 19
    str = str[0..15]
    str << "..: "
  else
    str << ":"
  end
  return str.gsub("_", " ")
end

# Strip any encoding shouldn't be in xml
def strip str
  str.gsub! "<", "&lt;"
  str.gsub! ">", "&gt;"
  str.gsub! "&", "&amp;"
  return str
end
