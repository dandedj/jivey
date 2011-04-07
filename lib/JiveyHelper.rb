require "User"

def calculate_username ( user )
	if user.fname && user.lname then
	  username = "#{user.fname[0..0]}#{user.lname}"
	elsif user.fullname then
  
	  matches = user.fullname.scan(/(.*)\s(.*)/)
	  if matches.size > 0 then
	    # first and last case
	    username = "#{matches[0][0][0..0]}#{matches[0][1]}"
	  else
	    # middle initial case
	    matches = user.fullname.scan(/(.*)\s(.*)\s(.*)/)
	    username = "#{matches[0][0][0..0]}#{matches[0][2]}"
	  end
	end

	if username == nil or username.size == 0 then
	  username = user.email[0..(user.email.index('@') - 1)]
	end
	
	if username != nil then 
	  username = username.downcase
	end
	puts username
	username
end