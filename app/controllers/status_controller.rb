class StatusController < ApplicationController
  def check
    service = FootballApiService.new
    result = service.test_connection

    if result.is_a?(Hash) && result[:error]
      render json: { connected: false, error: result[:error] }, status: :service_unavailable
    else
      render json: { connected: true }
    end
  end
end
