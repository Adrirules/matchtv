class ShareClick < ApplicationRecord
  PLATFORMS = %w[whatsapp x].freeze
  validates :platform, inclusion: { in: PLATFORMS }
  validates :page_url, presence: true, length: { maximum: 500 }
end
