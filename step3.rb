["rubygems", "happymapper", "definitions/xml_definitions", "functions"].each {|x| require x}
puts "------------------------------------------------------------------------------------------"
pages = File.read("pages.txt").split

@revert_hash        = {}
@user_reverted_to   = {}
@user_reverted_over = {}

@revert_high = 0
@revert_low = 0

start = Time.now
t = 0
i=0
pages.each do |page|
  revert_count = 0
  prev_revert_id = 0
  revisions = Revision.parse File.read"parsed_data/revisions_#{page}.xml"
  revisions.reverse.each do |revision|
    
    if @revert_hash.has_key? revision.revid
      @user_reverted_to[revision.user] = @user_reverted_to.fetch(revision.user, 0) + @revert_hash[revision.revid]
#      puts @revert_hash[revision.revid].to_s+" "+revision.revid.to_s
#      t += @revert_hash[revision.revid]
    end
      
    if !revision.revertid.nil?
      #puts revision.user+" "+revision.revertid.to_s
      @revert_hash[revision.revertid] = @revert_hash.fetch(revision.revertid, 0) + 1
      @revert_high = revision.revid
      @revert_low = revision.revertid
    end
    
    if revision.revid > @revert_low && revision.revid < @revert_high
      @user_reverted_over[revision.user] = @user_reverted_over.fetch(revision.user, 0) + 1
    end
    
    # We've found the person who was being reverted to'
    if prev_revert_id === revision.revid
      #puts "-- #{revision.user} is the originator" #{revision.revid}"
      prev_revert_id = 0
    end 
     
    # This person just had their revision reverted over
    if prev_revert_id != 0 && revision.revertid.nil?
      #puts "  #{revision.user} just got his edit reverted "#{revision.revid}"
#      @user_reverted_over[revision.user] = @user_reverted_over.fetch(revision.user, 0) + 1
    end
     
     
   if !revision.revertid.nil?
     revert_count +=1
      if prev_revert_id == revision.revertid
        #puts "#{revision.user}'s revision #{revision.revid} is a revert back to #{revision.revertid}"
       else
        #puts 
        #puts "#{revision.user}'s revision #{revision.revid} is a revert back to #{revision.revertid}"
      end
      prev_revert_id = revision.revertid
    else
      #puts "intermediate revision #{revision.revid} - #{revision.user}"
   end
   
  end
  puts "#{page} has #{revert_count} reverts over #{revisions.length} revisions"
  #puts t
end

puts "Time to complete this run: #{compute_time_taken(Time.now-start)}"
print "\a\a\a\a\a\a\a\a\a\a"

@user_reverted_over.keys.sort.each do |key|
#  puts "#{key} #{@user_reverted_over[key]}"
  user_insert_reverted_over_count key, @user_reverted_over[key]
end


@user_reverted_to.keys.sort.each do |key|
  user_insert_reverted_to_count key, @user_reverted_to[key]
end
