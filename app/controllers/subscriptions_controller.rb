class SubscriptionsController < ApplicationController
  before_action :authenticate_user!, except: [ :show ]

  def show
  end

  def create
    stripe_key = Rails.application.credentials.dig(:stripe, :secret_key) || ENV["STRIPE_SECRET_KEY"]

    unless stripe_key.present?
      redirect_to subscription_path, alert: "Billing is not configured yet."
      return
    end

    service = Billing::StripeCheckoutService.new(current_user)
    session = service.create_checkout_session(
      success_url: success_subscription_url,
      cancel_url: cancel_subscription_url
    )

    redirect_to session.url, allow_other_host: true
  rescue => e
    Rails.logger.error "[Subscription] Checkout error: #{e.message}"
    redirect_to subscription_path, alert: "Something went wrong. Please try again."
  end

  def destroy
    subscription = current_user.subscription
    unless subscription&.active_or_trialing?
      redirect_to subscription_path, alert: "No active subscription found."
      return
    end

    stripe_key = Rails.application.credentials.dig(:stripe, :secret_key) || ENV["STRIPE_SECRET_KEY"]
    if stripe_key.present?
      Stripe.api_key = stripe_key
      Stripe::Subscription.cancel(subscription.stripe_subscription_id)
    end

    subscription.update!(status: :canceled, canceled_at: Time.current)
    redirect_to subscription_path, notice: "Subscription canceled. You'll retain Pro access until the end of your billing period."
  rescue => e
    Rails.logger.error "[Subscription] Cancel error: #{e.message}"
    redirect_to subscription_path, alert: "Something went wrong. Please try again."
  end

  def success
    # Auto-sync subscription from Stripe on success redirect
    # (webhook is the primary method, this is a fallback for local dev)
    sync_subscription_from_stripe if current_user && !current_user.pro?
    redirect_to dashboard_path, notice: "Welcome to CrypCop Pro! Your account has been upgraded."
  end

  private

  def sync_subscription_from_stripe
    return unless current_user.stripe_customer_id.present?
    stripe_key = Rails.application.credentials.dig(:stripe, :secret_key) || ENV["STRIPE_SECRET_KEY"]
    return unless stripe_key.present?

    Stripe.api_key = stripe_key
    subs = Stripe::Subscription.list(customer: current_user.stripe_customer_id, limit: 1)
    return unless subs.data.any?

    s = subs.data.first
    sub = current_user.subscription || current_user.build_subscription
    sub.update!(
      stripe_subscription_id: s.id,
      stripe_price_id: s.items.data.first.price.id,
      status: :active,
      current_period_start: Time.current,
      current_period_end: 1.month.from_now
    )
  rescue => e
    Rails.logger.warn "[Subscription] Auto-sync failed: #{e.message}"
  end

  def cancel
    redirect_to subscription_path, notice: "Checkout canceled. No charges were made."
  end
end
