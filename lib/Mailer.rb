require 'socket'
require 'net/smtp'

class Mailer

   @@local_hostname = nil
   @@hostname = nil
   @@port = nil

   def initialize(hostname, port, local_hostname = "localhost")
       @@hostname = hostname
       @@port = port
       @@local_hostname = local_hostname
   end

   def send(params)

     _message = <<MESSAGE
From: #{params[:from_name]} <#{params[:from]}>
To: #{params[:to_name]} <#{params[:to]}>
Subject: #{params[:subject]}

#{params[:message]}
MESSAGE
       smtp = Net::SMTP.new @@hostname, @@port
       smtp.enable_starttls
       smtp.start(@@hostname, params[:username], params[:password], :login) do |server|
          server.send_message _message, params[:from], params[:to]
       end
   end
end