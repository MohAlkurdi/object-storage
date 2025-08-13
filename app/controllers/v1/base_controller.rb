class V1::BaseController < ActionController::API
  before_action :authenticate

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "not_found" }, status: :not_found
  end

  private

  def authenticate
    token = request.authorization.to_s.sub(/^Bearer\s+/, "")
    expected = ENV.fetch("API_TOKEN", nil)
    unless expected && ActiveSupport::SecurityUtils.secure_compare(token, expected)
      render json: { error: "unauthorized" }, status: :unauthorized
    end
  end
end

