#!/usr/bin/ruby

require "net/http"
require "uri"

def parse_date(str_date) 
    return str_date[/\d{4}-\d{2}-\d{2}/]
end

address = ARGV[0]
if address.empty? || address.nil?
  puts "BTC Address argument required"
  puts "Usage: wafflepool-zencommand.rb [BTC Address]"
end

uri = URI.parse("http://wafflepool.com/miner/#{address}")
http = Net::HTTP.new(uri.host, uri.port)

stats_html = http.request(Net::HTTP::Get.new(uri.request_uri)).body

hashrate = stats_html.match(/Hash Rate:\<\/b\>\s([0-9]*\.?[0-9]*)\sMH\/s/m).captures[0]
stalerate = stats_html.match(/([0-9]*\.?[0-9]*)%\<\/td\>/m).captures[0]
btc_expected = stats_html.match(/\<b\>Bitcoins\sexpected.*\s([0-9]*\.[0-9]*)\<br\>/m).captures[0]
btc_payout_recent = stats_html.scan(/\<td\>(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}).*\n\<td\>([0-9]*\.?[0-9]*).*?\<\/td\>/)

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

zenresponse = "OK|hashrate=#{hashrate} stalerate=#{stalerate} btc_expected=#{btc_expected} btc_payout_today=#{btc_payout_today}"
puts zenresponse

