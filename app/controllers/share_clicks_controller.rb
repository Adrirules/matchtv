class ShareClicksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    platform = params[:platform].to_s.strip
    page_url = params[:page_url].to_s.strip

    return head :bad_request unless ShareClick::PLATFORMS.include?(platform)
    return head :bad_request if page_url.blank? || page_url.length > 500

    ShareClick.create!(platform: platform, page_url: page_url)
    head :ok
  rescue StandardError
    head :ok  # ne jamais bloquer l'UX en cas d'erreur
  end
end
