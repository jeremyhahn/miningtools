#!/usr/bin/ruby

require "net/http"
require "uri"
require "json"

class WafflePool

    @@json = nil

    def initialize(address)
      uri = URI.parse("http://wafflepool.com/tmp_api?address=#{address}")
      http = Net::HTTP.new(uri.host, uri.port)
      body = http.request(Net::HTTP::Get.new(uri.request_uri)).body
      @@json = JSON.parse(body)
    end

    def parse_date(str_date) 
        return str_date[/\d{4}-\d{2}-\d{2}/]
    end

    def hashrate
        captured_hashrate = @@json['hash_rate'].to_f
        str_hashrate = @@json['hash_rate_str']
        return captured_hashrate * 1000 if str_hashrate.include?("kH")
        return captured_hashrate * 1000000 if str_hashrate.include?("MH")
    end

    def stalerate
      return @@json['worker_hashrates'][0]['stalerate'].to_f
    end

    def btc_payout_total
      return @@json['balances']['sent']
    end

    def btc_payout_expected
      return @@json['balances']['unconverted'].to_f
    end

    def btc_recently_paid
      last_date = parse_date Time.new.to_s
      btc_payout_today = 0
      @@json['recent_payments'].each do |recent|
        date = parse_date recent['time']
        break if date != last_date || date.nil?
        last_date = date
        btc_payout_today += recent['amount'].to_f
      end
      return btc_payout_today
    end
end

address = ARGV[0]
if address == nil
  puts "Usage: wafflepool-zencommand.rb [BTC Address]"
  exit 1
end

wafflepool = WafflePool.new address
zenresponse = "OK|hashrate=#{wafflepool.hashrate} stalerate=#{wafflepool.stalerate} btc_expected=#{wafflepool.btc_payout_expected} btc_total_paid=#{wafflepool.btc_payout_total} btc_recently_paid=#{wafflepool.btc_recently_paid}"
puts zenresponse

