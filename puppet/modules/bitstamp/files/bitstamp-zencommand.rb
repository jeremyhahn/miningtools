#!/usr/bin/ruby

require "typhoeus"
require "json"

response = Typhoeus.get("https://www.bitstamp.net/api/ticker/")
json = JSON.parse(response.response_body)

sell = json['ask']
buy = json['last']
high = json['high']
low = json['low']

puts "OK|buy=#{buy} sell=#{sell} high=#{high} low=#{low}"

