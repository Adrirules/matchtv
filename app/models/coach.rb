class Coach < ApplicationRecord
  validates :team_api_id, presence: true, uniqueness: true

  def as_api_hash
    {
      'name'        => name,
      'photo'       => photo,
      'nationality' => nationality,
      'age'         => age,
      'career'      => career || []
    }
  end
end
