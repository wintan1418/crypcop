require "net/http"
require "json"

module Solana
  class Client
    BASE_TIMEOUT = 10
    MAX_RETRIES = 2

    class ApiError < StandardError; end
    class RateLimitError < ApiError; end

    def get(url, headers: {})
      request(:get, url, headers: headers)
    end

    def post(url, body:, headers: {})
      request(:post, url, body: body, headers: headers)
    end

    private

    def request(method, url, body: nil, headers: {})
      uri = URI(url)
      retries = 0

      begin
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = BASE_TIMEOUT
        http.read_timeout = BASE_TIMEOUT

        req = case method
        when :get
          Net::HTTP::Get.new(uri)
        when :post
          Net::HTTP::Post.new(uri)
        end

        headers.each { |k, v| req[k] = v }
        req["Content-Type"] = "application/json"
        req["Accept"] = "application/json"
        req.body = body.to_json if body

        response = http.request(req)

        case response.code.to_i
        when 200..299
          JSON.parse(response.body)
        when 429
          raise RateLimitError, "Rate limited by #{uri.host}"
        else
          raise ApiError, "HTTP #{response.code}: #{response.body.to_s[0..200]}"
        end
      rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => e
        retries += 1
        retry if retries <= MAX_RETRIES
        raise ApiError, "Connection failed after #{MAX_RETRIES} retries: #{e.message}"
      end
    end
  end
end
