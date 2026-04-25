class Standing < ApplicationRecord
  validates :league_id, presence: true
  validates :league_id, uniqueness: { scope: :season }

  def self.for_league(league_id, season: nil)
    season ||= FootballApiService::LEAGUE_SEASONS[league_id]
    find_by(league_id: league_id, season: season)
  end

  def stale?
    synced_at.nil? || synced_at < 12.hours.ago
  end
end
