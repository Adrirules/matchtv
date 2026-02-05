class Matchup < ApplicationRecord
  validates :slug, presence: true, uniqueness: true
  has_many :matches
  def to_param
    slug
  end
end
