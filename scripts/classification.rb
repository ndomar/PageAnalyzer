require "functions"

Dir.chdir("./parsed_data")
for file in Dir['**/user_*'].reverse
  edit_count = 0
  page_count = 0
  str = ""
  name = file[5..file.length-5]
  print "\n    >"+name
  user = User.parse File.read "#{file}"
  if user.registered == "true" && !user.name.include?(",") && !user.name.include?("'") && user.rating.nil?
    
    user.pages.each do |page|
    page_count += 1
      print "\n        "+set_name_length(page.name)
      str += '"http://en.wikipedia.org/w/index.php?title='+page.name+'&limit=1300&action=history" '
      page.revisions.each do |revision|
      edit_count += 1
        print "           "+revision.revisionid.to_s
        #str+= ' "http://en.wikipedia.org/w/index.php?title="'+page.name+'"&oldid='+revision.revisionid.to_s+'"'
      end
    end
    print "\n        "
    if user.reverted_over.nil? then reverted_over = 0 else reverted_over = user.reverted_over end
    if edit_count > 50
      user_insert_rating file, "reliable"
      puts "reliable"
    elsif reverted_over > 5 #edit_count > 9 && page_count < 20
      IO.popen('pbcopy', 'r+').puts name
      #IO.popen('xsel –clipboard –input', 'r+') { |clipboard| clipboard.puts name }
      system "open /Applications/Browsers/'Google Chrome.app'/ #{str} " # Mac
      # system "google-chrome #{str}" # Linux
      print "\n"
      rating = gets.chomp
      
      if rating.eql? "r"
        user_insert_rating file, "reliable"
        puts "reliable"
      elsif rating.eql? "o"
        puts "other"
        user_insert_rating file, "unreliable"
      elsif rating.eql? "s"
        puts "skip"
      else
        puts "skip"
      end
    end
  end
end
