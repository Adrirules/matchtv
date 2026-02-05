class AddApiIdToMatches < ActiveRecord::Migration[7.0]
  def change
    add_column :matches, :api_id, :integer
    add_index :matches, :api_id
  end
end
