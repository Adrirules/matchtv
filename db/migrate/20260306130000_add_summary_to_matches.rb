class AddSummaryToMatches < ActiveRecord::Migration[7.0]
  def change
    add_column :matches, :summary, :text
  end
end
