good   = ["FA", "A", "GA","B"]
medium = ["C"]
poor   = ["Start", "Stub"]

file = "pages_list.txt"

File.open(file, "w"){|f| f.write("")}

# Go though the pages
[good, medium, poor].each do |group|
  pages = []
  group.each do |file|
    pages += File.read("pages/Articles_#{file}.txt").split
  end
  str = ""
  i   = 0
  chance = 1-(100.000/pages.size)
  
  begin
    pages_write_count = 0
    str.each {|t| pages_write_count += 1 }
    if i >= pages.size then i = 0 end
    if (rand(chance*100) > rand(chance*100)+(100-(chance*100))) && !str.include?(pages[i])
      str += pages[i]+"\n"
      puts pages[i]
    end
    i += 1
  end while pages_write_count <= 150
  File.open(file, "a"){|f| f.write(str)}
  puts "------------------------------------"
end
