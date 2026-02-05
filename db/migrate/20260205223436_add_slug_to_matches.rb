class AddSlugToMatches < ActiveRecord::Migration[7.0]
  def change
    add_column :matches, :slug, :string
    add_index :matches, :slug
  end
end
