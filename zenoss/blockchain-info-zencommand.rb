#!/usr/bin/ruby

require "date"
require "time_difference"
require "typhoeus"
require "json"

address = ARGV[0]
response = Typhoeus.get("https://blockchain.info/address/#{address}?format=json&limit=5")
json = JSON.parse(response.response_body)

total_received=json["total_received"]
final_balance=json["final_balance"]
transactions=json["n_tx"]
total_sent=json["total_sent"]

s_total_received = total_received.to_s
s_final_balance = final_balance.to_s

if s_total_received.length > 8
  pieces = s_total_received.scan(/(\d+)(\d{8})/)
  total_received = "#{pieces[0][0]}.#{pieces[0][1]}"
end

if s_final_balance.length > 8
  pieces = s_final_balance.scan(/(\d+)(\d{8})/)
  final_balance = "#{pieces[0][0]}.#{pieces[0][1]}"
end

puts "OK|total_received=#{total_received} final_balance=#{final_balance} transactions=#{transactions} total_sent=#{total_sent}"

