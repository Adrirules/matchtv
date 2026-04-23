class SeoReport < ApplicationRecord
  validates :period, inclusion: { in: %w[weekly monthly] }
  validates :label, :report_date, presence: true

  scope :weekly,  -> { where(period: "weekly") }
  scope :monthly, -> { where(period: "monthly") }
  scope :recent,  ->(n = 8) { order(report_date: :desc).limit(n) }
end
