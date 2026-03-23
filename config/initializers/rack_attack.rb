class Rack::Attack
  # Throttle all requests by IP (300 requests per 5 minutes)
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip
  end

  # Throttle login attempts by IP (5 per 20 seconds)
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.ip
    end
  end

  # Throttle login attempts by email (5 per minute)
  throttle("logins/email", limit: 5, period: 60.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.params.dig("user", "email")&.downcase&.strip
    end
  end

  # Throttle scan requests (10 per minute for free users)
  throttle("scans/ip", limit: 10, period: 60.seconds) do |req|
    if req.path.match?(%r{/tokens/.+/scan}) && req.post?
      req.ip
    end
  end

  # Throttle API webhook endpoints
  throttle("webhooks/ip", limit: 100, period: 1.minute) do |req|
    if req.path.start_with?("/webhooks")
      req.ip
    end
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |req|
    [ 429, { "Content-Type" => "text/plain" }, [ "Rate limit exceeded. Try again later.\n" ] ]
  end
end
