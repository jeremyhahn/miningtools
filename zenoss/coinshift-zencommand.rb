#!/usr/bin/ruby

require_relative "lib/Coinshift"

address = ARGV[0]
if address == nil
  puts "Usage: coinshift-zencommand.rb [BTC Address]"
  exit 1
end

coinshift = Coinshift.new address
zenresponse = "OK|hashrate=#{coinshift.hashrate} stalerate=#{coinshift.stalerate} btc_expected=#{coinshift.btc_payout_expected} btc_total_paid=#{coinshift.btc_payout_total} btc_recently_paid=#{coinshift.btc_recently_paid}"
puts zenresponse
