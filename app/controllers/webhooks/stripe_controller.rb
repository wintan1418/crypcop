module Webhooks
  class StripeController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      payload = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

      service = Billing::StripeWebhookService.new(payload, sig_header)
      result = service.process!

      if result.nil?
        head :unauthorized
      else
        head :ok
      end
    rescue => e
      Rails.logger.error "[StripeWebhook] Error: #{e.message}"
      head :bad_request
    end
  end
end
