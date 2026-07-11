class ApplicationController < ActionController::Base
  before_action :reject_malformed_urls

  private

  # Retourne 410 Gone pour toute URL contenant %22 (guillemet encodé)
  # Source probable : slug avec guillemets dans frontmatter YAML mal parsé → sitemap pollué
  def reject_malformed_urls
    if request.original_fullpath.include?('%22') || request.original_fullpath.include?('"')
      head :gone
    end
  end
end
