#!/usr/bin/ruby

require_relative "lib/WafflePool"

address = ARGV[0]
if address == nil
  puts "Usage: wafflepool-zencommand.rb [BTC Address]"
  exit 1
end

wafflepool = WafflePool.new address
zenresponse = "OK|hashrate=#{wafflepool.hashrate} stalerate=#{wafflepool.stalerate} btc_expected=#{wafflepool.btc_payout_expected} btc_total_paid=#{wafflepool.btc_payout_total} btc_recently_paid=#{wafflepool.btc_recently_paid}"
puts zenresponse
