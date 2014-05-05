#!/usr/bin/ruby

require "erb"
require_relative "Blockrio"

class ChartBinding

  attr_accessor :wallet_address, :blockrio, :total_btc, :total_btc_by_day, :total_btc_per_month_by_day

  def initialize(wallet_address, blockrio)
      @wallet_address = wallet_address
      @blockrio = blockrio
      @total_btc_by_day = blockrio.total_btc_by_day
      @total_btc_per_month_by_day = blockrio.total_btc_per_month_by_day
      @total_btc = blockrio.total_btc
  end

  def get_binding
      binding()
  end
end

if ARGV.length != 1
  puts "USAGE: ./blockrio_charts_gen.rb [BTC Address]"
  exit 1
end

address=ARGV[0]

blockrio = Blockrio.new address
chart_binding = ChartBinding.new address, blockrio

template = File.open("blockrio_charts.html.erb", "r").read
erb_template = ERB.new(template)

File.open("blockrio_charts.html", "w+") { |file|
  file.write(erb_template.result(chart_binding.get_binding))
}