["rubygems", "happymapper", "definitions/xml_definitions"].each {|x| require x}
puts "------------------------------------------------------------------------------------------"
pages = File.read("pages.txt").split

pages.each do |page|
  revert_count = 0
  prev_revert_id = 0
  revisions = Revision.parse File.read"parsed_data/revisions_#{page}.xml"
  revisions.reverse.each do |revision|
    if prev_revert_id === revision.revid
      puts "-- #{revision.user} is the originator" #{revision.revid}"
      prev_revert_id = 0
    end 

    if prev_revert_id != 0 && revision.revertid.nil?
      puts "  #{revision.user} just got his edit reverted "#{revision.revid}"
    end
    
    if !revision.revertid.nil?
      revert_count +=1
      if prev_revert_id == revision.revertid
        puts "#{revision.user}'s revision #{revision.revid} is a revert back to #{revision.revertid}"
      else
        puts 
        puts "#{revision.user}'s revision #{revision.revid} is a revert back to #{revision.revertid}"
      end
      prev_revert_id = revision.revertid
    else
      #puts "intermediate revision #{revision.revid} - #{revision.user}"
    end
    
  end
  puts "\n#{page} has #{revert_count} reverts over #{revisions.length} revisions"
  
end