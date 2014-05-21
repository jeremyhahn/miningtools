#!/usr/bin/ruby

require 'socket'
require_relative 'lib/CGMinerAPI'

hostname = 'localhost'
port = 4028

command = ARGV[0]
argument = nil

if command.include? "|"
  pieces = command.split("|")
  command = pieces[0]
  argument = pieces[1]
end

if command == nil
  puts "Usage: cgminer-api-zencommand.rb [ summary | switchpool ] "
  exit 0
end

case command

   when "summary"
      api = CGMinerAPI.new hostname, port
      api.summary
   when "switchpool"
      api = CGMinerAPI.new hostname, port
      api.switchpool argument
   else
      puts "Invalid command: " + command
end
