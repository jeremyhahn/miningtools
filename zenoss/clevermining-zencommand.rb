#!/usr/bin/ruby

require "net/http"
require "uri"
require_relative 'lib/CloudFlare'

class CleverMining

    @@html = nil

    def initialize(address)
      @@html = CloudFlare.scrape "http://clevermining.com/users/12mdN8NbiC1xRm8NaXmwJUjLi9BwTuFguT"
    end

    def hashrate

       puts @@html
       puts @@html.match(/Hashrate/)

       exit 0
       
    end

    def stalerate
      return 0 # unavailable
    end

    def btc_payout_total
      return @@html.match(/Total\sProfits.*>([0-9]*\.?[0-9]*)\sBTC/).captures[0] || 0
    end

    def btc_payout_expected
      return @@html.match(/Total\sExpected.*>([0-9]*\.?[0-9]*)\sBTC/).captures[0] || 0
    end

    def btc_recently_paid
      return @@html.scan(/Last\s24h\sProfits.*>(0.00000000)\sBTC/) || 0
    end
end

address = ARGV[0]
if address == nil
  puts "Usage: clevermining-zencommand.rb [BTC Address]"
  exit 1
end

clevermining = CleverMining.new address
zenresponse = "OK|hashrate=#{clevermining.hashrate} stalerate=#{clevermining.stalerate} btc_expected=#{clevermining.btc_payout_expected} btc_total_paid=#{clevermining.btc_payout_total} btc_recently_paid=#{clevermining.btc_recently_paid}"
puts zenresponse
