#!/usr/bin/ruby

require "net/http"
require "uri"

class Coinshift

    @@html = nil

    def initialize(address)
      uri = URI.parse("http://coinshift.com/account/#{address}/")
      http = Net::HTTP.new(uri.host, uri.port)
      @@html = http.request(Net::HTTP::Get.new(uri.request_uri)).body
    end

    def parse_date(str_date) 
        return str_date[/\d{4}-\d{2}-\d{2}/]
    end

    def hashrate
        matcher = @@html.match(/Accepted\<\/h4\>.*?\>([0-9]*\.?[0-9]*)\sKh\/s/)
        return 0 if matcher == nil
        return matcher.captures[0].to_f * 1000
    end

    def stalerate
      matcher = @@html.match(/Rejected\<\/h4\>.*?\>([0-9]*\.?[0-9]*)\sKh\/s/)
      return 0 if matcher == nil
      return matcher.captures[0].to_f
    end

    def btc_payout_total
      matcher = @@html.match(/All\stime\spayouts:\s\<strong\>([0-9]*\.?[0-9]*)\sBTC/)
      return 0 if matcher == nil
      return matcher.captures[0].to_f
    end

    def btc_payout_expected
      matcher = @@html.match(/Estimated\sUnexchanged\<\/h4\>.*?\>([0-9]*\.?[0-9]*)\sBTC/)
      return 0 if matcher == nil
      return matcher.captures[0].to_f || 0
    end

    def btc_recently_paid
      btc_payout_recent = @@html.scan(/Last\s\d+\spayouts.*?<td>\n\s+([0-9]*\.?[0-9]*).*?<td>\s+(\w+\s\d+\s\w+\s\d+\s\d+:\d+)\n/m) || 0
      last_date = nil
      btc_payout_today = 0
      btc_payout_recent.each do |amount, datetime|
        if last_date == nil
          last_date = parse_date datetime
        end
        next if amount.empty?
        next if last_date != (parse_date datetime)
        btc_payout_today += amount.to_f
      end 
      return btc_payout_today.to_f
    end
end

address = ARGV[0]
if address == nil
  puts "Usage: coinshift-zencommand.rb [BTC Address]"
  exit 1
end

coinshift = Coinshift.new address
zenresponse = "OK|hashrate=#{coinshift.hashrate} stalerate=#{coinshift.stalerate} btc_expected=#{coinshift.btc_payout_expected} btc_total_paid=#{coinshift.btc_payout_total} btc_recently_paid=#{coinshift.btc_recently_paid}"
puts zenresponse
