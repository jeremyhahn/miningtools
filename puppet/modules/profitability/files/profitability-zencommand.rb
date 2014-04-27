#!/usr/bin/ruby

require "typhoeus"
require "date"
require "time_difference"
require_relative "lib/CGMinerAPI"
require_relative "lib/RubyINI"
require_relative "lib/Mailer"

class CloudFlare
    def self.scrape(url)
        response = Typhoeus::Request.get(url, cookiefile: ".typhoeus_cookies", cookiejar: ".typhoeus_cookies")
        body = response.response_body
        challenge = body.match(/name="jschl_vc"\s*value="([a-zA-Z0-9]+)"\/\>/).captures[0]
        math = body.match(/a\.value\s*=\s*(\d.+?);/).captures[0]
        domain = url.split("/")[2]
        answer = eval(math) + domain.length
        answer_url = domain + "/cdn-cgi/l/chk_jschl?jschl_vc=#{challenge}&jschl_answer=#{answer}"
        html = Typhoeus.get(answer_url,  followlocation: true)
        return html.response_body
    end
end

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
        response = Typhoeus.get("https://www.multipool.us", followlocation: true)
        
        p response
        
        html = response.response_body
        return html.match(/1\sday.*?\<\/td\>\<td\>([0-9]*\.?[0-9]*)\<\/td\>\<td\>/).captures[0]
    end
end

def send_notification(ini, pool)
    mailer = Mailer.new ini.smtp.hostname, ini.smtp.port
    params = {
      :from => "profitability-monitor@#{ini.local.fqdn}",
      :to => ini.profitability.notifications,
      :subject => "Mining Pool Switch",
      :message => "Switched miners to #{pool}.",
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
     cgminer = CGMinerAPI.new miner, 4028
     case most_profitable_pool
        when "wafflepool" then 
          cgminer.switchpool pool_config_index[:wafflepool]
          send_notification ini, "WafflePool"
        when "clevermining" then
          cgminer.switchpool pool_config_index[:clevermining]
          send_notification ini, "CleverMining"
        when "coinshift" then
          cgminer.switchpool pool_config_index[:coinshift]
          send_notification ini, "Coinshift"
     end
  end
end

wafflepool_btc_per_mh   = WafflePool.get_btc_per_mh
clevermining_btc_per_mh = CleverMining.get_btc_per_mh
coinshift_btc_per_mh    = Coinshift.get_btc_per_mh

zenresponse = "OK|wafflepool=#{wafflepool_btc_per_mh} clevermining=#{clevermining_btc_per_mh} coinshift=#{coinshift_btc_per_mh}"
puts zenresponse

# Make sure miners are working on the most profitable pool
most_profitable_pool = "wafflepool"
if clevermining_btc_per_mh > wafflepool_btc_per_mh
   most_profitable_pool = "clevermining"
end
if coinshift_btc_per_mh > wafflepool_btc_per_mh && coinshift_btc_per_mh > clevermining_btc_per_mh
   most_profitable_pool = "coinshift"
end

File.open("profitability.db", File::CREAT|File::RDWR) do |db|

  current_pool = most_profitable_pool
  last_switched = DateTime.now

  if db.size == 0
     db.write "#{most_profitable_pool}\n#{DateTime.now}"
     db.close
     update_miners_to most_profitable_pool
     break
  else
     pieces = db.read.split("\n")
     current_pool = pieces[0]
     last_switched = DateTime.parse pieces[1]
  end

  if current_pool == most_profitable_pool
     db.close
     break
  end

  if TimeDifference.between(last_switched, Time.new).in_minutes < 15
    db.close
    break
  end

  db.truncate 0
  db.write "#{most_profitable_pool}\n#{DateTime.now}"
  db.close

  update_miners_to most_profitable_pool
end

