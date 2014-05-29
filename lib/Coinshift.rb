require "typhoeus"

class Coinshift

    @@html = nil

    def initialize(address)
      response = Typhoeus.get("http://coinshift.com/account/#{address}/")
      @@html = response.response_body
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

    def self.btc_per_mh
        response = Typhoeus.get("http://www.coinshift.com", followlocation: true)
        html = response.response_body
        #matcher = html.match(/\<h1\salign.*?\>([0-9]*\.?[0-9]*)\<\/h1\>\n\s+\<h3\salign.*\>BTC\/MH\/day\<\/h3\>/)
        matcher = html.match(/<h3\salign="center".*?$\s*<h1.*?([0-9]*\.?[0-9]*)<\/h1>/)
        return 0 if matcher == nil
        return matcher.captures[0].to_f      
    end
end