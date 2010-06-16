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

# Takes the text of 3 revisions and compute the edit distance between them
def process_text revs
  
  rev1 = @first.text.pair_distance_similar @second.text
  rev2 = @second.text.pair_distance_similar @third.text
  rev3 = @first.text.pair_distance_similar @rev.text
  
  puts "#{rev1} : #{@second.user}"
  puts "#{rev2} : #{@third.user}"
  puts "#{rev3} : "
end

#Check to see if this middle edit was a bad edit, in the eyes of the other two
def bad_edit? rev1, rev2, rev3
  if rev1 > rev2 && rev2 < rev3
    puts @second.user
    puts @second.comment
  end
end

def immeditate_revert? rev3
  if rev3 === 1.0
    puts "#{@third.user} just reverted #{@second.user}'s edit, back to #{@first.user}'s version"
  end
end

def compute_immediate_revision
  if @first.user.eql?(@second.user) && (Time.parse(@second.timestamp)-Time.parse(@first.timestamp)) > 15
    puts "These two edits by the same person are very close together"
  elsif @second.user.eql?(@third.user) && (Time.parse(@third.timestamp)-Time.parse(@second.timestamp)) > 15
    puts "These two edits by the same person are very close together"
  end
end