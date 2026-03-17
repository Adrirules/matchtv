class AddPreviewToMatches < ActiveRecord::Migration[7.0]
  def change
    add_column :matches, :preview, :text
  end
end
