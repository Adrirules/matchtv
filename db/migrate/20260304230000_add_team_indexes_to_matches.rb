class AddTeamIndexesToMatches < ActiveRecord::Migration[7.0]
  def change
    add_index :matches, :home_team
    add_index :matches, :away_team
    add_index :matches, :status
    add_index :matches, [:start_time, :competition]
  end
end
