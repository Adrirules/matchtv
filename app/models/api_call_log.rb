class ApiCallLog < ApplicationRecord
  def self.track(endpoint)
    seg = endpoint.to_s.split("/").reject(&:blank?).first || "other"
    upsert(
      { date: Date.today, endpoint: seg, count: 1 },
      unique_by: [:date, :endpoint],
      on_duplicate: Arel.sql("count = api_call_logs.count + 1, updated_at = NOW()")
    )
  rescue => e
    Rails.logger.warn("[ApiCallLog] track failed: #{e.message}")
  end

  def self.usage(date = Date.today)
    rows = where(date: date).pluck(:endpoint, :count).to_h
    endpoints = %w[fixtures standings teams players injuries coachs other]
    total = 0
    lines = endpoints.map do |ep|
      count = rows[ep].to_i
      total += count
      "  #{ep.ljust(12)} #{count}"
    end
    lines << "  #{'TOTAL'.ljust(12)} #{total}"
    lines.join("\n")
  end
end
