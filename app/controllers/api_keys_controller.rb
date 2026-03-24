class ApiKeysController < ApplicationController
  before_action :authenticate_user!

  def index
    @api_keys = current_user.api_keys.order(created_at: :desc)
  end

  def create
    @api_key = current_user.api_keys.build(
      name: params.dig(:api_key, :name) || "My API Key",
      tier: current_user.pro? ? :pro_api : :free_api
    )

    if @api_key.save
      redirect_to api_keys_path, notice: "API key created: #{@api_key.key}"
    else
      redirect_to api_keys_path, alert: @api_key.errors.full_messages.join(", ")
    end
  end

  def destroy
    key = current_user.api_keys.find(params[:id])
    key.update!(active: false)
    redirect_to api_keys_path, notice: "API key deactivated."
  end
end
