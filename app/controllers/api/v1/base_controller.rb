module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_key!

      private

      def authenticate_api_key!
        key = request.headers["X-Api-Key"] || params[:api_key]
        @api_key = ApiKey.active_keys.find_by(key: key)

        unless @api_key
          render json: { error: "Invalid or missing API key" }, status: :unauthorized
          return
        end

        unless @api_key.can_call?
          render json: { error: "API rate limit exceeded. Upgrade your plan.", calls_limit: @api_key.calls_limit, calls_today: @api_key.calls_today }, status: :too_many_requests
          return
        end

        @api_key.record_call!
      end

      def current_api_user
        @api_key&.user
      end
    end
  end
end
