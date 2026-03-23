module Billing
  class StripeCheckoutService
    def initialize(user)
      @user = user
      Stripe.api_key = Rails.application.credentials.dig(:stripe, :secret_key) || ENV["STRIPE_SECRET_KEY"]
    end

    def create_checkout_session(success_url:, cancel_url:)
      customer = find_or_create_customer

      Stripe::Checkout::Session.create(
        customer: customer.id,
        payment_method_types: [ "card" ],
        line_items: [ {
          price: price_id,
          quantity: 1
        } ],
        mode: "subscription",
        success_url: success_url,
        cancel_url: cancel_url
      )
    end

    private

    def find_or_create_customer
      if @user.stripe_customer_id.present?
        Stripe::Customer.retrieve(@user.stripe_customer_id)
      else
        customer = Stripe::Customer.create(email: @user.email)
        @user.update!(stripe_customer_id: customer.id)
        customer
      end
    end

    def price_id
      Rails.application.credentials.dig(:stripe, :price_id_pro) || ENV["STRIPE_PRICE_ID_PRO"]
    end
  end
end
