class AddVenueToMatches < ActiveRecord::Migration[7.0]
  def change
    add_column :matches, :venue_name, :string
    add_column :matches, :venue_city, :string
  end
end
