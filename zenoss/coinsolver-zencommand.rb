#!/usr/bin/ruby

require "net/http"
require "uri"
require "json"

class Coinsolver

    @@json = nil

    def initialize(address)
      uri = URI.parse("http://coinsolver.com/api.php?getaccountinfo=#{address}")
      http = Net::HTTP.new(uri.host, uri.port)
      body = http.request(Net::HTTP::Get.new(uri.request_uri)).body
      @@json = JSON.parse(body)
    end

    def hashrate
        return @@json['hashrate'].to_f
    end

    def stalerate
      return 0  # unsupported
    end

    def btc_payout_total
      return @@json['total_btc_paid']
    end

    def btc_payout_expected
      return @@json['btc_unexchanged'].to_f
    end

    def btc_recently_paid
      return @@json['btc_balance']
    end
end

address = ARGV[0]
if address == nil
  puts "Usage: coinsolver-zencommand.rb [BTC Address]"
  exit 1
end

coinsolver = Coinsolver.new address
zenresponse = "OK|hashrate=#{coinsolver.hashrate} stalerate=#{coinsolver.stalerate} btc_expected=#{coinsolver.btc_payout_expected} btc_total_paid=#{coinsolver.btc_payout_total} btc_recently_paid=#{coinsolver.btc_recently_paid}"
puts zenresponse
