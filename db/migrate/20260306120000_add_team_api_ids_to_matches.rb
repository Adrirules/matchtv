class AddTeamApiIdsToMatches < ActiveRecord::Migration[7.0]
  def change
    add_column :matches, :home_team_api_id, :integer
    add_column :matches, :away_team_api_id, :integer
    add_index :matches, :home_team_api_id
    add_index :matches, :away_team_api_id
  end
end
