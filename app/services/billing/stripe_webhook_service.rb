module Billing
  class StripeWebhookService
    def initialize(payload, sig_header)
      @payload = payload
      @sig_header = sig_header
      @webhook_secret = Rails.application.credentials.dig(:stripe, :webhook_secret) || ENV["STRIPE_WEBHOOK_SECRET"]
    end

    def process!
      event = verify_event
      return unless event

      case event.type
      when "checkout.session.completed"
        handle_checkout_completed(event.data.object)
      when "customer.subscription.updated"
        handle_subscription_updated(event.data.object)
      when "customer.subscription.deleted"
        handle_subscription_deleted(event.data.object)
      when "invoice.payment_failed"
        handle_payment_failed(event.data.object)
      end
    end

    private

    def verify_event
      Stripe::Webhook.construct_event(@payload, @sig_header, @webhook_secret)
    rescue Stripe::SignatureVerificationError
      Rails.logger.warn "[StripeWebhook] Invalid signature"
      nil
    end

    def handle_checkout_completed(session)
      return unless session.mode == "subscription"

      user = User.find_by(stripe_customer_id: session.customer)
      return unless user

      stripe_sub = Stripe::Subscription.retrieve(session.subscription)

      user.create_subscription!(
        stripe_subscription_id: stripe_sub.id,
        stripe_price_id: stripe_sub.items.data.first.price.id,
        status: :active,
        current_period_start: Time.at(stripe_sub.current_period_start),
        current_period_end: Time.at(stripe_sub.current_period_end)
      )
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "[StripeWebhook] Failed to create subscription: #{e.message}"
    end

    def handle_subscription_updated(stripe_sub)
      subscription = Subscription.find_by(stripe_subscription_id: stripe_sub.id)
      return unless subscription

      status = case stripe_sub.status
      when "active" then :active
      when "past_due" then :past_due
      when "canceled" then :canceled
      when "trialing" then :trialing
      else :canceled
      end

      subscription.update!(
        status: status,
        current_period_start: Time.at(stripe_sub.current_period_start),
        current_period_end: Time.at(stripe_sub.current_period_end)
      )
    end

    def handle_subscription_deleted(stripe_sub)
      subscription = Subscription.find_by(stripe_subscription_id: stripe_sub.id)
      return unless subscription

      subscription.update!(status: :canceled, canceled_at: Time.current)
    end

    def handle_payment_failed(invoice)
      user = User.find_by(stripe_customer_id: invoice.customer)
      return unless user&.subscription

      user.subscription.update!(status: :past_due)
    end
  end
end
