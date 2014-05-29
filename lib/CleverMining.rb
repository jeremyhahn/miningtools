require_relative "CloudFlare"

class CleverMining
    def self.btc_per_mh
        html = CloudFlare.scrape "http://www.clevermining.com"
        matcher = html.match(/\<\/i\>([0-9]*\.?[0-9]*)\sBTC\/day\sper\sMH\/s\<\/a\>/)
        return 0 if matcher == nil
        return matcher.captures[0].to_f
    end
end
