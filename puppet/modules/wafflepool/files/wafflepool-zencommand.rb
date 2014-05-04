#!/usr/bin/ruby

require "net/http"
require "uri"

class WafflePool

    @@html = nil

    def initialize(address)
      uri = URI.parse("http://wafflepool.com/miner/#{address}")
      http = Net::HTTP.new(uri.host, uri.port)
      @@html = http.request(Net::HTTP::Get.new(uri.request_uri)).body
    end

    def parse_date(str_date) 
        return str_date[/\d{4}-\d{2}-\d{2}/]
    end

    def hashrate
        captured_hashrate = @@html.match(/Hash Rate:\<\/b\>\s([0-9]*\.?[0-9]*)\s(M?k?)H\/s/m).captures
        return 0 if captured_hashrate == nil || captured_hashrate.length < 2
        return captured_hashrate[0].to_f * 1000 if captured_hashrate[1] == "k"
        return captured_hashrate[0].to_f * 1000000 if captured_hashrate[1] == "M"
    end
    
    def stalerate
      return @@html.match(/([0-9]*\.?[0-9]*)%\<\/td\>/m).captures[0] || 0
    end

    def btc_payout_total
      return @@html.match(/\<b\>Bitcoins\ssent.*?\s([0-9]*\.[0-9]*)\<br\>/).captures[0] || 0
    end

    def btc_payout_expected
      return @@html.match(/\<b\>Bitcoins\sexpected.*\s([0-9]*\.[0-9]*)\<br\>/m).captures[0] || 0
    end

    def btc_recently_paid
      btc_payout_recent = @@html.scan(/\<td\>(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}).*\n\<td\>([0-9]*\.?[0-9]*).*?\<\/td\>/) || 0
      last_date = nil
      btc_payout_today = 0
      btc_payout_recent.each do |datetime, amount|
        if last_date == nil
          last_date = parse_date datetime
        end
        next if amount.empty?
        next if last_date != (parse_date datetime)
        btc_payout_today += amount.to_f
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

