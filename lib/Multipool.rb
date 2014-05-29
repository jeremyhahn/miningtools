require "typhoeus"

class Multipool
    def self.btc_per_mh
        response = Typhoeus.get("http://api.multipool.us/api.php")
        body = response.response_body.gsub(/<!--.*->/, "")
        json = JSON.parse(body)
        return json["prof"]["scrypt_1d"].to_f
    end
end
