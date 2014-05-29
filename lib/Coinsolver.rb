require "net/http"
require "uri"
require "json"

class Coinsolver

    @@json = nil
    @@address = nil

    def initialize(address)
      uri = URI.parse("http://coinsolver.com/api.php?getaccountinfo=#{address}")
      http = Net::HTTP.new(uri.host, uri.port)
      body = http.request(Net::HTTP::Get.new(uri.request_uri)).body
      @@json = JSON.parse(body)
      @@address = address
    end

    def hashrate
        return 0 if !@@json.include?("hashrate")
        return @@json['hashrate']
    end

    def stalerate
      return 0  # unsupported
    end

    def btc_payout_total
      return 0 if !@@json.include?("total_btc_paid")
      return @@json['total_btc_paid'] || 0
    end

    def btc_payout_expected
      return 0 if !@@json.include?("btc_unexchanged")
      return @@json['btc_unexchanged'].to_f || 0
    end

    def btc_recently_paid
      return 0 if !@@json.include?("btc_balance")
      return @@json['btc_balance'] || 0
    end

    def self.btc_per_mh(address)
      uri = URI.parse("http://www.coinsolver.com/user-details.php?account=#{address}")
      http = Net::HTTP.new(uri.host, uri.port)
      html = http.request(Net::HTTP::Get.new(uri.request_uri)).body
      # mining multiple coins
      matcher = html.match(/Average:<.*?([0-9]*\.?[0-9]*)\sBTC\/Mh/)
      if matcher == nil
         # mining single coin
         matcher = html.match(/Est\sBTC\/Day\/MH\/s.*?>([0-9]*\.?[0-9]*)\s/)
         if matcher == nil
            # this pattern has popped up once or twice now - one last effort
            matcher = html.match(/([0-9]*\.?[0-9]*)\sBTC\/1Mh/)
         end
         return 0 if matcher == nil
      end
      return matcher.captures[0].to_f || 0
    end
end
