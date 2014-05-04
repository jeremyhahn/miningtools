#!/usr/bin/ruby

require "coinbase"
require_relative "lib/RubyINI"

I18n.enforce_available_locales = false

ini = RubyINI.load("/opt/miningtools/lib/miningtools.ini")

coinbase = Coinbase::Client.new(ini.coinbase.apikey, ini.coinbase.secret)

buy_price = coinbase.buy_price
sell_price = coinbase.sell_price

puts "OK|buy_price=#{buy_price} sell_price=#{sell_price}"

