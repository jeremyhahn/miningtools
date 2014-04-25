#!/usr/bin/ruby

require 'socket'

class CGMinerAPI 

  def initialize(hostname, port, command)
      socket = TCPSocket.open(hostname, port)
      socket.write command
      @response = socket.read
      socket.close
      #puts "[DEBUG]: " + @response
  end

  def parse_metric(metric)

    supported_metrics = ["elapsed", "mhs_av", "mhs_5s", "found_blocks", "accepted", "getworks", "rejected",
       "hardware_errors", "discarded", "stale", "get_failures", "total_mh", "difficulty_accepted", "difficulty_rejected",
       "difficulty_stale", "best_share", "device_hardware", "device_rejected", "pool_rejected", "pool_stale"]

    metric_pieces = metric.split("=")
    name = metric_pieces[0].downcase.sub(/ /, "_").sub(/%/, "")

    return nil if !supported_metrics.include?(name)

    value = metric_pieces[1]

    return nil if value.nil?

    value_pieces = metric.split(",")
    this_metric_pieces = value_pieces[0].split("=")
    this_metric_value = this_metric_pieces[1]

    return name + "=" + this_metric_value
  end
  
  def summary() 

    zencommand_response = "OK|"

    pieces = @response.split("|")
    summary = pieces[1]
    summary_pieces = summary.split(",")

    i=1
    summary_pieces.each do |metric|
      
      parsed_metric = parse_metric metric
      next if parsed_metric.nil?
      zencommand_response += parsed_metric
      if i < summary_pieces.length
         zencommand_response += " "
      end
    end

    puts zencommand_response
    
  end
  
end

hostname = 'localhost'
port = 4028

command = ARGV[0]

if command == nil
  puts "Usage: cgminer-api-zencommand.rb [ summary | dev[index] ] "
  exit 0
end

case command
  
   when "summary"
      api = CGMinerAPI.new hostname, port, command
      api.summary
   else
      puts "Invalid command: " + command
end
