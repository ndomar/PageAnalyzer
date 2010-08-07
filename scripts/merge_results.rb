["functions"].each {|x| require x}
results = File.read("results.txt").split "\n"
users = File.read("user_list.ssf").split "\n"

i=0
results.each do |result|
  if result.include? "3:reliable"
    user_insert_rating "#{@parse_folder}/user_#{users[i]}.xml", "reliable"
  elsif result.include? "2:other"
    user_insert_rating "#{@parse_folder}/user_#{users[i]}.xml", "other"
  end
  i += 1
end