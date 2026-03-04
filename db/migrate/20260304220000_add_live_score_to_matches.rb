class AddLiveScoreToMatches < ActiveRecord::Migration[7.0]
  def change
    add_column :matches, :status, :string, default: 'NS'
    add_column :matches, :home_score, :integer
    add_column :matches, :away_score, :integer
    add_column :matches, :elapsed, :integer
  end
end
