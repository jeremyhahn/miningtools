#!/usr/bin/ruby

require "date"
require "time_difference"
require_relative "lib/CGMinerAPI"
require_relative "lib/RubyINI"
require_relative "lib/Mailer"
require_relative "lib/TextBelt"
require_relative "lib/WafflePool"
require_relative "lib/CleverMining"
require_relative "lib/Coinshift"
require_relative "lib/Coinsolver"
require_relative "lib/Multipool"

class Profitability

  @@ini = nil
  @@pools = nil
  @@database = "profitability.db"

  def initialize(ini, pools)
    @@pools = pools
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

    most_profitable_scrypt_pool = find_most_profitable_scrypt_pool
    most_profitable_scryptn_pool = find_most_profitable_scryptn_pool

    timestamp = DateTime.now

    data = db_read
    record = "#{most_profitable_scrypt_pool}|#{timestamp},#{most_profitable_scryptn_pool}|#{timestamp}"

    if data == nil
      db_write record
      update_scrypt_miners_to most_profitable_scrypt_pool
      update_scryptn_miners_to most_profitable_scryptn_pool
      return nil
    end

    scrypt_scryptn_pieces = data.split(",")

    scrypt_pieces = scrypt_scryptn_pieces[0].split("|")
    scryptn_pieces = scrypt_scryptn_pieces[1].split("|")

    current_scrypt_pool = scrypt_pieces[0].strip
    current_scryptn_pool = scryptn_pieces[0].strip

    last_switched_scrypt = DateTime.parse scrypt_pieces[1]
    last_switched_scryptn = DateTime.parse scryptn_pieces[1]

    scrypt_time_difference = TimeDifference.between(last_switched_scrypt, Time.new).in_minutes
    scryptn_time_difference = TimeDifference.between(last_switched_scryptn, Time.new).in_minutes

    record_needs_updating = false

    if current_scrypt_pool != most_profitable_scrypt_pool && scrypt_time_difference > 5
       record = "#{most_profitable_scrypt_pool}|#{timestamp},#{current_scryptn_pool}|#{last_switched_scryptn}"
       update_scrypt_miners_to most_profitable_scrypt_pool
       current_scrypt_pool = most_profitable_scrypt_pool
       last_switched_scrypt = timestamp
       record_needs_updating = true
    end

    if current_scryptn_pool != most_profitable_scryptn_pool && scryptn_time_difference > 5
       record = "#{current_scrypt_pool}|#{last_switched_scrypt},#{most_profitable_scryptn_pool}|#{timestamp}"
       update_scryptn_miners_to most_profitable_scryptn_pool
       record_needs_updating = true
    end

    db_write record if record_needs_updating
  end

  def find_most_profitable_scrypt_pool
     most_profitable_pool = nil
     most_profitable_btc_per_mh = 0
     @@pools.each do |k, pool|
      next if pool.scryptn
      if pool.btc_per_mh > most_profitable_btc_per_mh
        most_profitable_pool = pool.name
        most_profitable_btc_per_mh = pool.btc_per_mh
      end
    end   
    return most_profitable_pool
  end

  def find_most_profitable_scryptn_pool
     most_profitable_pool = nil
     most_profitable_btc_per_mh = 0
     @@pools.each do |k, pool|
      if pool.btc_per_mh > most_profitable_btc_per_mh
        most_profitable_pool = pool.name
        most_profitable_btc_per_mh = pool.btc_per_mh
      end
    end   
    return most_profitable_pool
  end

  def send_email_notification(message)
    mailer = Mailer.new @@ini.smtp.hostname, @@ini.smtp.port
    email = {
      :from => "profitability-monitor@#{@@ini.local.fqdn}",
      :to => @@ini.profitability.notifications,
      :subject => "Profitability Monitor",
      :message => message,
      :username => @@ini.smtp.username,
      :password => @@ini.smtp.password,
      :starttls => @@ini.smtp.starttls
    }
    mailer.send email
  end

  def send_sms_notification(message)
    textbelt = TextBelt.new @@ini
    textbelt.send(message)
  end

  def update_scrypt_miners_to(most_profitable_scrypt_pool)
    scrypt_miners = @@ini.profitability.scrypt_miners
    scrypt_miners = [scrypt_miners] if scrypt_miners.is_a? String
    @@pools.each do |k, pool|
      next if pool.name != most_profitable_scrypt_pool
      scrypt_miners.each do |miner|
         cgminer = CGMinerAPI.new miner, 4028
         begin
            cgminer.switchpool pool.config_index
            message = "Switched #{miner} to #{pool.name}."
            send_email_notification message
            send_sms_notification message if @@ini.profitability.enable_sendhub
         rescue
            message = "Failed to update #{miner} to #{pool.name}."
            send_email_notification message
            send_sms_notification message if @@ini.profitability.enable_sendhub
            next
         end
      end
    end
  end

  def update_scryptn_miners_to(most_profitable_scryptn_pool)
    scryptn_miners = @@ini.profitability.scryptn_miners
    scryptn_miners = [scryptn_miners] if scryptn_miners.is_a? String
    @@pools.each do |k, pool|
      next if pool.name != most_profitable_scryptn_pool
      scryptn_miners.each do |miner|
         cgminer = CGMinerAPI.new miner, 4028
         begin
            cgminer.switchpool pool.config_index
            message = "Switched #{miner} to #{pool.name}."
            send_email_notification message
            send_sms_notification message if @@ini.profitability.enable_sendhub
         rescue
            message = "Failed to update #{miner} to #{pool.name}."
            send_email_notification message
            send_sms_notification message if @@ini.profitability.enable_sendhub
            next
         end
      end
    end
  end

end

class Pool
  attr_accessor :name, :btc_per_mh, :config_index, :scryptn
  def initialize
    scryptn = 0
  end
end

ini = RubyINI.load("/opt/miningtools/lib/miningtools.ini")

wafflepool_btc_per_mh   = WafflePool.btc_per_mh
clevermining_btc_per_mh = CleverMining.btc_per_mh
coinshift_btc_per_mh    = Coinshift.btc_per_mh
multipool_btc_per_mh    = Multipool.btc_per_mh
coinsolver_btc_per_mh   = Coinsolver.btc_per_mh(ini.coinsolver.address)

zenresponse = "OK|wafflepool=#{wafflepool_btc_per_mh} clevermining=#{clevermining_btc_per_mh} coinshift=#{coinshift_btc_per_mh} multipool=#{multipool_btc_per_mh} coinsolver=#{coinsolver_btc_per_mh}"
puts zenresponse

wafflepool = Pool.new
wafflepool.name = "wafflepool"
wafflepool.btc_per_mh = wafflepool_btc_per_mh
wafflepool.config_index = 0

clevermining = Pool.new
clevermining.name = "clevermining"
clevermining.btc_per_mh = clevermining_btc_per_mh
clevermining.config_index = 1

coinshift = Pool.new
coinshift.name = "coinshift"
coinshift.btc_per_mh = coinshift_btc_per_mh
coinshift.config_index = 2

coinsolver = Pool.new
coinsolver.name = "coinsolver"
coinsolver.btc_per_mh = coinsolver_btc_per_mh
coinsolver.config_index = 3
coinsolver.scryptn = 1

pools = {
  :wafflepool => wafflepool,
  :clevermining => clevermining,
  :coinshift => coinshift,
  :coinsolver => coinsolver
}

profitability = Profitability.new ini, pools
profitability.mine_most_profitable
