class Match < ApplicationRecord
  belongs_to :matchup

  LIVE_STATUSES     = %w[1H HT 2H ET BT P].freeze
  FINISHED_STATUSES = %w[FT AET PEN].freeze

  def live?     = LIVE_STATUSES.include?(status)
  def finished? = FINISHED_STATUSES.include?(status)
  def has_score? = home_score.present? && away_score.present?

  def cache_duration
    return 55.seconds if live?
    return 24.hours   if finished?
    1.hour
  end
end
