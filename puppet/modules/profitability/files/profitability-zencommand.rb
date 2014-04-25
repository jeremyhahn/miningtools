#!/usr/bin/ruby

require "typhoeus"

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
        return html.match(/\<\/thead\>\n\<tr\>\n\<td\>.*$\n<td.*$\n<td.*$\n<td.*right\"\>([0-9]*\.?[0-9]*)\<\/td\>/).captures[0]       
    end
end

class CleverMining
    def self.get_btc_per_mh
        html = CloudFlare.scrape "http://www.clevermining.com"
        return html.match(/\<\/i\>([0-9]*\.?[0-9]*)\sBTC\/day\sper\sMH\/s\<\/a\>/).captures[0]       
    end
end

class Coinshift
    def self.get_btc_per_mh
        response = Typhoeus.get("http://www.coinshift.com", followlocation: true)
        html = response.response_body
        return html.match(/\<h1\salign.*?\>([0-9]*\.?[0-9]*)\<\/h1\>\n\s+\<h3\salign.*\>BTC\/MH\/day\<\/h3\>/).captures[0]       
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

#Multipool.get_btc_per_mh
zenresponse = "OK|wafflepool=#{WafflePool.get_btc_per_mh} clevermining=#{CleverMining.get_btc_per_mh} coinshift=#{Coinshift.get_btc_per_mh}"
p zenresponse


