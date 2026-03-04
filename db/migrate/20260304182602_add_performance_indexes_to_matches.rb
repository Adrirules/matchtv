class AddPerformanceIndexesToMatches < ActiveRecord::Migration[7.0]
  def change
    add_index :matches, :start_time unless index_exists?(:matches, :start_time)
    add_index :matches, :competition unless index_exists?(:matches, :competition)
  end
end
