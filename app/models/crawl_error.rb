class CrawlError < ApplicationRecord
  ALERT_THRESHOLD = 20 # nouvelles URLs en 24h → email

  # Enregistre une 404 — upsert pour éviter les doublons et compter les hits
  def self.track(url)
    return if url.blank?

    upsert(
      { url: url, count: 1, first_seen: Date.today, last_seen: Date.today, alert_sent: false },
      unique_by: :url,
      on_duplicate: Arel.sql(
        "count = crawl_errors.count + 1, last_seen = EXCLUDED.last_seen, updated_at = NOW()"
      )
    )
  rescue => e
    Rails.logger.warn("[CrawlError] track failed for #{url}: #{e.message}")
  end

  # Nouvelles URLs vues aujourd'hui (pas encore connues avant)
  def self.new_today
    where(first_seen: Date.today)
  end

  # Spike détecté si trop de nouvelles URLs en 24h
  def self.spike_today?
    new_today.count >= ALERT_THRESHOLD
  end
end
