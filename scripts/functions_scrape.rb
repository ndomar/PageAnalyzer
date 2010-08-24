# Truncates the head of an xml document making it
# start with the opening tag of the first revision
def remove_head str, state
  if state.eql? "rev"
    match_str = "<rev revid="
  elsif state.eql? "bl"
    match_str = "<bl pageid="
  end
  i = 0; cont = "go"
  begin
    if str[i..i+10].eql? match_str
      str = str[i..str.length]
      cont = "stop"
    end
    i += 1
  end while cont != "stop" && i < str.length
  return str
end

# Truncates the tail of an xml document making it
# end on the close tag of the last revision
def remove_tail str, state
  if state.eql? "rev"
    match_str = "</rev>"
    j=5
  elsif state.eql? "bl"
    match_str = "</backlinks>"
    j=11
  end
  i = str.length; cont = "go"
  begin
    if str[i..i+j].eql? match_str
      if state.eql? "rev"
        @tail = str[i+j+1..str.length] # In case we reach the reach the end of the revisions and need to reinstate the tail
        str = str[0..i+j]
      elsif state.eql? "bl"
        @tail = str[i..str.length] # In case we reach the reach the end of the revisions and need to reinstate the tail
        str = str[0..i-1]
      end
      cont = "stop"
    end
    i -= 1
  end while cont != "stop" && i > 0
  return str
end