class Player < ApplicationRecord
  validates :name, :slug, :api_id, presence: true
  validates :slug, uniqueness: true
  validates :api_id, uniqueness: true

  def self.find_by_slug(slug)
    find_by(slug: slug)
  end
end
