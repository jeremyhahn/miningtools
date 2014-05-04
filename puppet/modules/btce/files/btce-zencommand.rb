#!/usr/bin/ruby

require "typhoeus"
require "json"

response = Typhoeus.get("https://btc-e.com/api/2/btc_usd/ticker")
json = JSON.parse(response.response_body)

sell = json['ticker']['sell']
buy = json['ticker']['buy']
high = json['ticker']['high']
low = json['ticker']['low']

puts "OK|buy=#{buy} sell=#{sell} high=#{high} low=#{low}"

