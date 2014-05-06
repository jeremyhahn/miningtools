
require "typhoeus"
require "json"

class BtcMonth

  attr_accessor :name, :number, :year, :dates, :amounts, :total_btc

  def initialize(date, btc, dates, amounts, total_btc)
      months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
      date_pieces = date.split("-")
      @dates = dates
      @amounts = amounts
      @number = date_pieces[0]
      @year = date_pieces[2]
      @name = months[@number.to_i-1]
      @total_btc = total_btc.round(8)
  end
end

class Blockrio

  @@total_btc = 0
  @@btc_by_day = Hash.new

  def initialize(address)
    response = Typhoeus.get("http://btc.blockr.io/api/v1/address/txs/#{address}")
    json = JSON.parse(response.response_body)
    last_date = nil
    last_btc = 0   
    transactions = json["data"]["txs"]
    transactions.each do |tx|
      utc = tx["time_utc"]
      utc_pieces = utc.split("T")
      utc_date = utc_pieces[0]
      if utc_date != last_date && last_date != nil
         @@btc_by_day[last_date] = last_btc
         last_btc = 0
         last_date = utc_date
      end
      last_btc += tx["amount"].to_f
      @@total_btc += tx["amount"].to_f
      last_date = utc_date
    end   
  end

  def total_btc
    return @@total_btc
  end

  def total_btc_by_day
    return @@btc_by_day
  end

  def total_btc_per_month_by_day
    months = Array.new
    last_date = nil
    last_month_number = 0
    last_month = Hash.new
    last_btc = 0
    total_btc_for_month = 0
    @@btc_by_day.each do |date,btc|
      year_number = date.split("-")[0].to_i
      month_number = date.split("-")[1].to_i
      day_number = date.split("-")[2].to_i
      date = "#{month_number}-#{day_number}-#{year_number}"
      if month_number != last_month_number && last_month_number > 0
         months[last_month_number] = BtcMonth.new last_date, last_btc, last_month.keys.reverse, last_month.values.reverse, total_btc_for_month
         total_btc_for_month = 0
         last_month_number = month_number
         last_date = date
         last_month = Hash.new
         last_btc = btc
      end
      last_month[date] = btc
      last_date = date
      last_month_number = month_number
      last_btc = btc
      total_btc_for_month += btc
    end
    months[last_month_number] = BtcMonth.new last_date, last_btc, last_month.keys.reverse, last_month.values.reverse, total_btc_for_month
    months.shift
    months.shift
    return months.reverse
  end

end