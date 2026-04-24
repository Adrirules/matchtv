class ErrorsController < ApplicationController
  def not_found
    CrawlError.track(request.path)
    render status: :not_found
  end
end
