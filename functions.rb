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

# On every turn in the loop the following much be done
def process_revision rev, revs
  @user_hash[rev.user] = @user_hash.fetch(rev.user, 0)+1    # Collect user information
  rev.hash = Digest::SHA1.hexdigest rev.text                # Set the hash value (a hash of the text) for each revisions
  rev.age = compute_edit_age rev, revs.last                 # Get the edit age
  revert? rev, revs
  if revs.length > 1
    compute_intermediate_revision rev, revs.last, revs
  end
  revs.push rev
end

#   Takes the text of 3 revisions and compute the edit distance between them
#   rev1 = @first.text.pair_distance_similar @second.text
#   rev2 = @second.text.pair_distance_similar @third.text
#   rev3 = @first.text.pair_distance_similar @rev.text

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
  i = 1
  revs.reverse.each do |each|
    if rev.hash.eql? each.hash
      puts "#{rev.user} just reverted back #{i} revisions to #{each.user}'s version"
      puts revs.fetch(revs.length-(i+1)).user
      # puts "#{rev.hash} #{rev.user} #{rev.timestamp}"
      # puts "#{each.hash} #{each.user} #{each.timestamp}"
    end
    i+=1
  end
# def immeditate_revert? rev3
#   if rev3 === 1.0
#     puts "#{@third.user} just reverted #{@second.user}'s edit, back to #{@first.user}'s version"
#   end
# end
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