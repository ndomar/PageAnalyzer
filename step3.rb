["rubygems", "happymapper", "definitions/xml_definitions"].each {|x| require x}

pages = File.read("pages.txt").split

pages.each do |page|
  revisions = Revision.parse File.read"data/revisions_#{page}.xml"
  revisions.each do |revision|
    if !revision.revertid.nil?
      puts revision.revertid
    end
  end
  
end