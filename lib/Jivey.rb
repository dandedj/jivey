require 'rubygems' 
require 'rest_client'
require 'rexml/document'
require 'User'
require 'Group'
require 'logger'
require 'savon'

class Jivey
  attr_accessor :log, :url, :username, :password, :retries
  
  def initialize(logger)
      self.log = logger
      self.retries = 3
  end
  
  def get( path )
    tries = 1
    log.debug("Requesting get[#{path}]")
    begin
      response = RestClient.get "http://#{username}:#{password}@#{url}/#{path}"
      log.debug("Response for get[#{path}]")
      log.debug(response)
      doc = REXML::Document.new(response)
      yield doc
    rescue => e
      log.error("Call failed for: #{path}")
      log.error(e)
      if (e.respond_to?('response')) then
        log.error(e.response)
      end
      tries = tries + 1
      if tries <= self.retries then 
        log.info("Retrying get")
        retry
      else
        raise(e)
      end
    end
    response
  end
  
  def post( path, body )
    tries = 1
    log.debug("Requesting post[#{path}]")
    log.debug("body: #{body}")
    begin
      response = RestClient.post "http://#{username}:#{password}@#{url}/#{path}", body, :content_type => 'text/plain'
      log.debug("Response for #{path}")
      log.debug(response)
      doc = REXML::Document.new(response)
      yield doc
    rescue => e
       log.error("Call failed for: #{path}")
       log.error(e)
       if (e.respond_to?('response')) then
         log.error(e.response)
       end
       tries = tries + 1
       if tries <= self.retries then 
         log.info("Retrying post")
         retry
       else
         raise(e)
       end
    end
  end 
  
  def put( path, body )
    tries = 1
    log.debug("Requesting put[#{path}]")
    log.debug("body: #{body}")
    begin
      response = RestClient.put "http://#{username}:#{password}@#{url}/#{path}", body, :content_type => 'text/plain'
      log.debug("Response for #{path}")
      log.debug(response)
      doc = REXML::Document.new(response)
      yield doc
    rescue => e
       log.error("Call failed for: #{path}")
       log.error(e)
       if (e.respond_to?('response')) then
         log.error(e.response)
       end
       tries = tries + 1
        if tries <= self.retries then 
          log.info("Retrying get")
          retry
        else
          raise(e)
        end
    end
  end
  
  def delete( path, element_id )
    tries = 1
    log.debug("Requesting delete[#{path}]")
    begin
      response = RestClient.delete "http://#{username}:#{password}@#{url}/#{path}/#{element_id}"
      log.debug("Response for delete[#{path}/#{element_id}]")
      log.debug(response)
      doc = REXML::Document.new(response)
      yield doc
    rescue => e
       log.error("Call failed for: #{path}/#{element_id}")
       log.error(e)
       if (e.respond_to?('response')) then
         log.error(e.response)
       end
       tries = tries + 1
        if tries <= self.retries then 
          log.info("Retrying get")
          retry
        else
          raise(e)
        end
    end
  end
  
  def username_exists ( user_id )
    begin
      get( "/rpc/rest/userService/users/#{user_id}" ) do |doc| 
        true
      end
    rescue
      false
    end
  end
  
  def email_exists ( email )
    begin
      get( "rpc/rest/userService/usersByEmail/#{email}" ) do |doc| 
        true
      end
    rescue
      false
    end
  end
  
  def create_user ( user )
    body = "
    <createUserWithUser> 
        <user>
            <email>#{user.email}</email>
            <enabled>true</enabled>
            <firstName>#{user.fname}</firstName>
            <lastName>#{user.lname}</lastName>
            <name>#{user.fullname}</name>
            <password>#{user.password}</password>
            <username>#{user.username}</username>
        </user>
    </createUserWithUser>"
    
    post( "rpc/rest/userService/users", body ) do |doc| 
      doc.elements['/ns2:createUserWithUserResponse/return/ID'].text
    end
  end
  
  def update_user ( user_id, user )
    body = "
    <updateUser> 
        <user>
            <ID>#{user_id}</ID>
            <email>#{user.email}</email>
            <enabled>true</enabled>
            <firstName>#{user.fname}</firstName>
            <lastName>#{user.lname}</lastName>
            <name>#{user.fname} #{user.lname}</name>
        </user>
    </updateUser>"
    
    put( "rpc/rest/userService/users", body ) do |doc| 
    end
  end
  
  def remove_profile_field ( field_id )
    
    delete( "rpc/rest/profileFieldService/fields", field_id ) do |doc|
      
    end
  end
  
  def add_user_profile_field_entry ( user_id, field_id, value )
    body = "
    <addProfile> 
        <userID>#{user_id}</userID>
        <profile>
            <fieldID>#{field_id}</fieldID>
            <value>#{value}</value>
        </profile>
    </addProfile>"
    
    post( "rpc/rest/profileService/profiles", body ) do |doc|
    end
  end
  
  def create_community( parent_id, name, display_name, description, contentTypeIds )
    body = "
    <createCommunity> 
        <name>#{name}</name>
        <displayName>#{display_name}</displayName>
        <description>#{description}</description>
        <communityID>#{parent_id}</communityID>
        #{contentTypeIds}
    </createCommunity>"
    
    post( "rpc/rest/communityService/communities", body ) do |doc| 
        doc.elements['/ns2:createCommunityResponse/return/ID'].text
    end
  end
  
  def rename_community( community_id, new_name, contentTypeIds )
    body = "
    <updateCommunity> 
        <community>
            <name>#{new_name}</name>
            <ID>#{community_id}</ID>
            <displayName>#{new_name}</displayName>
            #{contentTypeIds}
        </community>
    </updateCommunity>"
    
    put( "rpc/rest/communityService/communities", body ) do |doc| 
    end
  end
  
  def update_community( community_id, new_root, name, display_name, contentTypeIds )
    body = "
    <updateCommunity> 
        <community>
            <ID>#{community_id}</ID>
            <parentCommunityID>#{new_root}</parentCommunityID>
            <name>#{name}</name>
            <displayName>#{display_name}</displayName>
            #{contentTypeIds}
        </community>
    </updateCommunity>"
    
    put( "rpc/rest/communityService/communities", body ) do |doc| 
    end
  end
  
  def enable_content_types( community_id, content_types )
    
    content_types_string = ''
    content_types.each() do |content_type|
      content_types_string = content_types_string + "
        <availableContentType>#{content_type}</availableContentType>"
    end
    
    body = "
    <updateCommunity> 
        <community>
            <name>#{new_name}</name>
            <ID>#{community_id}</ID>
            <displayName>#{new_name}</displayName>
            #{content_type_string}
        </community>
    </updateCommunity>"
    
    put( "rpc/rest/communityService/communities", body ) do |doc| 
    end
  end
  
  def entitle_group_to_container( group_id, container_type, container_id )
    # This method is broken for REST but works for SOAP so this one method is done differently
    client = Savon::Client.new "http://ec2-184-72-204-197.compute-1.amazonaws.com/rpc/soap/EntitlementService?wsdl"
  
    response = client.add_group_entitlement() do |soap, wsse|
        wsse.username = username
        wsse.password = password
        soap.body = { 
            :groupID => group_id, 
            :containerID => community_id, 
            :containerType => 14, 
            :contentTypeID => 102 }
      end
      
      log.debug( response )
  end
  
  def entitle_group_to_community( group_id, community_id )
    entitle_group_to_container( group_id, 14, community_id ) 
  end
  
  def add_community_watch( user_id, community_id )
    body = "
    <createCommunityWatch> 
        <userID>#{user_id}</userID>
        <communityID>#{community_id}</communityID>
    </createCommunityWatch>"
    
    put( "rpc/rest/watchService/communityWatches", body ) do |doc| 
    end
  end
  
  def entitle_group_to_social_group( group_id, social_group_id )
    entitle_group_to_container( group_id, 700, social_group_id ) 
  end
  
  def remove_group_entitlement( group_id, community_id )
    client = Savon::Client.new "http://ec2-184-72-204-197.compute-1.amazonaws.com/rpc/soap/EntitlementService?wsdl"
  
    response = client.remove_group_entitlement() do |soap, wsse|
        wsse.username = username
        wsse.password = password
        soap.body = { 
            :groupID => group_id, 
            :containerID => community_id, 
            :containerType => 14 }
      end
      log.debug( response )
  end
  
  def get_user_by_email( email )
    id = ''
      get( "rpc/rest/userService/usersByEmail/#{email}" ) do |doc| 
        id = doc.elements['/ns2:getUserByEmailAddressResponse/return/ID'].text
      end
    id
  end
  
  def get_users( start, num )
      ids = []
      get( "rpc/rest/userService/usersBounded/#{start}/#{num}" ) do |doc| 
        doc.elements.each('/ns2:getUsersBoundedResponse/return/ID') do |ele|
           ids << ele.text
        end
      end
      ids
  end
  
  def create_group ( group )
    body = "
    <createGroup> 
        <name>#{group.name}</name>
        <description>#{group.description}</description>
    </createGroup>"
    
    post( "rpc/rest/groupService/groups", body ) do |doc| 
        doc.elements['/ns2:createGroupResponse/return/ID'].text
    end
  end
  
  def create_social_group ( owner, group_name, group_description, content_type_ids )
    body = "
    <createSocialGroup> 
        <name>#{group_name}</name>
        <description>#{group_description}</description>
        <userID>#{owner}</userID>
        <displayName>#{group_name}</displayName>
        #{content_type_ids}
        <typeID>0</typeID>
    </createSocialGroup>"
    
    post( "rpc/rest/socialGroupService/socialGroup", body ) do |doc| 
        puts doc
        doc.elements['/ns2:createSocialGroupResponse/return/ID'].text
    end
  end
  
  
  
  def get_social_group_by_name( name )
    
  id = ''
    get( "rpc/rest/socialGroupService/socialGroupsByName/#{name}" ) do |doc| 
      id = doc.elements['/ns2:getUserByEmailAddressResponse/return/ID'].text
    end
  id
  end
  
  
  def add_user_to_group ( user_id, group_id )
    body = "
    <addMemberToGroup> 
        <userID>#{user_id}</userID>
        <groupID>#{group_id}</groupID>
    </addMemberToGroup>"
    post( "rpc/rest/groupService/groupMembers", body ) do |doc|
    end
  end
  
  def add_user_to_social_group ( user_id, group_id )
    body = "
    <addMember> 
        <userID>#{user_id}</userID>
        <socialGroupID>#{group_id}</socialGroupID>
        <memberType>1</memberType>
    </addMember>"
    post( "rpc/rest/socialGroupService/socialGroupMembers", body ) do |doc|
    end
  end

  def get_all_groups
    groups = [] 
    get("rpc/rest/groupService/groups") do |doc|
      doc.elements["/ns2:getGroupsResponse"].each() do |ele|
        groups << ele.elements['ID'].text
      end
    end
    groups
  end
  
  def get_all_social_groups
    groups = [] 
    get("rpc/rest/socialGroupService/socialGroups") do |doc|
      doc.elements["/ns2:getSocialGroupsResponse"].each() do |ele|
        groups << [ele.elements['ID'].text, ele.elements['name'].text, ele.elements['displayName'].text]
      end
    end
    groups
  end
  
  def remove_social_group( group_id )
    delete( "rpc/rest/socialGroupService/socialGroup", group_id ) do |doc|
    end
  end 
  
  def each_user_in_group( group_id )
    get("rpc/rest/groupService/groupMembers/#{group_id}") do |doc|
      doc.elements["/ns2:getGroupMembersResponse"].each() do |ele|
        yield ele.elements['ID'].text, ele.elements['name'].text
      end
    end
  end
  
  def each_group
    get("rpc/rest/groupService/groups") do |doc|
      doc.elements["/ns2:getGroupsResponse"].each() do |ele|
        yield ele.elements['ID'].text, ele.elements['name'].text
      end
    end
  end
  
  def remove_groups 
    puts "Found : #{get_all_groups.size} groups"
    get_all_groups.each() do |group|
      delete( "rpc/rest/groupService/groups", group ) do |doc|
      end
    end 
  end
  
  def rename_group ( group_id, new_name )
    body = "
    <updateGroup> 
        <group>
            <ID>#{id}</ID>
            <name>#{new_name}</name>
        </group>
    </updateGroup>"
    put("rpc/rest/groupService/groups") do |doc|
    end
  end
  
  def rename_social_group ( group_id, new_name, displayName, contentTypeIDs )
    body = "
    <updateSocialGroup> 
        <socialGroup>
            <ID>#{group_id}</ID>
            <name>#{new_name}</name>
            <displayName>#{new_name}</displayName>
            #{contentTypeIDs}
        </socialGroup>
    </updateSocialGroup>"
    put("rpc/rest/socialGroupService/socialGroups", body) do |doc|
    end
  end
  
  def each_social_group
    get("rpc/rest/socialGroupService/socialGroups") do |doc|
      doc.elements["/ns2:getSocialGroupsResponse"].each() do |ele|
        yield ele.elements['ID'].text, ele.elements['name'].text, ele.elements['displayName'].text, ele.elements['contentTypesIDs']
      end
    end
  end
  
  def get_all_communities
      communities = []
      get("rpc/rest/communityService/communities") do |doc|
        doc.elements['/ns2:getRecursiveCommunitiesResponse'].each() do |ele|
          communities << ele.elements['ID'].text
        end
      end
      communities
  end
  
  def each_community
      get("rpc/rest/communityService/communities") do |doc|
        doc.elements['/ns2:getRecursiveCommunitiesResponse'].each() do |ele|
          puts "-----------\n#{ele}\n-------------"
          yield ele.elements['ID'].text, ele.elements['name'].text, ele.elements['displayName'].text
        end
      end
  end
  
  def remove_communities 
    get_all_communities.each() do |community|
      begin
        delete( "rpc/rest/communityService/communities", community ) do |doc|
        end
      rescue => e
        # This is fine since sub communities will fail
      end
    end
  end
  
  def create_simple_profile_field( name )
    body = "
    <createProfileField> 
        <field>
            <descriptions>
                <locale>
                  <countryCode></countryCode>
                  <languageCode>en</languageCode>
                </locale>
                <value>#{name}</value>
                    
            </descriptions>
                <displayNames>
                    <locale>
                      <countryCode></countryCode>
                      <languageCode>en</languageCode>
                    </locale>
                    <value>#{name}</value>
                </displayNames>
                <editable>true</editable>
                <filterable>true</filterable>
                <typeID>9</typeID>
                <name>#{name}</name>
                <visibleToUsers>true</visibleToUsers>
            
        </field>
    </createProfileField>"
    
    post( "rpc/rest/profileFieldService/fields", body ) do |doc| 
        doc.elements['/ns2:createProfileFieldResponse/return/ID'].text
    end
  end
  
  def get_profile_fields
    fields = []
    get( "rpc/rest/profileFieldService/fields" ) do |doc| 
      doc.elements.each('/ns2:getProfileFieldsResponse/return') do |ele|
        ele.elements.each('displayNames') do |name|
         if name.elements['locale/languageCode'].text == 'en' then
           puts "#{ele.elements['ID'].text} -> #{name.elements['value'].text}"
           field = [ele.elements['ID'].text, name.elements['value'].text]
           fields << field
         end
        end
      end
    end
    fields
  end
  
  def get_default_profile_fields
    fields = []
    get( "rpc/rest/profileFieldService/defaultFields" ) do |doc| 
      doc.elements.each('/ns2:getDefaultFieldsResponse/return') do |ele|
        ele.elements.each('displayNames') do |name|
         if name.elements['locale/languageCode'].text == 'en' then
           puts "#{ele.elements['ID'].text} -> #{name.elements['value'].text}"
           field = [ele.elements['ID'].text, name.elements['value'].text]
           fields << field
         end
        end
      end
    end
    fields
  end
  
  
  def create_tbe_user ( user )
    user_id = create_user( user )
    log.debug("Created base user with id : #{user_id}")
    add_user_profile_field_entry( user_id, 1, user.company )
    # add_user_profile_field_entry (user_id, 5018, "#{user.location}")
    #     add_user_profile_field_entry (user_id, 5001, 1)
    #     add_user_profile_field_entry (user_id, 5017, 1)
    user_id
  end
  
end