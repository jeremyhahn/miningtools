#!/usr/bin/ruby

require_relative "lib/Coinsolver"

address = ARGV[0]
if address == nil
  puts "Usage: coinsolver-zencommand.rb [BTC Address]"
  exit 1
end

coinsolver = Coinsolver.new address
zenresponse = "OK|hashrate=#{coinsolver.hashrate} stalerate=#{coinsolver.stalerate} btc_expected=#{coinsolver.btc_payout_expected} btc_total_paid=#{coinsolver.btc_payout_total} btc_recently_paid=#{coinsolver.btc_recently_paid}"
puts zenresponse
