class TeamVote < ApplicationRecord
  validates :team_slug, presence: true
  validates :ip_hash,   presence: true, uniqueness: { scope: :team_slug }
end
