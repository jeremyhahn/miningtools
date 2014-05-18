require "ruby-sendhub"

class SendHubClient

     @@client = nil
     @@contact

     def initialize(ini)
         @@client = SendHub.new(ini.sendhub.apikey, ini.sendhub.phone)
         @@contact = ini.sendhub.contact
     end

     def sms(message)
         @@client.post_messages({:contacts => [@@contact], :text => message})
     end
     
     def contacts
         @@client.get_contacts
     end
end