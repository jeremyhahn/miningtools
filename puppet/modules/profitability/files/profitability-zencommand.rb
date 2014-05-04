#!/usr/bin/ruby

require "date"
require "time_difference"
require_relative "lib/CloudFlare"
require_relative "lib/CGMinerAPI"
require_relative "lib/RubyINI"
require_relative "lib/Mailer"

class WafflePool
    def self.get_btc_per_mh
        response = Typhoeus.get("http://www.wafflepool.com/stats")
        html = response.response_body
        return html.match(/\<\/thead\>\n\<tr\>\n\<td\>.*$\n<td.*$\n<td.*$\n<td.*right\"\>([0-9]*\.?[0-9]*)\<\/td\>/).captures[0].to_f
    end
end

class CleverMining
    def self.get_btc_per_mh
        html = CloudFlare.scrape "http://www.clevermining.com"
        return html.match(/\<\/i\>([0-9]*\.?[0-9]*)\sBTC\/day\sper\sMH\/s\<\/a\>/).captures[0].to_f
    end
end

class Coinshift
    def self.get_btc_per_mh
        response = Typhoeus.get("http://www.coinshift.com", followlocation: true)
        html = response.response_body
        return html.match(/\<h1\salign.*?\>([0-9]*\.?[0-9]*)\<\/h1\>\n\s+\<h3\salign.*\>BTC\/MH\/day\<\/h3\>/).captures[0].to_f      
    end
end

class Multipool
    def self.get_btc_per_mh
        response = Typhoeus.get("http://api.multipool.us/api.php")
        json = JSON.parse(response.response_body)
        return json["prof"]["scrypt_1d"].to_f
    end
end

def send_notification(ini, message)
    mailer = Mailer.new ini.smtp.hostname, ini.smtp.port
    params = {
      :from => "profitability-monitor@#{ini.local.fqdn}",
      :to => ini.profitability.notifications,
      :subject => "Profitability Monitor",
      :message => message,
      :username => ini.smtp.username,
      :password => ini.smtp.password,
      :starttls => ini.smtp.starttls
    }
    mailer.send params
end

def update_miners_to(most_profitable_pool)
  ini = RubyINI.load("/opt/miningtools/lib/miningtools.ini")
  pool_config_index = {
    :wafflepool => 0,
    :clevermining => 1,
    :coinshift => 2
  }
  ini.profitability.miners.each do |miner|
     begin
       cgminer = CGMinerAPI.new miner, 4028
       case most_profitable_pool
          when "wafflepool" then 
            cgminer.switchpool pool_config_index[:wafflepool]
            send_notification ini, "Switched #{miner} to WafflePool."
          when "clevermining" then
            cgminer.switchpool pool_config_index[:clevermining]
            send_notification ini,  "Switched #{miner} to CleverMining."
          when "coinshift" then
            cgminer.switchpool pool_config_index[:coinshift]
            send_notification ini, "Switched #{miner} to CoinShift."
       end
     rescue
       send_notification ini, "Failed to update miner #{miner}."
       next
     end
  end
end

wafflepool_btc_per_mh   = WafflePool.get_btc_per_mh
clevermining_btc_per_mh = CleverMining.get_btc_per_mh
coinshift_btc_per_mh    = Coinshift.get_btc_per_mh
multipool_btc_per_mh    = Multipool.get_btc_per_mh

zenresponse = "OK|wafflepool=#{wafflepool_btc_per_mh} clevermining=#{clevermining_btc_per_mh} coinshift=#{coinshift_btc_per_mh} multipool=#{multipool_btc_per_mh}"
puts zenresponse

# Make sure miners are working on the most profitable pool
most_profitable_pool = "wafflepool"
if clevermining_btc_per_mh > wafflepool_btc_per_mh
   most_profitable_pool = "clevermining"
end
if coinshift_btc_per_mh > wafflepool_btc_per_mh && coinshift_btc_per_mh > clevermining_btc_per_mh
   most_profitable_pool = "coinshift"
end

File.open("profitability.db", "r+") { |db|

  current_pool = most_profitable_pool
  last_switched = DateTime.now

  if db.size == 0
     db.puts most_profitable_pool + "\n" + DateTime.now.to_s
     update_miners_to most_profitable_pool
     break
  end
  
  pieces = db.read.split("\n")
  current_pool = pieces[0].strip
  last_switched = DateTime.parse pieces[1]
  
  if current_pool != most_profitable_pool && TimeDifference.between(last_switched, Time.new).in_minutes > 5

     db.truncate(0)
     db.puts most_profitable_pool + "\n" + DateTime.now.to_s

     update_miners_to most_profitable_pool
  end
}
