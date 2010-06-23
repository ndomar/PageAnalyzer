# This file provides a number of custom functions used in the parse.rb file
require "amatch"
include Amatch

# Seperates all the users that edited a page
# into registered and unregistered groups
def process_user_hash
  ip_check = Regexp.new(/^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/) #Regexp to identify IP addresses
  #Make sure the two hases are initilized
  @reg_hash = {} if @reghash.nil?
  @unreg_hash = {} if @reghash.nil?
  
  @user_hash.keys.each do |user|
    if !ip_check.match(user).nil?       # Checks if username is an IP address
      @unreg_hash[user] = @unreg_hash.fetch(user, 0) + 1
    else
      @reg_hash[user] = @reg_hash.fetch(user, 0) + 1
    end
  end
end

def prepare_revision_file rev, revert
  if !revert.nil?
    @revision_file += "<revision revertid=\"#{revert}\">"
  else
    @revision_file += "<revision revertid=\"\">"
  end
  @revision_file += "<revid>#{rev.revid}</revid>"
  @revision_file += "<parentid>#{rev.parentid}</parentid>"
  @revision_file += "<user>#{rev.user}</user>"
  @revision_file += "<timestamp>#{rev.timestamp}</timestamp>"
  @revision_file += "<unixtime>#{Time.parse(rev.timestamp).to_i}</unixtime>"
  @revision_file += "<age>#{rev.age}</age>"
  @revision_file += "<comment>#{strip rev.comment}</comment>"
  @revision_file += "<text xml:space=\"preserve\">#{strip rev.text}</text>"
  @revision_file += "</revision>"
end

# On every turn in the loop the following much be done
def process_revision rev, revs
  #@user_hash[rev.user] = @user_hash.fetch(rev.user, 0)+1    # Collect user information
  rev.hash = Digest::SHA1.hexdigest rev.text                # Set the hash value (a hash of the text) for each revisions
  rev.age = compute_edit_age rev, revs.last                 # Get the edit age
  prepare_revision_file rev, revert?(rev, revs)             # Add the contents of the current revision to the revision file
  
  if revs.length > 1
    compute_intermediate_revision rev, revs.last, revs
  end
  revs.push rev
end

# Check to see if this middle edit was a bad edit, in the eyes of the other two
def bad_edit? rev1, rev2, rev3
  if rev1 > rev2 && rev2 < rev3
    puts rev2.user
    puts rev2.comment
  end
end

# See if the current revision is exactly the same as a previous revision (a revert)
# Also identify over how many revisions the revert was made
def revert? rev, revs
  i = revs.length
  revs.each do |each|
    if rev.hash.eql? each.hash
      #puts "#{rev.user} just reverted back #{i} revisions to #{each.user}'s version" 
      return each.revid
      # puts revs.fetch(revs.length-(i+1)).user
      # puts "#{rev.hash} #{rev.user} #{rev.timestamp}"
      # puts "#{each.hash} #{each.user} #{each.timestamp}"
    end
    i-=1
  end
  return nil
end

# Computes to see if the same person made 2 revisions in a short timespan.
# If they did, then discard the first revision and only keep the second
# Since they obviously wanted the later revision to be their final one
def compute_intermediate_revision rev1, rev2, revs
  time = 3*60*60 # Years*Weeks*Days*Hours*Minues*Seconds
  if rev1.user.eql?(rev2.user) && rev1.age < time
    # puts "These two edits by the same person are very close together"
    revs.pop
  end
end

# Get the age of a revision. i.e. how long that revision has lasted before it was changed
def compute_edit_age rev1, rev2
  if rev2.nil?
    return nil
  else
    return Time.parse(rev1.timestamp).to_i-Time.parse(rev2.timestamp).to_i
  end
end
  
def user_add_revision name, page, revisionid
  if File.exists? "data/user_#{name}.xml"             # Check to see if the user exits
    str = File.read "data/user_#{name}.xml"
    user = User.parse str
    
    page_exists = false
    revision_exists = false
    user.pages.each do |p|                            # Does an entry for the page exist already
      if p.name.eql? page
        page_exists = true
        p.revisions.each do |revision|                # Does an entry for the revision exist already?
          if revision.revisionid.eql? revisionid
            revision_exists = true
          end
        end
      end
    end
    if page_exists                                    # If the page is already there, just add the revision
      if !revision_exists
        user_insert_revision name, str, page, revisionid # If it does, append this revision to the file
      end
    else                                         # If the page is not already there, add it in
      i = str.length
      file =nil
      begin
        if str[i..i+10].eql? "</userpage>" 
          file = str[0..i+10]+"<userpage name=\"#{page}\" ></userpage>"+str[i..str.length]
          File.open("data/user_#{name}.xml", "w"){|f| f.write(file)}
          user_insert_revision name, file, page, revisionid
        elsif str[i..i+16].eql? "</reverted_count>"
          file = str[0..i+16]+"<userpage name=\"#{page}\" ></userpage>"+str[i+16+1..str.length]
          File.open("data/user_#{name}.xml", "w"){|f| f.write(file)}
          user_insert_revision name, file, page, revisionid
        end
        i-=1
      end while file.nil? && i > -1
    end
  else                                                # If it doesn't, then create it
    file = "<?xml version=\"1.0\"?><user><name>#{name}</name><registered></registered><reverts></reverts><reverted_count></reverted_count></user>"
    File.open("data/user_#{name}.xml", "w"){|f| f.write(file)}
    user_add_revision name, page, revisionid    # And call this method again
  end
end

def user_insert_revision name, str, page, revisionid
#  puts "inserting user rev #{revisionid}"
  file = nil
  i = str.length
  begin
    # Go Backward until you've found the page we're looking for.
    if str[i..(i+18+page.length)].eql? "<userpage name=\"#{page}\" >"
      j = i
      begin       # Once you found the page, go forward until we're at the right section to insert
        if str[j..j+10].eql? "</userpage>"
          file = str[0..j-1]+"<userrev revisionid=\"#{revisionid}\" />"+str[j..str.length]
          File.open("data/user_#{name}.xml", "w"){|f| f.write(file)}
        end
        j += 1
      end while file.nil? && j < str.length-10
    end
    i -=1
  end while file.nil? && i > -1
end

def page_add_revision page, user, revisionid
  # Go and add this revision to the page
    # Check to see if the page exits
      # If it doesn't, then create it
      # And call this method again
    # 
      # If it doesn, append this revision to the file
end

def user_create_page name
  
end

def user_add_revert
  
end

def user_add_reverted

end

def strip str
  str.gsub! "<", "&lt;"
  str.gsub! ">", "&gt;"
  str.gsub! "&", "&amp;"
  return str
end