require "typhoeus"
require "json"

class TextBelt

    @@ini

    def initialize(ini)
      @@ini = ini
    end

    def send(message)
      response = Typhoeus.post("http://textbelt.com/text", body: {
        number: @@ini.textbelt.number,
        message: message
      })
      body = response.response_body
      @@json = JSON.parse(body)
      return @@json["success"] || false
    end
end