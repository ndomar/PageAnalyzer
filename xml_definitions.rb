# HappyMapper uses these classes to define the object to
# extract from the XML. What attributes it has etc
# Each attribute/element can be called as a method

# Defines a revision. Mainly used in the parsing code.
class Rev
  include HappyMapper
  attribute :revid, Integer         # The unique identifier of a revision
  attribute :parentid, Integer      # No idea what this is yet :P
  attribute :user, String           # The name of the user that made a change
  attribute :comment, String        # Comment a user made about a revision
  attribute :timestamp, String      # DateTime a revision was made
  element :text, String             # Used to access the text of a revision
  element :hash, String             # A hash of the text of the revision. I added this to make it easy to check if two revisions were identical
  element :age, Integer             # A unix timestamp of how long an edit lasted before another revision came along
end

# Defines a backlink. Used to get all the articles that link to a page
class Bl
  include HappyMapper
  attribute :pageid, Integer
  attribute :title, String
end

# Defines a login object. Used mainly in wiki_login.rb during the authentication process.
class Login
  include HappyMapper
  attribute :result, String         #Is either NeedToken or Success
  attribute :token, String          #NeedToken
  attribute :lguserid, String       #Success
  attribute :lgusername, String     #Success
  attribute :lgtoken, String        #Success
  attribute :cookieprefix, String   #Success
  attribute :sessionid, String      #Success
end
