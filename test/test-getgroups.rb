require 'rexml/document'
require 'Jivey'
require 'User'


log = Logger.new(STDOUT)
log.level = eval("Logger::DEBUG")

jivey = Jivey.new( log )
 jivey.url = "knowledgeexchange.taleo.com"
 jivey.username = "dandedj"
 jivey.password = "Hh1134"



jivey.each_user_in_group( 1024 ) do |userid|
  jivey.add_community_watch( userid, 2345 )
end

# http://taleo.uat3.hosted.jivesoftware.com/rpc/rest/watchService/users/14/2345/1
# http://domain:port/application_context/rpc/rest/watchService/users/{objectType}/{objectID}/{watchType}
puts "Done"
 
