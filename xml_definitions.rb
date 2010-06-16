# HappyMapper uses this class to define a Revision, 
# what attributes each revision has, and how to access
# the text of that revision.

class Rev
  include HappyMapper
  attribute :revid, Integer
  attribute :parentid, Integer
  attribute :user, String
  attribute :comment, String
  attribute :timestamp, String
  element :text, String
end

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