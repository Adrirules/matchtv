class AddPenaltyScoresToMatches < ActiveRecord::Migration[7.0]
  def change
    add_column :matches, :home_penalty, :integer
    add_column :matches, :away_penalty, :integer
  end
end
