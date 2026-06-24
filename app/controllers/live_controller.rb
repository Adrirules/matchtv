class LiveController < ApplicationController
  LIVE_STATUSES = %w[1H HT 2H ET BT P].freeze

  def index
    @live_matches = Match.where(status: LIVE_STATUSES).order(:start_time)

    known_order = FootballApiService::COMPETITIONS_META.map { |c| c[:name] }
    grouped = @live_matches.group_by(&:competition)
    @sorted_groups = grouped.sort_by { |comp, _| known_order.index(comp) || 999 }

    # Pas d'indexation Google pour cette page dynamique (contenu qui change toutes les minutes)
    @noindex = true

    expires_in 1.minute, public: true
  end
end
