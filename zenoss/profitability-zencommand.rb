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
        matcher = html.match(/\<\/thead\>\n\<tr\>\n\<td\>.*$\n<td.*$\n<td.*$\n<td.*right\"\>([0-9]*\.?[0-9]*)\<\/td\>/)
        return 0 if matcher == nil
        return matcher.captures[0].to_f
    end
end

class CleverMining
    def self.get_btc_per_mh
        html = CloudFlare.scrape "http://www.clevermining.com"
        matcher = html.match(/\<\/i\>([0-9]*\.?[0-9]*)\sBTC\/day\sper\sMH\/s\<\/a\>/)
        return 0 if matcher == nil
        return matcher.captures[0].to_f
    end
end

class Coinshift
    def self.get_btc_per_mh
        response = Typhoeus.get("http://www.coinshift.com", followlocation: true)
        html = response.response_body
        matcher = html.match(/\<h1\salign.*?\>([0-9]*\.?[0-9]*)\<\/h1\>\n\s+\<h3\salign.*\>BTC\/MH\/day\<\/h3\>/)
        return 0 if matcher == nil
        return matcher.captures[0].to_f      
    end
end

class Multipool
    def self.get_btc_per_mh
        response = Typhoeus.get("http://api.multipool.us/api.php")
        body = response.response_body.gsub(/<!--.*->/, "")
        json = JSON.parse(body)
        return json["prof"]["scrypt_1d"].to_f
    end
end

class Coinsolver
    def self.get_btc_per_mh(address)
      response = Typhoeus.get("http://www.coinsolver.com/user-details.php?account=#{address}")
      html = response.response_body
      matcher = html.match(/([0-9]*\.?[0-9]*)\sBTC\/1Mh/)
      return 0 if matcher == nil
      return matcher.captures[0].to_f
    end
end

class Profitability

  @@ini = nil
  @@pools = nil
  @@pool_config_indexes = nil
  @@database = "profitability.db"

  def initialize(ini, pools, pool_config_indexes)
    @@pools = pools
    @@pool_config_indexes = pool_config_indexes
    @@ini = ini
  end

  def db_read
    data = nil
    if File.exist?(@@database)
       File.open(@@database, "r") do |db|
         data = db.gets
       end
    end
    return data
  end

  def db_write(data)
    File.open(@@database, "w+") do |db|
      db.puts data
    end
  end

  def mine_most_profitable

    most_profitable_pool = find_most_profitable_pool
    data = db_read
    record = "#{most_profitable_pool}|#{DateTime.now}"

    if data == nil
      db_write record
      update_miners_to most_profitable_pool
      return nil
    end

    pieces = data.split("|")
    current_pool = pieces[0].strip
    last_switched = DateTime.parse pieces[1]
    time_difference = TimeDifference.between(last_switched, Time.new).in_minutes

    if current_pool != most_profitable_pool && time_difference > 5
       db_write record
       update_miners_to most_profitable_pool
    end
  end

  def find_most_profitable_pool
    most_profitable_pool = "wafflepool"
    most_profitable_btc_per_mh = @@pools[:wafflepool_btc_per_mh]
    if @@pools[:clevermining_btc_per_mh] > most_profitable_btc_per_mh
       most_profitable_pool = "clevermining"
       most_profitable_btc_per_mh = @@pools[:clevermining_btc_per_mh]
    end
    if @@pools[:coinshift_btc_per_mh] > most_profitable_btc_per_mh
       most_profitable_pool = "coinshift"
       most_profitable_btc_per_mh = @@pools[:coinshift_btc_per_mh]
    end
    if @@pools[:coinsolver_btc_per_mh] > most_profitable_btc_per_mh
       most_profitable_pool = "coinsolver"
       most_profitable_btc_per_mh = @@pools[:coinsolver_btc_per_mh]
    end
    return most_profitable_pool
  end

  def send_notification(message)
    mailer = Mailer.new @@ini.smtp.hostname, @@ini.smtp.port
    params = {
      :from => "profitability-monitor@#{@@ini.local.fqdn}",
      :to => @@ini.profitability.notifications,
      :subject => "Profitability Monitor",
      :message => message,
      :username => @@ini.smtp.username,
      :password => @@ini.smtp.password,
      :starttls => @@ini.smtp.starttls
    }
    mailer.send params
  end

  def update_miners_to(most_profitable_pool)
    @@ini.profitability.miners.each do |miner|
       begin
         cgminer = CGMinerAPI.new miner, 4028
         case most_profitable_pool
            when "wafflepool" then 
              cgminer.switchpool @@pool_config_indexes[:wafflepool]
              send_notification "Switched #{miner} to WafflePool."
            when "clevermining" then
              cgminer.switchpool @@pool_config_indexes[:clevermining]
              send_notification "Switched #{miner} to CleverMining."
            when "coinshift" then
              cgminer.switchpool @@pool_config_indexes[:coinshift]
              send_notification "Switched #{miner} to CoinShift."
            when "coinsolver" then
              cgminer.switchpool @@pool_config_indexes[:coinsolver]
              send_notification "Switched #{miner} to CoinSolver."
         end
       rescue
         send_notification "Failed to update miner #{miner}."
         next
       end
    end
  end

end

ini = RubyINI.load("/opt/miningtools/lib/miningtools.ini")

wafflepool_btc_per_mh   = WafflePool.get_btc_per_mh
clevermining_btc_per_mh = CleverMining.get_btc_per_mh
coinshift_btc_per_mh    = Coinshift.get_btc_per_mh
multipool_btc_per_mh    = Multipool.get_btc_per_mh
coinsolver_btc_per_mh   = Coinsolver.get_btc_per_mh(ini.coinsolver.address)

zenresponse = "OK|wafflepool=#{wafflepool_btc_per_mh} clevermining=#{clevermining_btc_per_mh} coinshift=#{coinshift_btc_per_mh} multipool=#{multipool_btc_per_mh} coinsolver=#{coinsolver_btc_per_mh}"
puts zenresponse

pools = {
  :wafflepool_btc_per_mh => wafflepool_btc_per_mh,
  :clevermining_btc_per_mh => clevermining_btc_per_mh,
  :coinshift_btc_per_mh => coinshift_btc_per_mh,
  :coinsolver_btc_per_mh => coinsolver_btc_per_mh
}

pool_config_indexes = {
  :wafflepool => 0,
  :clevermining => 1,
  :coinshift => 2,
  :coinsolver => 3
}


profitability = Profitability.new ini, pools, pool_config_indexes
profitability.mine_most_profitable
